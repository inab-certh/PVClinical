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

.. module:: entrezpy.elink.linkset.unit.linkin
  :synopsis: Exports class LinkIn implementing Elink results from the Elink
    `ncheck` command reporting if links are available within the same Entrez
    database.

.. moduleauthor:: Jan P Buchmann <jan.buchmann@sydney.edu.au>
"""


from app.entrezpy.elink.linkset.unit import linksetunit


class LinkIn(linksetunit.LinksetUnit):
  """ The `LinkIn` class represents a result from the `ncheck` Elink command.
  Results show if links are available within the same Entrez databases.

  :param str dbto: name of target database
  :param str hasneighbor: Y or N indicating if links are avaible
  """

  @classmethod
  def new(cls, dbto, hasneighbor):
    """:rtype: :class:`linkin.LinkIn`"""
    return cls(dbto, hasneighbor)

  def __init__(self, dbto, hasneighbor):
    """:ivar bool hasneighbor:"""
    super().__init__(dbto, None)
    self.hasneighbor = bool(hasneighbor == 'Y')

  def dump(self):
    """:rtype: dict"""
    return dict({'hasneighbor' : self.hasneighbor}, **self.basic_dump())
