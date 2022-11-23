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

.. module:: linksetunit
  :synopsis: Exports class LinksetUnit implementing result units for LinkSet().

.. moduleauthor:: Jan P Buchmann <jan.buchmann@sydney.edu.au>
"""


class LinksetUnit:
  """
  The LinksetUnit class implements the base class for all LinksetUnits.
  LinksetUnits atore the information for UIDs linked to one or several source
  UIDs. LinksetUnit instances are handled by LinkSet instances. Almost all
  LinksetUnits have a dbto and linkname parameter. Some exceptions exists and
  these parameters are then set to None.

  :param str dbto: name of linked database
  :param str linkname: linkname
  """

  def __init__(self, dbto, linkname, cat='basic'):
    """Inits LinksetUnit instance with the linked database name and linkname

    :attribute str dbto: name of target database
    :attribute str linkname: ELink linkname
    """
    self.db = dbto
    self.linkname = linkname
    self.cat = cat

  def dump(self):
    """Virtual function to dump attributes in derived instances.

      :return: all LinksetUnit instance attributes
      :rtype: dict
    """
    raise NotImplementedError()

  def basic_dump(self):
    """:return: basis attributes of LinksetUnit instance
       :rtype: dict
    """
    return {'dbto' : self.db, 'linkname' : self.linkname}
