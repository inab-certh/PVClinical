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

.. module:: entrezpy.esummary.esummary_parameter
   :synopsis: Export class EsummaryParameter for entrezpy queries to the
    Esummary NCBI E-Utility

.. moduleauthor:: Jan P Buchmann <jan.buchmann@sydney.edu.au>
"""

import sys
import math
import json
import logging

import entrezpy.base.parameter


logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)
logger.addHandler(logging.StreamHandler())


class EsummaryParameter(entrezpy.base.parameter.EutilsParameter):
  """EsummaryParameter implements checks and configures an Esummary() query.
  A summary query knows its size due to the id parameter or earlier result
  stored on the Entrez history server using WebEnv and query_key. The default
  retmode is JSON."""

  max_request_size = {'xml' : 10000, 'json' : 500}
  """maximum number of data sets per request"""

  def __init__(self, param):
    super().__init__(param)
    self.uids = param.get('id', [])
    self.rettype = param.get('rettype')
    self.retmode = 'json'
    self.retmax = self.adjust_retmax(param.get('retmax'))
    self.reqsize = self.adjust_reqsize(param.get('reqsize'))
    self.retstart = int(param.get('retstart', 0))
    #self.esummary_version = parameter.get('version', '2.0')
    self.calculate_expected_requests(reqsize=self.reqsize)
    self.check()

  def adjust_reqsize(self, reqsize):
    """Adjusts request size for query

    :param reqsize: Request size parameter
    :type  reqsize: str or None
    :return: adjusted request size
    :rtype: int
    """
    if reqsize is None:
      return EsummaryParameter.max_request_size.get(self.retmode)
    if int(reqsize) > EsummaryParameter.max_request_size.get(self.retmode):
      return EsummaryParameter.max_request_size.get(self.retmode)
    if self.retmax and (self.retmax < int(reqsize)):
      return self.retmax
    return int(reqsize)

  def adjust_retmax(self, retmax):
    """Adjusts retmax parameter. Order of check is crucial.

    :param int retmax: retmax value
    :return: adjusted retmax or None if all UIDs are fetched
    :rtype: int or None
    """
    if self.uids:           # we got UIDs to fetch
      return len(self.uids)
    if retmax is None:      # we have no clue what to expect, e.g. WebEnv
      logger.info(json.dumps({__name__ : {'No retmax': 'fetching 1 request \
                                          limited by retmode and retmax'}}))
      return None
    return int(retmax)      # we set a limitation

  def calculate_expected_requests(self, qsize=None, reqsize=None):
    """Calculate anf set the expected number of requests. Uses internal
    parameters if non are provided.

    :param int or None qsize: query size, i.e. expected number of data sets
    :param int reqsize: number of data sets  to fetch in one request
    """
    if not qsize:
      qsize = self.retmax
    if not reqsize:
      reqsize = EsummaryParameter.max_request_size.get(self.retmode)
    if self.retmax == 0 or (qsize is None):
      qsize = 1
    self.expected_requests = math.ceil(qsize / reqsize)

  def check(self):
    if not self.haveDb():
      logger.error(json.dumps({__name__:{'Missing parameter': 'db', 'action':'abort'}}))
      sys.exit()

    if not self.haveExpectedRequets():
      logger.error(json.dumps({__name__:{'Bad expected requests' :self.expected_requests,
                                         'action':'abort'}}))
      sys.exit()
    if not self.uids and not self.haveQuerykey() and not self.haveWebenv():
      logger.error(json.dumps({__name__:{'Missing required parameters' : {'ids':self.uids,
                                                                          'QueryKey':self.querykey,
                                                                          'WebEnv':self.webenv},
                                         'action':'abort'}}))
      sys.exit()

  def dump(self):
    return {'db' : self.db,
            'WebEnv':self.webenv,
            'query_key' : self.querykey,
            'uids' : self.uids,
            'retmode' : self.retmode,
            'rettype' : self.rettype,
            'retstart' : self.retstart,
            'retmax' : self.retmax,
            'request_size' : self.reqsize,
            'expected_requets' : self.expected_requests}
