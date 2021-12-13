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

.. module:: neighbor
  :synopsis: Exports class Neighbor implementing Elink results from the Elink
    `neighbor` command reporting linked UIDs in teh target database.

.. moduleauthor:: Jan P Buchmann <jan.buchmann@sydney.edu.au>
"""

from app.entrezpy.elink.linkset.unit import linksetunit


class Neighbor(linksetunit.LinksetUnit):
  """The `Neighbor` class represents a result from `neighbor` the Elink command.
  Neighbor results shows availbale links in teh target database.

  :param str uid: UID/accsession from the target database
  :param str dbto: Entrez database name for target database
  :param str linkname: Elink linkname
  """

  @classmethod
  def new(cls, uid, dbto, linkname):
    """:rtype: `neighbor.Neighbor`"""
    return cls(uid, dbto, linkname)

  def __init__(self, uid, dbto, linkname):
    super().__init__(dbto, linkname)
    self.uid = int(uid)

  def dump(self):
    """:return: dict"""
    return dict({'uid' : self.uid}, **self.basic_dump())
