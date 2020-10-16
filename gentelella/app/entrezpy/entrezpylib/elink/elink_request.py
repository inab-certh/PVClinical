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

.. module:: elink_request
  :synopsis:
    Exports class ElinkRequest implementing individual requests as part of a
            entrezpy query.

.. moduleauthor:: Jan P Buchmann <jan.buchmann@sydney.edu.au>
"""

import entrezpy.base.request

class ElinkRequest(entrezpy.base.request.EutilsRequest):
  """ The ElinkRequest class implements a single request as part of a Elinker
  query. It stores and prepares the parameters for a single request.
  See :class:`entrezpy.elink.elink_parameter.ElinkParameter` for parameter
  description.

  :param parameter: request parameter
  :param type: :class:`entrezpy.elink.elink_parameter.ElinkParameter`
  """
  def __init__(self, eutil, parameter):
    super().__init__(eutil, parameter.db)
    self.dbfrom = parameter.dbfrom
    self.cmd = parameter.cmd
    self.querykey = parameter.querykey
    self.webenv = parameter.webenv
    self.uids = parameter.uids
    self.retmode = parameter.retmode
    self.linkname = parameter.linkname
    self.term = parameter.term
    self.holding = parameter.holding
    self.datetype = parameter.datetype
    self.reldate = parameter.reldate
    self.mindate = parameter.mindate
    self.maxdate = parameter.maxdate
    self.doseq = parameter.doseq

  def get_post_parameter(self):
    """Implements :meth:`entrezpy.base.request.EutilsRequest.get_post_parameter`.

    - If `WebEnv` and `query_key` are given the history server will be used.
    - If UIDs are given create an id parameter for each UID, i.e. id=123&id=456
      (see :attr:`entrezpy.elink.elink.elink_parameter.ElinkParameter.doseq`)
    - Setting :attr:`entrezpy.elink.elink.elink_parameter.ElinkParameter.doseq`
      to `False` concatenats UIDs with commas, i.e. id=123,456

    `linkname`: For `neighbor` or `neighbor` commands without a given linkname
     one generated. See documentation for more details.
    """
    qry = self.prepare_base_qry(extend={'cmd':self.cmd, 'retmode':self.retmode,
                                        'dbfrom':self.dbfrom, 'db':self.db})
    if self.webenv and self.querykey:
      qry.update({'WebEnv' : self.webenv, 'query_key' : self.querykey})
    else:
      if self.doseq:
        qry.update({'id' : self.uids})
      else:
        qry.update({'id' : ','.join(str(x) for x in self.uids)})
    if self.cmd == 'neighbor' or self.cmd == 'neighbor_history' or self.cmd == 'neighbor_score':
      if not self.linkname:
        self.linkname = '_'.join([self.dbfrom, self.db])
      qry.update({'linkname' : self.linkname})
    if self.term:
      qry.update({'term' : self.term})
    if self.holding:
      qry.update({'holding' : self.holding})
    if self.datetype:
      qry.update({'datetype' : self.datetype})
    if self.reldate:
      qry.update({'reldate' : self.reldate})
    if self.mindate:
      qry.update({'mindate' : self.mindate})
    if self.maxdate:
      qry.update({'maxdate' : self.maxdate})
    if  not self.db:
      qry.pop('db')
    return qry

  def dump(self):
    """Dumps instance attributes

    :return: instance attributes
    :rtype: dict
    """
    return self.dump_internals({'retmode' : self.retmode,
                                'WebEnv' : self.webenv,
                                'cmd' : self.cmd,
                                'holding' : self.holding,
                                'term' : self.term,
                                'query_key' : self.querykey,
                                'dbfrom' : self.dbfrom,
                                'datetype' : self.datetype,
                                'reldate' : self.reldate,
                                'mindate' : self.mindate,
                                'maxdate' : self.maxdate})
