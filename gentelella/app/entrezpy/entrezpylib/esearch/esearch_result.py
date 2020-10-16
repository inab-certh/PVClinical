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

.. module:: entrezpy.esearch.esearch_result
  :synopsis: Exports class EsearchResult implementing entrezpy results from
    NCBI Esearch Eutils requests


.. moduleauthor:: Jan P Buchmann <jan.buchmann@sydney.edu.au>
"""


import entrezpy.base.result


class EsearchResult(entrezpy.base.result.EutilsResult):
  """ EsearchResult sstores fetched UIDs and/or WebEnv-QueryKeys and
  creates follow-up parameters. UIDs are stored as string, even when UIDs,
  since responses can contain also accsessions when using the idtype option.

  :param dict response: Esearch response
  :param request: Esearch request instance for this query
  :type request: :class:`entrezpy.esearch.esearch_request.EsearchRequest`
  :ivar list uids: analyzed UIDs from response
  """

  def __init__(self, response, request):
    super().__init__(request.eutil, request.query_id, request.db, response.get('webenv'),
                     response.pop('querykey', None))
    self.count = int(response.get('count'))
    # print(self.count)
    self.retmax = int(response.pop('retmax'))
    self.retstart = int(response.pop('retstart'))
    self.uids = response.pop('idlist', [])

  def dump(self):
    """:rtype: dict"""
    return {'db':self.db, 'count' : self.count, 'len_uids' : len(self.uids),
            'uid' : self.uids, 'retmax' : self.retmax, 'function':self.function,
            'retstart' : self.retstart, 'references' : self.references.dump()}

  def get_link_parameter(self, reqnum=0):
    """Assemble follow-up parameters for linking. The first request returns
    all required information and using its querykey in such a case.

    :rtype: dict
    """
    if self.uids:
      return {'db' : self.db, 'id' : self.uids, 'WebEnv' : self.webenv,
              'query_key' : self.references.get_querykey(self.webenv, reqnum)}
    retmax = self.retmax
    if retmax == 0:
      retmax = self.count
    return {'db' : self.db, 'WebEnv' : self.webenv, 'retmax' : retmax,
            'query_key' : self.references.get_querykey(self.webenv, reqnum)}

  def isEmpty(self):
    """Empty search result has no webenv/querykey and/or no fetched UIDs"""
    if self.references.size() > 0:
      return False
    if self.uids:
      return False
    return True

  def size(self):
    """Get number of analyzed UIDs

    :rtype: int
    """
    if self.uids:
      return len(self.uids)
    return self.count


  def query_size(self):
    """Get number of all UIDs for search (count)

    :rtype: int
    """
    return self.count

  def add_response(self, response):
    """Add responses from individual requests

    :param dict response: Esearch response
    """
    self.references.add_reference(response.pop('webenv', None), response.pop('querykey', None))
    self.uids += response.pop('idlist', [])
