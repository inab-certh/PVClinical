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

.. module:: entrezpy.elink.linkset.unit.linkout_all_attributes
   :synopsis: Exports :class:`LinkOutAllAttributes` implementing Elink results
    for `llinkslib` command reporting URLs and attributes for all links outside
    Entrez.

.. moduleauthor:: Jan P Buchmann <jan.buchmann@sydney.edu.au>
"""


import entrezpy.elink.linkset.unit.linksetunit


class LinkOutAllAttribute(entrezpy.elink.linkset.unit.linksetunit.LinksetUnit):
  """ The `LinkOutAllAttribute` class represents a result from the `llinkslib`
  Elink command. Results show the URL and its attributes for all links outside
  Entrez.

  :param dict unit: Entrez link data
  """

  @classmethod
  def new(cls, unit):
    """:rtype: :class:`linkout_all_attributes.LinkOutAllAttributes`"""
    return cls(unit)

  class Provider:
    """The Provider class stores all attrbiutes for an URL link outside Entrez

    :param dict provider_obj: attributes for linked URL
    """
    def __init__(self, provider_obj):
      self.id = provider_obj.pop('id', None)
      self.name = provider_obj.pop('name', None)
      self.nameabbr = provider_obj.pop('nameabbr', None)
      self.url = provider_obj.pop('url', None)
      self.iconurl = provider_obj.pop('iconurl', None)

    def dump(self):
      ":rtype: dict"
      return {'id' : self.id, 'name' : self.name, 'nameabbr' : self.nameabbr,
              'url' : self.url, 'iconurl' : self.iconurl}

  def __init__(self, unit):
    super().__init__(None, unit.pop('linkname', None))
    self.iconurl = unit.pop('iconurl', None)
    self.subjecttype = unit.pop('subjecttype', None)
    self.category = unit.pop('category', None)
    self.attributes = unit.pop('attributes', [])
    self.provider = self.Provider(unit.pop('provider', {}))

  def dump(self):
    ":rtype: dict"
    return dict({'iconurl' : self.iconurl, 'provider' : self.provider.dump(),
                 'subjecttype' : self.subjecttype, 'category' : self.category,
                 'attributes' : self.attributes, 'linkname' : self.linkname},
                **self.basic_dump())
