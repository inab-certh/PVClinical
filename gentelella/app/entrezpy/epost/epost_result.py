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

.. module:: epost_result
  :synopsis: Exports the EpostResult class implementing the results from
    Epost queries.

.. moduleauthor:: Jan P Buchmann <jan.buchmann@sydney.edu.au>
"""


import logging

from app.entrezpy.base import result


logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)
logger.addHandler(logging.StreamHandler())


class EpostResult(result.EutilsResult):
  """ EpostResult stores WebEnv and QueryKey from posting UIDs to the
  History server. Since no limit is imposed on the number of UIDs which can be
  posted in one query, the size of the result is the size of the request and
  only one WebEnv and QueryKey are returned.

  :param request: entrezpy Epost request instance
  :request type: :class:`entrezpy.epost.epost_request.EpostRequest`
  :param dict response: response
  """
  def __init__(self, response, request):
    """:ivar list uids: posted UIDs"""
    super().__init__('epost', request.query_id, request.db, response.pop('webenv'),
                     response.pop('querykey'))
    self.uids = request.uids

  def dump(self):
    return {'db' : self.db, 'size' : self.size(), 'len_uids' : len(self.uids),
            'query_key' : self.references.dump(), 'uids' : self.uids,
            'function' : self.function}

  def get_link_parameter(self, reqnum=0):
    return {'WebEnv' : self.webenv, 'db' : self.db,
            'QueryKey' : self.references.get_querykey(self.webenv, reqnum)}

  def size(self):
    return len(self.uids)

  def isEmpty(self):
    if self.size() > 0:
      return False
    return True
