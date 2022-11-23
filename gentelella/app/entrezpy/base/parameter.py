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

.. module:: entrezpy.base.parameter
  :synopsis: Export the base class for entrezpy parameters in NCBI E-Utils
    queries

.. moduleauthor:: Jan P Buchmann <jan.buchmann@sydney.edu.au>
"""


import sys
import json
import logging


logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)
logger.addHandler(logging.StreamHandler())


class EutilsParameter:
  """ EutilsParameter set and check parameters for each query. EutilsParameter
  is populated from a dictionary with valid E-Utilities parameters for the
  corresponding query. It declares virtual functions where necessary.

  Simple helper functions are presented to test the common parameters `db`,
  `WebEnv`, `query_key` and `usehistory`.

  .. note::  :attr:`.usehistory` is the parameter used for Entrez history
    queries and is set to `True` (use it) by default. It can be set to `False`
    to ommit history server use.

  :meth:`.haveExpectedRequests` tests if the  of the number of requests has been
  calculated.

  The virtual methods :meth:`.check` and :meth:`.dump` need thrir own
  implementation since they can vary between queries.

  .. warning:: :meth:`.check` is expected to run after all parameters have been
    set.

  :param dict parameter: Eutils query parameters
  """

  def __init__(self, parameter=None):
    """:ivar str db: Entrez database name
    :ivar str webenv: WebEnv
    :ivar int querykey: querykey
    :ivar int expected_request: number of expected request for the query
    :ivar bool doseq: use `id=` parameter for each uid in POST
    """
    if not parameter:
      logger.error(json.dumps({__name__ : {'Error' : 'Missing query parameters',
                                           'action' : 'abort'}}))
      sys.exit()
    self.db = parameter.get('db')
    self.webenv = parameter.get('WebEnv')
    self.querykey = parameter.get('query_key', 0)
    self.expected_requests = 1
    self.doseq = False
    self.usehistory = True

  def haveDb(self):
    """Check for required db parameter

    :rtype: bool
    """
    if self.db:
      return True
    return False

  def haveWebenv(self):
    """Check for required WebEnv parameter

    :rtype: bool
    """
    if self.webenv:
      return True
    return False

  def haveQuerykey(self):
    """Check for required QueryKey parameter

    :rtype: bool
    """
    if self.querykey:
      return True
    return False

  def useHistory(self):
    """Check if history server should be used.

    :rtype: bool
    """
    if self.usehistory:
      return True
    return False


  def haveExpectedRequets(self):
    """Check fo expected requests. Hints an error if no requests are expected.

    :rtype: bool
    """
    if self.expected_requests > 0:
      return True
    return False

  def check(self):
    """Virtual function to run a check before starting the query. This is a
    crucial step and should abort upon failing.

    :raises NotImplementedError: if not implemented
    """
    raise NotImplementedError()

  def dump(self):
    """Dump instance attributes

    :rtype: dict
    :raises NotImplementedError: if not implemented
    """
    raise NotImplementedError()
