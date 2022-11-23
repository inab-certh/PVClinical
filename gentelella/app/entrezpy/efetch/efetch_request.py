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

.. module:: entrezpy.efetch.efetch_request
  :synopsis: Exports class EfetchRequest implementing individual requests for
    entrezpy queries to NCBI Efetch Eutils

.. moduleauthor:: Jan P Buchmann <jan.buchmann@sydney.edu.au>
"""


from app.entrezpy.base import request


class EfetchRequest(request.EutilsRequest):
  """The EfetchRequest class implements a single request as part of an Efetch
  query. It stores and prepares the parameters for a single request.
  :meth:`entrezpy.efetch.efetch_query.Efetch.inquire` calculates start and size
  for a single request.

  :param parameter: request parameter
  :param type: :class:`entrezpy.efetch.efetch_parameter.EfetchParameter`
  :param int start: number of first UID to fetch
  :param int size: requets size
  """

  def __init__(self, eutil, parameter, start, size):
    super().__init__(eutil, parameter.db)
    self.start = start
    self.retmax = size
    self.uids = parameter.uids[start:start+self.retmax]
    self.webenv = parameter.webenv
    self.querykey = parameter.querykey
    self.rettype = parameter.rettype
    self.retmode = parameter.retmode
    self.strand = parameter.strand
    self.seqstart = parameter.seqstart
    self.seqstop = parameter.seqstop
    self.complexity = parameter.complexity

  def get_post_parameter(self):
    qry = self.prepare_base_qry()
    if self.retmode != None:
      qry.update({'retmode' : self.retmode})
    if self.rettype != None:
      qry.update({'rettype' : self.rettype})
    if self.strand != None:
      qry.update({'strand' : self.strand})
    if self.seqstart != None:
      qry.update({'seq_start' : self.seqstart})
    if self.seqstop != None:
      qry.update({'seq_stop' : self.seqstop})
    if self.complexity != None:
      qry.update({'complexity' : self.complexity})
    if self.webenv and self.querykey:
      qry.update({'WebEnv' : self.webenv, 'query_key' : self.querykey,
                  'retstart' : self.start, 'retmax' : self.retmax})
    else:
      qry.update({'id' : ','.join(str(x) for x in self.uids)})
    return qry

  def dump(self):
    """Dumps instance attributes"""
    return {'db' : self.db,
            'uids' : self.uids,
            'num_uids' : len(self.uids),
            'webenv' : self.webenv,
            'querykey' : self.querykey,
            'rettype' : self.rettype,
            'retmode' :self.retmode,
            'retmax' : self.retmax,
            'retstart' : self.start,
            'strand' : self.strand,
            'seqstart' : self.seqstart,
            'seqstop' : self.seqstop,
            'complexity' : self.complexity}

  def get_observation(self):
    """Overwrite :meth:`request.EutilsRequest.get_observation`
    for Efetch requests"""
    cols = [self.query_id, self.id, self.start, self.retmax, self.status, self.duration]
    if self.request_error != None:
      cols.append(self.request_error)
    return '\t'.join(str(x) for x in cols)
