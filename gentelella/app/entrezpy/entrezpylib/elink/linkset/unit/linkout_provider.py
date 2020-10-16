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

.. module:: linkout_provider
  :synopsis: Exports class LinkIn implementing Elink results from the Elink
    `prlinks` command.

.. moduleauthor:: Jan P Buchmann <jan.buchmann@sydney.edu.au>
"""


import entrezpy.elink.linkset.unit.linksetunit


class LinkOutProvider(entrezpy.elink.linkset.unit.linksetunit.LinksetUnit):
  """The `LinkOutProvider` class represents a result from the Elink command
  `prlinks`

  :param dict unit: collected information for one linkout provider
  """
  @classmethod
  def new(cls, unit):
    """Returns new instance.

    :rtype: `entrezpy.elink.linkset.unit.linksetunit.linkin.LinkIn`
    """
    return cls(unit)

  @staticmethod
  def set_url(urlobj):
    """Converts an UrlObj url and  language info in two dicts into single dict

    :param dict urlobj: Elink url JSON result
    :rtype: dict
    """
    if not urlobj:
      return None
    url = urlobj.pop('value', None)
    if not url:
      return None
    return {url : urlobj.pop('lng', None)}


  class Provider:
    """Provider implements the provider information providded in the results

    :param dict provider_obj: provider information
    """
    def __init__(self, provider_obj):
      self.id = int(provider_obj.pop('id'))
      self.name = provider_obj.pop('name', None)
      self.nameabbr = provider_obj.pop('nameabbr', None)
      self.url = LinkOutProvider.set_url(provider_obj.pop('url', None))

    def dump(self):
      """:rtype: dict"""
      return {'id' : self.id, 'name' : self.name, 'nameabbr' : self.nameabbr, 'url' : self.url}

  def __init__(self, unit):
    super().__init__(None, unit.pop('linkname', None))
    self.url = unit['url'].pop('value', None)
    self.iconurl = LinkOutProvider.set_url(unit.pop('iconurl', None))
    self.subjecttypes = unit.pop('subjecttypes', None)
    self.categories = unit.pop('categories', None)
    self.attributes = unit.pop('attributes', None)
    self.provider = self.Provider(unit.pop('provider', None))

  def dump(self):
    """:return: dict"""
    return dict({'iconurl' : self.iconurl, 'provider' : self.provider.dump(),
                 'categories' : self.categories, 'attributes' : self.attributes,
                 'subjecttypes' : self.subjecttypes, }, **self.basic_dump())
