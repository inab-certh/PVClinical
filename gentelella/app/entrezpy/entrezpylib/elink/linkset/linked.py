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

.. module:: entrezpy.elink.linkset.linked
   :synopsis: Exports LinkedLinkset class implementing 1-to-many Elink results.

.. moduleauthor:: Jan P Buchmann <jan.buchmann@sydney.edu.au>
"""

import entrezpy.elink.linkset.bare

class LinkedLinkset(entrezpy.elink.linkset.bare.LinkSet):
  """
  The LinkedLinkset class represents a collection of Elink results where
  one UID from a source database (dbfrom) is linked to one or several several
  UID's from a target database (fromdb). This occurs when an elink
  parameter contains several id parameters i.e. id=19880848&id=19822630.

  :param list uidsfrom: UIDs from database to link from
  :param str dbfrom: name of database to link from
  :param bool canLink: linkunits can be used for automated follow-up parameter
  """

  def __init__(self, uidfrom, dbfrom, canLink=True):
    super().__init__('linked', dbfrom, canLink)
    self.uid = int(uidfrom)

  def get_link_uids(self):
    """Collect UIDs in LinksetUnits

    :rtype: dict
    """
    link = {}
    for i in self.linkunits:
      if i.db not in link:
        link[i.db] = []
      link[i.db].append(i.uid)
    return link

  def dump(self):
    """:rtype: dict"""
    return dict({'uid': self.uid}, **self.base_dump())
