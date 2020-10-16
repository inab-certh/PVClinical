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

.. module:: entrezpy.elink.linkset.unit.linkout
  :synopsis: Exports class LinkList implementing Elink results for `lcheck`
    command reporting if if external links for UIDs exist.

.. moduleauthor:: Jan P Buchmann <jan.buchmann@sydney.edu.au>
"""


import entrezpy.elink.linkset.unit.linksetunit


class LinkOut(entrezpy.elink.linkset.unit.linksetunit.LinksetUnit):
  """ The `LinkOut` class represents a result from the `lcheck` Elink command.
  Results show if external links for UIDs exist.

  :param str dbto: target database
  :param str haslinkout: Y or N indicating presence or absence of external links
  """

  @classmethod
  def new(cls, dbto, haslinkout):
    """:rtype: :class:`linkout.LinkOut`"""
    return cls(dbto, haslinkout)

  def __init__(self, dbto, haslinkout):
    """:ivar bool haslinkout:"""
    super().__init__(dbto, None)
    self.haslinkout = bool(haslinkout == 'Y')

  def dump(self):
    """:rtype: dict"""
    return dict({'haslinkout' : self.haslinkout}, **self.basic_dump())
