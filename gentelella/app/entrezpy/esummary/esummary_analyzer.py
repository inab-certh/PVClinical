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

.. module:: entrezpy.esummary.esummary_analyzer
   :synopsis: Exports class EsummaryAnalyzer implementing entrezpy Esummary
    queries to NCBI E-Utility Esummary

.. moduleauthor:: Jan P Buchmann <jan.buchmann@sydney.edu.au>
"""


import json
import logging

from app.entrezpy.base import analyzer
from app.entrezpy.esummary import esummary_result


logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)


class EsummaryAnalyzer(analyzer.EutilsAnalyzer):
  """EsummaryAnalyzer implements the analysis of ESsummary responses from
  E-Utils. JSON formatted data is enforced in responses. Summaries are stored in
  a :class:`esummary_result.EsummaryResult` instance.
  """

  def __init__(self):
    """:ivar result: Esummary results
       :type result: :class:`esummary_result.EsummaryResult`
    """
    super().__init__()
    self.result = None

  def init_result(self, response, request):
    """Inits :attr:`.result` as
     :class:`esummary_result.EsummaryResult`.

    :return: if result is initiated
    :rtype: bool
    """
    if not self.result:
      self.result = esummary_result.EsummaryResult(response, request)
      return True
    return False

  def analyze_result(self, response, request):
    if not self.init_result(response, request):
      self.result.add_summaries(response.pop('result', None))

  def analyze_error(self, response, request):
    log_msg = {'tool' : request.tool, 'request' : request.id, 'query' : request.query_id}
    if 'error' in response:
      log_msg.update({'error' : response.pop('error')})
    if 'esummaryresult' in response:
      log_msg.update({'error' : response.pop('esummaryresult')})
    logger.info(json.dumps({__name__ : {'Response-Error': log_msg}}))
    logger.debug(json.dumps({__name__ : {'Response-Error': log_msg,
                                         'dump' : request.dump_internals()}}))
