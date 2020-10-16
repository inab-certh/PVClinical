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

.. module:: entrezpy.esearch.esearcher
   :synopsis: Exports class Esearcher implementing entrezpy Esearch queries to
      NCBI EUtils Esearch

.. moduleauthor:: Jan P Buchmann <jan.buchmann@sydney.edu.au>
"""


import json
import logging

import entrezpy.base.query
import entrezpy.esearch.esearch_parameter
import entrezpy.esearch.esearch_analyzer
import entrezpy.esearch.esearch_request


logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)
logger.addHandler(logging.StreamHandler())


class Esearcher(entrezpy.base.query.EutilsQuery):
  """Esearcher implements ESearch queries to NCBI's E-Utilities. Esearch queries
  return UIDs or WebEnv/QueryKey references to Entrez' History server.
  Esearcher implments :meth:`entrezpy.base.query.EutilsQuery.inquire` which
  analyzes the first result and automatically configures subseqeunt requests to
  get all queried UIDs if required.
  """
  def __init__(self, tool, email, apikey=None, apikey_var=None, threads=None, qid=None):
    super().__init__('esearch.fcgi', tool, email, apikey, apikey_var, threads, qid)

  def inquire(self, parameter, analyzer=entrezpy.esearch.esearch_analyzer.EsearchAnalyzer()):
    """Implements :meth:`entrezpy.base.query.EutilsQuery.inquire` and configures
    follow-up requests if required.

    :param dict parameter: ESearch parameter
    :param analyzer analyzer: analyzer for ESearch results, default is
      :class:`entrezpy.esearch.esearch_analyzer.EsearchAnalyzer`
    :return: analyzer instance or None if request errors have been encountered
    :rtype: :class:`entrezpy.esearch.esearch_analyzer.EsearchAnalyzer` or None
    """
    p = entrezpy.esearch.esearch_parameter.EsearchParameter(parameter)
    logger.debug(json.dumps({__name__ : {'Parameter' : p.dump()}}))
    self.monitor_start(p)
    follow_up = self.initial_search(p, analyzer)
    if not follow_up:
      self.monitor_stop()
      if not analyzer.isSuccess():
        return None
      return analyzer
    self.monitor_update(follow_up)
    logger.debug(json.dumps({__name__:{'Follow-up': follow_up.dump()}}))
    req_size = follow_up.reqsize
    for i in range(1, follow_up.expected_requests):
      if (i * req_size + req_size) > follow_up.retmax:
        logger.debug(json.dumps({__name__:{'adjust-reqsize':
                                           {'request' : i,
                                            'start' : (i*follow_up.reqsize),
                                            'end' : i*req_size+req_size,
                                            'query_size' : follow_up.reqsize,
                                            'adjusted-reqsize' : follow_up.retmax%req_size}}}))
        req_size = follow_up.retmax % req_size
      logger.debug(json.dumps({__name__:{'request':i,
                                         'expected':follow_up.expected_requests,
                                         'start':(i*follow_up.reqsize),
                                         'end':(i*follow_up.reqsize)+req_size,
                                         'reqsize':req_size}}))
      self.add_request(entrezpy.esearch.esearch_request.EsearchRequest(self.eutil,
                                                                       follow_up,
                                                                       (i*follow_up.reqsize),
                                                                       req_size), analyzer)
    self.request_pool.drain()
    self.monitor_stop()
    if self.check_requests() != 0:
      logger.debug(json.dumps({__name__ : {'Error': 'failed follow-up'}}))
      return None
    return analyzer

  def initial_search(self, parameter, analyzer):
    """Does first request and triggers follow-up if required or possible.

    :param parameter: Esearch parameter instances
    :type  parameter: :class:`entrezpy.esearch.esearch_parameter.EsearchParamater`
    :param analyzer: Esearch analyzer instance
    :type  analyzer: :class:`entrezpy.esearch.esearch_analyzer.EsearchAnalyzer`
    :return: follow-up parameter or None
    :rtype: :class:`entrezpy.esearch.esearch_parameter.EsearchParamater` or None
    """
    self.add_request(entrezpy.esearch.esearch_request.EsearchRequest(self.eutil,
                                                                     parameter,
                                                                     parameter.retstart,
                                                                     parameter.reqsize), analyzer)
    self.request_pool.drain()
    if self.check_requests() != 0:
      logger.info(json.dumps({__name__: {'Request-Error': 'inital search'}}))
      return None
    if not analyzer.isSuccess():
      logger.info(json.dumps({__name__: {'Response-Error': 'inital search'}}))
      return None
    if not parameter.uilist: # we care only about count
      return None
    if parameter.retmax == 0: # synonym for uilist
      return None
    if reachedLimit(parameter, analyzer):# reached limit in first search
      return None
    return configure_follow_up(parameter, analyzer) # We need mooaahhr

  def check_requests(self):
    """Test for request errors

      :return: 1 if request errors else 0
      :rtype: int
    """
    if not self.hasFailedRequests():
      logger.info(json.dumps({__name__ : {'Query status' : {self.id : 'OK'}}}))
      return 0
    logger.info(json.dumps({__name__ : {'Query status' : {self.id : 'failed'}}}))
    logger.debug(json.dumps({__name__ : {'Query status' :
                                         {self.id : 'failed',
                                          'request-dumps' : [x.dump_internals()
                                                             for x in self.failed_requests]}}}))
    return 1

def configure_follow_up(parameter, analyzer):
  """Adjusting EsearchParameter to follow-up results based on the initial
  Esearch result. Fetch remaining UIDs using the history server.

  :param analyzer: Esearch analyzer instance
  :type  analyzer: :class:`entrezpy.search.esearch_analyzer.EsearchAnalyzer`
  :param parameter: Initial Esearch parameter
  :type  result: :class:`entrezpy.search.esearch_parameter.EsearchParameter`
  """

  parameter.term = None
  if not parameter.retmax:
    parameter.retmax = analyzer.query_size()
  analyzer.adjust_followup(parameter)
  parameter.webenv = analyzer.reference().webenv
  parameter.querykey = analyzer.reference().querykeys[0]
  parameter.calculate_expected_requests(reqsize=parameter.reqsize)
  parameter.check()
  return parameter

def reachedLimit(parameter, analyzer):
  """Checks if the set limit has been reached

  :rtype: bool
  """
  if analyzer.query_size() == analyzer.size(): # fetched all UIDs
    return True
  if not parameter.retmax:  # We have no limit
    return False
  if analyzer.size() == parameter.retmax: # Fetched limit set by retmax
    return True
  return False
