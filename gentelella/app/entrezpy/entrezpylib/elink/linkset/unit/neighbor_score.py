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

.. module:: neighbor_score
  :synopsis: Exports class NeighborScore implementing Elink results from the
    Elink `neighbor_score` command reporting similarity scores for links.

.. moduleauthor:: Jan P Buchmann <jan.buchmann@sydney.edu.au>
"""


import entrezpy.elink.linkset.unit.linksetunit


class NeighborScore(entrezpy.elink.linkset.unit.linksetunit.LinksetUnit):
  """The `NeighborScore` class represents a result from the `neighbor_score`
  Elink command. Results show a goodness score for the found links.

  :param dict link: Linkscore to target database
  :param str dbto: Entrez database name for target database
  :param str linkname: Elink linkname
  """

  @classmethod
  def new(cls, link, dbto, linkname):
    """:rtype: :class:`neighbor_score.Neighbor_score`"""
    return cls(link, dbto, linkname)

  def __init__(self, link, dbto, linkname):
    super().__init__(dbto, linkname)
    self.uid = int(link['id'])
    self.score = int(link['score'])

  def dump(self):
    """:rtype: dict"""
    return dict({'uid' : self.uid, 'score' : self.score}, **self.basic_dump())
