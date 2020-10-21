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

.. module:: entrezpy.esearch.esearch_analyzer
  :synopsis: Exports class EsearchAnalzyer implementing the entrezpy analysis of
    Eutils results from NCBI Eutils queries


.. moduleauthor:: Jan P Buchmann <jan.buchmann@sydney.edu.au>
"""


import json
import logging

import entrezpy.base.analyzer
import entrezpy.esearch.esearch_result


logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)
logger.addHandler(logging.StreamHandler())


class EsearchAnalyzer(entrezpy.base.analyzer.EutilsAnalyzer):
  """EsearchAnalyzer implements the analysis of ESearch responses from E-Utils.
  JSON formatted data is enforced in responses. The result are stored as a
  :class:`entrezpy.esearch.esearch_result.EsearchResult` instance.
  """
  def __init__(self):
    """:ivar result: :class:`entrezpy.esearch.esearch_result.EsearchResult`"""
    super().__init__()
    self.result = None

  def init_result(self, response, request):
    """Inits :class:`entrezpy.esearch.esearch_result.EsearchResult`.

    :return: if result is initiated
    :rtype: bool
    """
    if not self.result:
      self.result = entrezpy.esearch.esearch_result.EsearchResult(response, request)
      return True
    return False

  def analyze_result(self, response, request):
    """Implements :meth:`entrezpy.base.analyzer.EsearchAnalyzer.analyze_result`.

    :param dict response: Esearch response
    :param request: Esearch request
    :type request: :class:`entrezpy.esearch.esearch_request.EsearchRequest`
    """
    if not self.init_result(response['esearchresult'], request):
      self.result.add_response(response.pop('esearchresult'))

  def analyze_error(self, response, request):
    """Implements :meth:`entrezpy.base.analyzer.EutilsAnalyzer.analyze_error`.

      :param dict response: Esearch response
      :param request: Esearch request
      :type request: :class:`entrezpy.esearch.esearch_request.EsearchRequest`
    """
    err_msg = {'tool' : request.tool, 'request' : request.id,
               'query' : request.query_id, 'error': response['esearchresult']}
    logger.info(json.dumps({__name__ : {'Response-Error' : err_msg}}))
    err_msg.update({'request-dump' : request.dump_internals()})
    logger.debug(json.dumps({__name__ : {"Response-Error": err_msg}}))

  def size(self):
    """Get number of analyzed UIDs in :attr:`.result`

    :rtype: int
    """
    return self.result.size()

  def query_size(self):
    """Get number of expected UIDs in :attr:`.result`

    :rtype: int
    """
    return self.result.query_size()

  def reference(self):
    """Get History Server references from :attr:`.result`

    :return: History Server referencess
    :rtype: :class:`entrezpy.base.referencer.EutilReferencer.Reference`
    """
    return self.result.references.get_reference(self.result.webenv)

  def adjust_followup(self, parameter):
    """Adjust result attributes due to follow-up.

    :param parameter: Esearch parameter
    :param type: :class:`entrezpy.esearch.esearch_parameter.EsearchParameter`
    """
    self.result.retmax = parameter.retmax
