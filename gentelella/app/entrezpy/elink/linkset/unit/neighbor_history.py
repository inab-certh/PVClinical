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

.. module:: neighbor_history
  :synopsis: Exports class NeighborHistory implementing Elink results from the
    Elink `neighbor_history` command repoting WebEnv and query-key for links.

.. moduleauthor:: Jan P Buchmann <jan.buchmann@sydney.edu.au>
"""


from app.entrezpy.elink.linkset.unit import linksetunit


class NeighborHistory(linksetunit.LinksetUnit):
  """The `NeighborHistory` class represents a result from the `neighbor_history`
  Elink command. Results are returned as WebEnv and query_key.

  :param str dbto: Entrez database name for target database
  :param str linkname: Elink linkname
  :param str webenv: WebEnv for link
  :param int querykey: querykey for correspondong WebEnv
  """

  @classmethod
  def new(cls, dbto, linkname, webenv, querykey):
    """:rtype: :class:`neighbor_history.Neighbor_history`"""
    return cls(dbto, linkname, webenv, querykey)

  def __init__(self, dbto, linkname, webenv, querykey):
    super().__init__(dbto, linkname, cat='neighbor_history')
    self.webenv = webenv
    self.querykey = querykey

  def dump(self):
    """:rtype: dict"""
    return dict({'cat' : self.cat, 'webenv' : self.webenv, 'querykey' : self.querykey},
                **self.basic_dump())
