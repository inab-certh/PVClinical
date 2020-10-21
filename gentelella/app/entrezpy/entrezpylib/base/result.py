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

.. module:: entrezpy.base.result
  :synopsis: Exports the base class for entrezpy results from NCBI E-Utils
    queries

.. moduleauthor:: Jan P Buchmann <jan.buchmann@sydney.edu.au>
"""

import entrezpy.base.referencer


class EutilsResult:
  """EutilsResult is the base class for an entrezpy result. It sets the
  required result attributes common for all result and declares virtual
  functions to interact with other entrezpy classes. Empty results are
  successful results since no query error has been received.
  :meth:`entrezpy.base.result.EutilsResult.size` is important to

  - determine if and how many follow-up requests are required
  - if it's an empty result

  :param string function: EUtil function of the result
  :param string qid: query id
  :param string db: Entrez database name for result
  :param string webenv: WebEnv of response
  :param int querykey: querykey of response
  """

  def __init__(self, function, qid, db, webenv=None, querykey=None):
    self.function = function
    self.query_id = qid
    self.db = db
    self.webenv = webenv
    self.references = entrezpy.base.referencer.EutilReferencer(self.webenv, querykey)

  def size(self):
    """Returns result size in the corresponding ResultSize unit

    :rtype: int
    :raises NotImplementedError: if implementation is missing"""
    raise NotImplementedError("Help! Require implementation")

  def dump(self):
    """Dumps all instance attributes

    :rtype: dict
    :raises NotImplementedError: if implementation is missing"""
    raise NotImplementedError("Help! Require implementation")

  def get_link_parameter(self, reqnum=0):
    """Assembles parameters for automated follow-ups. Use the query key from
    the first request by default.

    :param int reqnum: request number for which query_key should be returned
    :return: EUtils parameters
    :rtype: dict
    :raises NotImplementedError: if implementation is missing"""
    raise NotImplementedError("Help! Require implementation")

  def isEmpty(self):
    """Indicates empty result.

    :rtype: bool
    :raises NotImplementedError: if implementation is missing"""
    raise NotImplementedError("Help! Require implementation")
