"""
..
  Copyright 2018 The University of Sydney
  This file is part of entrezpy.

  Entrezpy is free software: you can redistribute it and/or modify it under the
  terms of the GNU Lesser General Public License as published by the Free
  Software Foundation, either version 3 of the License, or (at your option) any
  later version.

  Entrezpy is distributed in the hope that it will be useful, but WITHOUT ANY
  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
  A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with entrezpy.  If not, see <https://www.gnu.org/licenses/>.

.. module:: entrezpy.conduit
   :synopsis: Exports class Conduit implementing entrezpy pipelines to query
      NCBI E-Utilities

.. moduleauthor:: Jan P Buchmann <jan.buchmann@sydney.edu.au>
"""

import sys
import json
import uuid
import base64
import queue
import logging

import entrezpy.esearch.esearcher
import entrezpy.esearch.esearch_analyzer
import entrezpy.elink.elinker
import entrezpy.elink.elink_analyzer
import entrezpy.epost.eposter
import entrezpy.epost.epost_analyzer
import entrezpy.efetch.efetcher
import entrezpy.esummary.esummarizer
import entrezpy.esummary.esummary_analyzer

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)
logger.addHandler(logging.StreamHandler())


class Conduit:
  """Conduit simplifies to create pipelines and queries for entrezpy. Conduit
  stores results from previous requests, allowing to concatenate queries and
  retrieve obtained results later if required to reduce the need to redownload
  data. Conduit can use multiple threads to speed up data download, but some
  external libraries can break, e.g. SQLite3.

  Pipelines
  ---------
  Queries instances in pipelines of :class:`Conduit.Pipeline` are stored in the
  dictionary :attr:`Conduit.queries` with the query id as key and are accessible
  by all Conduit instances. A single :class:`Conduit.Pipeline` stores only the
  query id for this instance

  :param str email: user email
  :param str apikey: NCBI apikey
  :param str apikey_var: enviroment variable storing NCBI apikey
  :param int threads: set threads for multithreading
  """

  queries = {}
  """Query storage"""

  analyzers = {}
  """Analyzed query storage"""

  class Query:
    """ Entrezpy query for a Conduit pipeline. Conduit assembles pipelines using
    several Query() instances. If a dependency is given, it uses those
    parameters as basis using `:meth:`.resolve_dependency`.

    :param str function: Eutils function
    :param dict parameter: function parameters
    :param str dependency: query id from earlier query
    :param analyzer: analyzer instance for this query
    :type analyzer: :class:`entrezpy.base.analyzer.EutilsAnalyzer`
    """

    def __init__(self, function, parameter, dependency=None, analyzer=None):
      if not parameter and not dependency:
        sys.exit(logger.error(json.dumps({__name__:{'Error': 'Missing required parameters' \
                                                    'parameter and/or `dependency`.',
                                                    'action' : 'abort'}})))
      if not parameter:
        parameter = {}
      self.id = base64.urlsafe_b64encode(uuid.uuid4().bytes).decode()
      self.function = function
      self.parameter = parameter
      self.dependency = dependency
      self.analyzer = analyzer

    def resolve_dependency(self):
      """Resolves dependencies to obtain paremeters from earlier query.
      Parameters passed to this instance will overwrite dependency parameters
      """
      if self.dependency:
        parameter = Conduit.analyzers[self.dependency].result.get_link_parameter()
        if self.function == 'elink':
          parameter['dbfrom'] = parameter['db']
        parameter.update(self.parameter)
        self.parameter = parameter

  class Pipeline:
    """The Pipeline class implements a query pipeline with several consecutive
    queries. New pipelines are obtained through :class:`.Conduit`. Query
    instances are stored in :attr:`Conduit.queries` and the corresponding query
    id's in :attr:`.queries`. Every added query returns its id which can be
    used to retrieve it. """

    def __init__(self):
      """:ivar  queries: queries for this Pipeline instance
         :type  queries: :class:`queue.Queue()`
      """
      self.queries = queue.Queue()

    def add_search(self, parameter=None, dependency=None, analyzer=None):
      """Adds Esearch query

      :param dict parameter: Esearch E-Eutility parameters
      :param str dependency: query id from earlier query
      :param analyzer: analyzer for this query
      :type  analyzer: :class:`entrezpy.base.analyzer.EutilsAnalyzer`
      :return: Conduit query
      :rtype: :class:`ConduitQuery`
      """
      return self.add_query(Conduit.Query('esearch', parameter, dependency, analyzer))

    def add_link(self, parameter=None, dependency=None, analyzer=None):
      """Adds Elink query. Signature as :meth:`Conduit.Pipeline.add_search`"""
      return self.add_query(Conduit.Query('elink', parameter, dependency, analyzer))

    def add_post(self, parameter=None, dependency=None, analyzer=None):
      """Adds Epost query. Signature as :meth:`Conduit.Pipeline.add_search`"""
      return self.add_query(Conduit.Query('epost', parameter, dependency, analyzer))

    def add_summary(self, parameter=None, dependency=None, analyzer=None):
      """Adds Esummary query. Signature as :meth:`Conduit.Pipeline.add_search`"""
      return self.add_query(Conduit.Query('esummary', parameter, dependency, analyzer))

    def add_fetch(self, parameter=None, dependency=None, analyzer=None):
      """Adds Efetch query. Same signature as :meth:`Conduit.Pipeline.add_search`
      but analyzer is required as this step obtains highly variable results.
      """
      return self.add_query(Conduit.Query('efetch', parameter, dependency, analyzer))

    def add_query(self, query):
      """Adds query to own pipeline and storage

      :param query: Conduit query
      :type  query: :class:`Conduit.Query`
      :return: query id of added query
      :rtype: str
      """
      self.queries.put(query.id)
      Conduit.queries[query.id] = query
      return query.id

  def __init__(self, email, apikey=None, apikey_envar=None, threads=None):
    self.tool = 'entrezpyConduit'
    self.email = email
    self.apikey = apikey
    self.api_envar = apikey_envar
    self.threads = threads

  def run(self, pipeline):
    """Runs one query in pipeline and checks for errors. If errors are
    encounterd the pipeline aborts.

    :param pipeline: Conduit pipeline
    :type  pipeline: :class:`Conduit.Pipeline`
    """
    while not pipeline.queries.empty():
      q = Conduit.queries[pipeline.queries.get()]
      q.resolve_dependency()
      logger.info(json.dumps({__name__ : {'Inquiring' : {'query_id' : q.id,
                                                         'function' : q.function}}}))
      if q.function == 'esearch':
        Conduit.analyzers[q.id] = self.search(q)
      if q.function == 'elink':
        Conduit.analyzers[q.id] = self.link(q)
      if q.function == 'efetch':
        Conduit.analyzers[q.id] = self.fetch(q)
      if q.function == 'epost':
        Conduit.analyzers[q.id] = self.post(q)
      if q.function == 'esummary':
        Conduit.analyzers[q.id] = self.summarize(q)
      self.check_query(q)
      if Conduit.analyzers[q.id].isEmpty():
        logger.info(json.dumps({__name__ : {'empty response': {'query_id' : q.id,
                                                               'action' : 'skip'}}}))
        return Conduit.analyzers[q.id]
    return Conduit.analyzers[q.id]

  def check_query(self, query):
    """Check for successful query.

    :param query: Conduit query
    :type  query: :class:`Conduit.Query`
    """
    if not Conduit.analyzers[query.id]:
      sys.exit(logger.error(json.dumps({__name__ : {'Request error': {'query_id' : query.id,
                                                                      'action' : 'abort'}}})))
    if not Conduit.analyzers[query.id].isSuccess():
      sys.exit(logger.info(json.dumps({__name__ : {'response error': {'query_id' : query.id,
                                                                      'action' : 'abort'}}})))

  def get_result(self, query_id):
    """"Returns stored result from previous run.

    :param str query_id: query id
    :return: Result from this query
    :rtype: :class:`entrezpy.base.result.EutilsResult`
    """
    analyzer = self.analyzers.get(query_id)
    if not analyzer:
      return None
    return analyzer.get_result()

  def new_pipeline(self):
    """Retrurns new Conduit pipeline.

    :return: Conduit pipeline
    :rtype: :class:`Conduit.Pipeline`
    """
    return self.Pipeline()

  def search(self, query, analyzer=entrezpy.esearch.esearch_analyzer.EsearchAnalyzer):
    """Configures and runs an Esearch query. Analyzer are class references and
    instantiated here.

    :param query: Conduit Query
    :type  query: :class:`Conduit.Query`
    :param analyzer: reference to analyzer class
    :return: analyzer
    :rtype: :class:`entrezpy.esearch.esearch_analyzer.EsearchAnalyzer`
    """
    analyzer = query.analyzer if query.analyzer else analyzer()
    return entrezpy.esearch.esearcher.Esearcher(self.tool,
                                                self.email,
                                                self.apikey,
                                                threads=self.threads,
                                                qid=query.id).inquire(query.parameter, analyzer)

  def summarize(self, query, analyzer=entrezpy.esummary.esummary_analyzer.EsummaryAnalyzer):
    """Configures and runs an Esummary query. Analyzer are class references and
    instantiated here.

    :param query: Conduit Query
    :type  query: :class:`Conduit.Query`
    :param analyzer: reference to analyzer class
    :return: analyzer
    :rtype: :class:`entrezpy.esummary.esummary_analyzer.EsummaryAnalyzer`
    """
    analyzer = query.analyzer if query.analyzer else analyzer()
    return entrezpy.esummary.esummarizer.Esummarizer(self.tool,
                                                     self.email,
                                                     self.apikey,
                                                     threads=self.threads,
                                                     qid=query.id).inquire(query.parameter, analyzer)

  def link(self, query, analyzer=entrezpy.elink.elink_analyzer.ElinkAnalyzer):
    """Configures and runs an Elink query. Analyzer are class references and
    instantiated here.

    :param query: Conduit Query
    :type  query: :class:`Conduit.Query`
    :param analyzer: reference to analyzer class
    :return: analyzer
    :rtype: :class:`entrezpy.elink.elink_analyzer.ElinkAnalyzer`
    """
    analyzer = query.analyzer if query.analyzer else analyzer()
    return entrezpy.elink.elinker.Elinker(self.tool,
                                          self.email,
                                          self.apikey,
                                          threads=self.threads,
                                          qid=query.id).inquire(query.parameter, analyzer)

  def post(self, query, analyzer=entrezpy.epost.epost_analyzer.EpostAnalyzer):
    """Configures and runs an Epost query. Analyzer are class references and
    instantiated here.

    :param query: Conduit Query
    :type  query: :class:`Conduit.Query`
    :param analyzer: reference to analyzer class
    :return: analyzer
    :rtype: :class:`entrezpy.epost.epost_analyzer.EpostAnalyzer`
    """
    analyzer = query.analyzer if query.analyzer else analyzer()
    return entrezpy.epost.eposter.Eposter(self.tool,
                                          self.email,
                                          self.apikey,
                                          threads=self.threads,
                                          qid=query.id).inquire(query.parameter, analyzer)

  def fetch(self, query, analyzer=entrezpy.efetch.efetch_analyzer.EfetchAnalyzer):
    """uns an Efetch query. The Analyzer needs to be added to the quuery

    :param query: Conduit Query
    :type  query: :class:`Conduit.Query`
    :param analyzer: reference to analyzer class
    :return: analyzer
    :return: analyzer
    :rtype: :class:`entrezpy.efetch.efetch_analyzer.EfetchAnalyzer`
    """
    analyzer = query.analyzer if query.analyzer else analyzer()
    return entrezpy.efetch.efetcher.Efetcher(self.tool,
                                             self.email,
                                             self.apikey,
                                             threads=self.threads,
                                             qid=query.id).inquire(query.parameter, analyzer)
