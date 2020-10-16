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

.. module:: entrezpy.efetch.efetch_parameter
  :synopsis: Export EfetchParameter implementing Efetch parameters for NCBI
    EUtils Efetch queries

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


# nuccore complexity=> ASN.1 as text
DEF_RETMODE = 'xml'
"""Default retmode for fetch requests"""

class EfetchParameter(entrezpy.base.parameter.EutilsParameter):
  """EfetchParameter implements checks and configures an EftechQuery. A fetch
  query knows its size due to the id parameter or earlier result stored on the
  Entrez history server using WebEnv and query_key. The default retmode
  (fetch format) is set to XML because all E-Utilities can retun XML but not
  JSON, unfortunately.
  """

  req_limits = {'xml' : 10000, 'json' : 500, 'text' : 10000}
  """Max number of UIDs to fetch per request mode"""

  valid_retmodes = {'pmc' :       {'xml'},
                    'gene' :      {'text', 'xml'},
                    'poset' :     {'text', 'xml'},
                    'pubmed' :    {'text', 'xml'},
                    'nuccore' :   {'text', 'xml'},
                    'protein' :   {'text', 'xml'},
                    'sequences' : {'text', 'xml'}}
  """Enforced request uid sizes by NCBI for fetch requests by format"""

  def __init__(self, param):
    super().__init__(param)
    self.uids = param.get('id', [])
    self.rettype = param.get('rettype')
    self.retmode = self.check_retmode(param.get('retmode', DEF_RETMODE))
    self.retmax = self.adjust_retmax(param.get('retmax'))
    self.reqsize = self.adjust_reqsize(param.get('reqsize'))
    self.retstart = int(param.get('retstart', 0))
    self.strand = param.get('strand')
    self.seqstart = param.get('seq_start')
    self.seqstop = param.get('seq_stop')
    self.complexity = param.get('complexity')
    self.calculate_expected_requests(reqsize=self.reqsize)

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
      return EfetchParameter.req_limits(self.retmode)
    return int(retmax)      # we set a limitation

  def check_retmode(self, retmode):
    """Checks for valid retmode and retmode combination

    :param str retmode: retmode parameter
    :return: retmode
    :rtype: str
    """
    if retmode not in EfetchParameter.req_limits:
      sys.exit(logger.error(json.dumps({__name__ : {'Unknown retmode': retmode,
                                                    'action' : 'abort'}})))

    if self.db in EfetchParameter.valid_retmodes and \
       retmode not in EfetchParameter.valid_retmodes[self.db]:
      sys.exit(logger.error(json.dumps({__name__ : {'Bad retmode for database':
                                                    {'db' : self.db, 'retmode' : retmode},
                                                    'action' : 'abort'}})))
    return retmode

  def adjust_reqsize(self, reqsize):
    """Adjusts request size for query

    :param reqsize: Request size parameter
    :type  reqsize: str or None
    :return: adjusted request size
    :rtype: int
    """
    if reqsize is None:
      return EfetchParameter.req_limits.get(self.retmode)
    if int(reqsize) > EfetchParameter.req_limits.get(self.retmode):
      return EfetchParameter.req_limits.get(self.retmode)
    if self.retmax and (self.retmax < int(reqsize)):
      return self.retmax
    return int(reqsize)

  def calculate_expected_requests(self, qsize=None, reqsize=None):
    """Calculate anf set the expected number of requests. Uses internal
    parameters if non are provided.

    :param int or None qsize: query size, i.e. expected number of data sets
    :param int reqsize: number of data sets  to fetch in one request
    """
    if not qsize:
      qsize = self.retmax
    if not reqsize:
      reqsize = EfetchParameter.req_limits.get(self.retmode)
    if self.retmax == 0 or (qsize is None):
      qsize = 1
    self.expected_requests = math.ceil(qsize / reqsize)

  def check(self):
    """Implements :class:`entrezpy.base.parameter.EutilsParameter.check` to
    check for the minumum required parameters. Aborts if any check fails.
    """
    if not self.haveDb():
      sys.exit(logger.error(json.dumps({__name__ : {'Missing parameter': {'db' : self.db},
                                                    'action' : 'abort'}})))

    if not self.haveExpectedRequets():
      sys.exit(logger.error(json.dumps({__name__ : {'Bad expected requests' : self.expected_requests,
                                                    'action' : 'abort'}})))

    if not self.uids and not self.haveQuerykey() and not self.haveWebenv():
      sys.exit(logger.error(json.dumps({__name__ : {'Missing parameters' :
                                                    {'id': self.uids,
                                                     'QueryKey': self.querykey,
                                                     'WebEnv' : self.webenv},
                                                    'action' : 'abort'}})))

  def dump(self):
    return {'db' : self.db,
            'WebEnv':self.webenv,
            'query_key' : self.querykey,
            'uids' : self.uids,
            'retmode' : self.retmode,
            'rettype' : self.rettype,
            'retstart' : self.retstart,
            'retmax' : self.retmax,
            'strand' : self.strand,
            'seqstart' : self.seqstart,
            'seqstop' : self.seqstop,
            'complexity' : self.complexity,
            'request_size' : self.reqsize,
            'expected_requets' : self.expected_requests}
