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

.. module:: entrezpy.elink.linkset.relaxed
   :synopsis:
    Exports RelaxedLinkset class implementing many-to-many Elink results.

.. moduleauthor:: Jan P Buchmann <jan.buchmann@sydney.edu.au>
"""

from app.entrezpy.elink.linkset import bare

class RelaxedLinkset(bare.LinkSet):
  """
  The RelaxedLinkset class represents a collection of Elink results where
  several UID's from a source database (dbfrom) are linked to several UID's
  from a target database (fromdb). This usually occurs when creating elink
  commands with one id parameter concatenating several UIDs by a comma, i.e.
  id=19880848,19822630.

  :param uidsfrom: UIDs from database to link from
  :type uidsfrom: list
  :param dbfrom: name of database to link from
  :type dbfrom: str
  :param canLink: linkunits can be used for automated follow-up parameter
  :type canLink: boolean
  """

  def __init__(self, uidsfrom, dbfrom, canLink=True):
    """ :attr dict uids: UIDs from source database"""
    super().__init__('relaxed', dbfrom, canLink)
    self.uids = {int(x) : 0 for x in uidsfrom}


  def get_link_uids(self):
    """:return: target database and its linl UIDs
       :rtype: dict
    """
    link = {}
    for i in self.linkunits:
      if i.db not in link:
        link[i.db] = []
      link[i.db].append(i.uid)
    return link
    #return [x.uids for x in self.linkunits]

  def dump(self):
    """:return: all basis attributes of the instance
    :rtype: dict
    """
    return dict({'src_uids': [x for x in self.uids]},**self.base_dump())
