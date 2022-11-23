"""
..
  Copyright 2018, 2019 The University of Sydney
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

.. module:: elinker
   :synopsis: Exports ELinker class implementing Elink queries.

.. moduleauthor:: Jan P Buchmann <jan.buchmann@sydney.edu.au>
"""


import json
import logging

from app.entrezpy.base import query
from app.entrezpy.elink import elink_parameter
from app.entrezpy.elink import elink_request
from app.entrezpy.elink import elink_analyzer

logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)
logger.addHandler(logging.StreamHandler())

class Elinker(query.EutilsQuery):
  """Elinker implements elink queries to E-Utilities [0].
  Elinker implements the inquire() method to link data sets on NCBI Entrez
  servers. All parameters described in [0] are acccepted. Elink queries consist
  of one request linking UIDs or an earlier requests on the history server
  within the same or different Entrez database. [0]:
  https://www.ncbi.nlm.nih.gov/books/NBK25499/#chapter4.ELink

  :param str tool: tool name
  :param str email: user email
  :param str apikey: NCBI apikey
  :param str apikey_var: enviroment variable storing NCBI apikey
  :param int threads: set threads for multithreading
  :param str qid: unique query id
  """

  def __init__(self, tool, email, apikey=None, apikey_var=None, threads=None, qid=None):
    super().__init__('elink.fcgi', tool, email, apikey, apikey_var, threads, qid)

  def inquire(self, parameter, analyzer=elink_analyzer.ElinkAnalyzer()):
    """ Implements virtual function inquire()

      1. Prepares parameter instance :class:`elink_parameter.ElinkerParameter`
      2. Starts threading monitor :func:`monitor_start`
      3. Adds ElinkRequests to queue :func:`add_request`
      4. Runs and analyzes all requests
      5. Checks for errors :func:`check_requests`

    :param dict parameter: ELink parameter
    :param analyzer analyzer: analyzer for Elink Results, default is
      :class:`elink_analyzer.ElinkAnalyzer`
    :return: analyzer  or None if request errors have been encountered
    :rtype: :class:`entrezpy.base.analyzer.EntrezpyAnalyzer` instance or None
    """
    logger.debug(json.dumps({__name__ : {'dump' : self.dump()}}))
    p = elink_parameter.ElinkParameter(parameter)
    self.monitor_start(p)
    self.add_request(elink_request.ElinkRequest(self.eutil, p), analyzer)
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
