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

.. module:: entrezpy.esummary.esummary_request
  :synopsis: Exports class EsummaryRequest implementing individual requests for
    entrezpy queries to Esummary NCBI E-Utility

.. moduleauthor:: Jan P Buchmann <jan.buchmann@sydney.edu.au>
"""


import entrezpy.base.request


class EsummaryRequest(entrezpy.base.request.EutilsRequest):
  """The SummaryRequest class implements a single request as part of an Esummary
  query. It stores and prepares the parameters for a single request.
  :meth:`entrezpy.esummary.esummary_query.Esummaryizer.inquire` calculates start
  and size for a single request.

  :param parameter: request parameter
  :param type: :class:`entrezpy.esummary.esummary_parameter.EsummaryParameter`
  :param int start: number of first UID to fetch
  :param int size: requets size
  """

  def __init__(self, eutil, parameter, start, size):
    super().__init__(eutil, parameter.db)
    self.retstart = start
    self.retmax = size
    self.retmode = parameter.retmode
    self.rettype = parameter.rettype
    self.uids = parameter.uids[start:start+size]
    self.webenv = parameter.webenv
    self.querykey = parameter.querykey

  def get_post_parameter(self):
    qry = self.prepare_base_qry(extend={'retmode':self.retmode})
    if self.webenv and self.querykey:
      qry.update({'WebEnv' : self.webenv, 'query_key':self.querykey,
                  'retstart' : self.retstart, 'retmax' : self.retmax})
    else:
      qry.update({'id' : ','.join(str(x) for x in self.uids)})
    return qry

  def dump(self):
    """:rtype: dict"""
    return self.dump_internals({'retstart' : self.retstart,
                                'retmax' : self.retmax,
                                'retmode' : self.retmode,
                                'rettype' : self.rettype,
                                'WebEnv' : self.webenv,
                                'query_key' : self.querykey,
                                'uids' : len(self.uids)})
