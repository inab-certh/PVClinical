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

.. module:: entrezpy.elink.epost_parameter
  :synopsis: Exports class EpostParameter for NCBI E-Utils Esearch queries

.. moduleauthor:: Jan P Buchmann <jan.buchmann@sydney.edu.au>
"""


import sys
import json
import logging

from app.entrezpy.base import parameter

logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)
logger.addHandler(logging.StreamHandler())


class EpostParameter(parameter.EutilsParameter):
  """EpostParameter checks query specific parameters and configures a
  :class:`entrezpy.epost.epost_query.EpostQuery` instance. Force XML since
  Epost responds only XML. Epost requests don't have follow-ups.

  :param dict parameter: Eutils Epost parameters
  """
  def __init__(self, parameter):
    """
    :ivar list uids: UIDs to post
    :ivar str retmode: fix retmode to XML
    :ivar int query_size: size of query, here number of UIDs
    :ivar int request_size: size of request, here nuber if UIDs
    :ivar int expected_requests: number of expected requests, here 1
    """
    super().__init__(parameter)
    self.uids = parameter.get('id', [])
    self.retmode = 'xml'
    self.query_size = len(self.uids)
    self.request_size = self.query_size
    self.expected_requests = 1
    self.check()

  def check(self):
    """Implements :meth:`parameter.EutilsParameter.check`
    by checking for missing database parameter and UIDs.
    """
    if not self.haveDb():
      sys.exit(logger.error(json.dumps({__name__:{'Missing parameter': 'db', 'action' : 'abort'}})))
    if self.query_size == 0:
      sys.exit(logger.error(json.dumps({__name__:{'Missing uids' : self.uids, 'action':'abort'}})))

  def dump(self):
    """Dump instance variables

    :rtype: dict
    """
    return {'db' : self.db,
            'WebEnv':self.webenv,
            'query_key' : self.querykey,
            'uids' : self.uids,
            'retmode' : self.retmode,
            'doseq' : self.doseq,
            'query_size' : self.query_size,
            'request_size' : self.request_size,
            'expected_requets' : self.expected_requests}
