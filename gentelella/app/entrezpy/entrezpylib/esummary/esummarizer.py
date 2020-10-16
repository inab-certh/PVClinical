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

.. module:: entrezpy.esummary.esummarizer
   :synopsis: Exports class Esummarizer implementing entrezpy Esummary queries
    to NCBI E-Utility Esummary

.. moduleauthor:: Jan P Buchmann <jan.buchmann@sydney.edu.au>
"""


import json
import logging

import entrezpy.base.query
import entrezpy.esummary.esummary_request
import entrezpy.esummary.esummary_analyzer
import entrezpy.esummary.esummary_parameter


logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)
logger.addHandler(logging.StreamHandler())


class Esummarizer(entrezpy.base.query.EutilsQuery):
  """Esummary implements Esummary queries to E-Utilities [0]. It fetches
  summaries for given UIDs or Webenv and query_key references.
  Esummary can consist of several queries, depending on the format requested.
  # [0]: https://www.ncbi.nlm.nih.gov/books/NBK25499/#chapter4.ESummary
  """

  def __init__(self, tool, email, apikey=None, apikey_var=None, threads=None, qid=None):
    super().__init__('esummary.fcgi', tool, email, apikey, apikey_var, threads, qid)

  def inquire(self, parameter, analyzer=entrezpy.esummary.esummary_analyzer.EsummaryAnalyzer()):
    """Implements :meth:`entrezpy.base.quet.EutilsQuery.unquire`.

    :param dict parameter: Esummary parameter
    :param analyzer: Esummary analyzer
    :type  analyzer: :class:`entrezpy.esummary.esummary_analzyer`
    :return: analyzer instance or None if request errors have been encountered
    :rtype: :class:`entrezpy.esummary.esummary_analyzer.EsummaryAnalyzer` or
      None
    """
    param = entrezpy.esummary.esummary_parameter.EsummaryParameter(parameter)
    logger.debug(json.dumps({__name__ : {'Parameter' : param.dump()}}))
    req_size = param.reqsize
    self.monitor_start(param)
    for i in range(param.expected_requests):
      if i * req_size + req_size > param.retmax:
        req_size = param.retmax % param.reqsize
      self.add_request(entrezpy.esummary.esummary_request.EsummaryRequest(self.eutil,
                                                                          param,
                                                                          (i*param.reqsize),
                                                                          req_size), analyzer)
    self.request_pool.drain()
    self.monitor_stop()
    if self.check_requests() == 0:
      return analyzer
    return None

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
