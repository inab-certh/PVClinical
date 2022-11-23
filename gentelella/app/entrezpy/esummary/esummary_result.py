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

.. module:: entrezpy.esummary.esummary_result
  :synopsis: Exports class EsummaryResult implementing entrezpy results from
    NCBI Esummary E-Utility requests

.. moduleauthor:: Jan P Buchmann <jan.buchmann@sydney.edu.au>
"""


from app.entrezpy.base import result


class EsummaryResult(result.EutilsResult):
  """EsummaryResult stores summaries in :attr:`.summaries`, avoiding
  duplicates and quick access. EsummaryResult has no WebEnv references."""
  def __init__(self, response, request):
    super().__init__('esummary', request.query_id, request.db)
    self.summaries = {}
    if response:
      self.add_summaries(response['result'])

  def dump(self):
    """:rtype: dict"""
    return {'db':self.db, 'size' : self.size(), 'function' : self.function,
            'summaries': [self.summaries[x] for x in self.summaries]}

  def get_link_parameter(self, reqnum=0):
    """Esummary has no link automated link ability

    :return: None
    """
    return None

  def size(self):
    return len(self.summaries)

  def isEmpty(self):
    if self.size() == 0:
      return True
    return False

  def add_summaries(self, results):
    """Adds summaries form a Esummary E-Utiliy response

    :param dict results: Esummaries
    """
    if results:
      for i in results['uids']:
        if int(i) not in self.summaries:
          self.summaries[int(i)] = results.get(i)
