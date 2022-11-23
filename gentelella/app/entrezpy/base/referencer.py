"""
..
  Copyright 2018 The University of Sydney
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

.. module:: entrezpy.base.referencer
  :synopsis: Exports the EutilReferencer class managing WebEnv and query keys
    for entrezpy queries

.. moduleauthor:: Jan P Buchmann <jan.buchmann@sydney.edu.au>
"""


class EutilReferencer:
  """EutilReferences handles History Server references for queries. WenEnv and
  corresponding query keys are stored and can be retrieved either as whole, i.e.
  Webenv and all corresponding query keys or as specific queryley for a webenv.
  Query keys for each WebeVn are stored in a list and can be retrieved as
  the N-th request for WebEnv, i.e. the first reuquest is at index 0, the last
  at -1.
  """

  class Reference:
    """Acting as struct to return all querykeys for a WebEnv"""
    def __init__(self, webenv, querykeys):
      self.webenv = webenv
      self.querykeys = querykeys

  def __init__(self, webenv, querykey):
    """:param str webenv: WebEnv
       :param int webenv: querykey
    """
    self.references = {}
    if webenv:
      self.add_reference(webenv, querykey)

  def add_reference(self, webenv, querykey):
    """Adds new refernce

    :param str webenv: WebEnv
    :param int webenv: querykey
    """
    if webenv not in self.references:
      self.references[webenv] = []
    self.references[webenv].append(int(querykey))

  def get_reference(self, webenv):
    """:param str webenv: WebEnv
       :return: History server reference for webenv
       :rtype: :class:'EutilReference.Reference' instance or None
    """
    if webenv not in self.references:
      return None
    return self.Reference(webenv, self.references[webenv])

  def get_querykey(self, webenv, querynum):
    """:return: query key for N-th query as list index, i.e. first = 0
       :rtype: int or None
    """
    if webenv not in self.references:
      return None
    if (querynum+1) > len(self.references[webenv]):
      return None
    return self.references[webenv][querynum]

  def dump(self):
    """Return all references

    :rtype: dict"""
    return self.references

  def size(self):
    """:rtype: int"""
    return len(self.references)
