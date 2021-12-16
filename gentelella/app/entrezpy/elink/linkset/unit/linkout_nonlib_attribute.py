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

.. module:: entrezpy.elink.linkset.unit.linkout_nonlib_attributes
   :synopsis: Exports :class:`LinkOutNonlibAttributes` implementing Elink
    results for `llinks` command reporting URLs and attributes for all links
    outside Entrez not being libraries.

.. moduleauthor:: Jan P Buchmann <jan.buchmann@sydney.edu.au>
"""


from app.entrezpy.elink.linkset.unit import linksetunit


class LinkOutNonlibAttributes(linksetunit.LinksetUnit):
  """ The `LinkOutNonlibAttribute` class represents a result from the `llinks`
  Elink command. Results show the URL and its attributes for all links outside
  Entrez which are not libraries.

  :param dict objurl: Entrez link data
  """
  @classmethod
  def new(cls, objurl):
    """:rtype: :class:`linkout_nonlib_attributes.LinkOutNonlibAttributes`"""
    return cls(objurl)

  def __init__(self, objurl):
    super().__init__(None, None)
    self.objurl = objurl

  def dump(self):
    ":rtype: dict"
    return dict({'objurl' : self.objurl}, **self.basic_dump())
