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

.. module:: elink_result
   :synopsis: Exports ElinkResult class implementing E-Utils results.

.. moduleauthor:: Jan P Buchmann <jan.buchmann@sydney.edu.au>
"""


import sys
import json
import logging

from app.entrezpy.base import result

logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)
logger.addHandler(logging.StreamHandler())


class ElinkResult(result.EutilsResult):
  """ The ElinkResult class implements the uniform handling of different Elink
  LinkSets instances. It creates follow-up parameters if possible. ElinkResult
  instances store all results from one Elinker query as an aggregation of
  :class:`entrezpy.elink.linkset.bare.LinkSet` instances.
  The size unit for ElinkResult is :class:`entrezpy.elink.linkset.bare.LinkSet`.

  :param str qid: query id
  :param str cmd: used Elink command
  """
  @staticmethod
  def canLink(lset):
    """
      Test if linkset can be use to generate automated  follow-up queries

      :param lset: LinkSet
      :type lset: LinkSet instance
      :returns: True if empty, False otherwise
      :rtype: bool
    """
    if lset.canLink:
      return True
    logger.info(json.dumps({__name__ : 'linkset \'{}\': no direct follow-up' \
                                       'parameters'.format(lset.category)}))
    return False

  def __init__(self, qid, cmd):
    """
    :ivar list linksets: list to store analyzed linskets
    :ivar str cmd: invoked ELink command
    """
    super().__init__('elink', qid, db=None)
    self.linksets = []
    self.cmd = cmd

  def size(self):
    """Implements :meth:`result.EutilsResult.size`.
    :rtype: int
    """
    return len(self.linksets)

  def isEmpty(self):
    """Test for empty result

      :returns: True if empty, False otherwise
      :rtype: bool
    """
    if not self.linksets:
      return True
    return False

  def add_linkset(self, linkset):
    """Store linkset in :attr:`self.linkset`

    :param linkset: populated LinkSet
    :type linkset: LinkSet instance
    """
    self.linksets.append(linkset)

  def dump(self):
    """
    :returns: all ELinkResult instance attributes
    :rtype: dict
    """
    return {'function' : self.function, 'size' : self.size(),
            'linksets' : [x.dump() for x in self.linksets]}

  def get_link_parameter(self, reqnum=0):
    """Assemble follow-up parameters depending if the History server has been
    used.

    :returns: parameters for follow-up query
    :rype: dict
    """
    if self.cmd == 'neighbor_history':
      return self.collapse_history_linksets()
    return self.collapse_uid_linksets()

  def collapse_history_linksets(self):
    """Assemble follow-up WebEnv and query_key parameters in linksets.
    Skip those who cannot and test for unexpected result

    :returns: parameters for follow-up query using History server
    :rype: dict
    """
    dbs = {}
    query_keys = []
    for i in self.linksets:
      if not ElinkResult.canLink(i):
        continue
      for j in i.linkunits:
        dbs[j.db] = 0
        query_keys.append(j.querykey)
    if not dbs:
      return None
    self.check_unexpected_dbnum(dbs)
    if len(query_keys) > 1:
      logger.debug(json.dumps({__name__: "History follow-up using term"}))
      return {'WebEnv' : self.linksets[0].linkunits[0].webenv,
              'db' : self.linksets[0].linkunits[0].db,
              'term' : ' OR '.join(str("#{0}".format(x)) for x in query_keys)}
    logger.debug(json.dumps({__name__: "History follow-up using querykey"}))
    return {'WebEnv' : self.linksets[0].linkunits[0].webenv,
            'db' : self.linksets[0].linkunits[0].db,
            'query_key' : query_keys[0]}

  def collapse_uid_linksets(self):
    """Assemble follow-up UID and database parameters in linksets.
    Skip those who cannot and test for unexpected result

    :returns: parameters for follow-up query using UIDs
    :rype: dict
    """
    dbs = {}
    for i in self.linksets:
      if not ElinkResult.canLink(i):
        continue
      for j, k in i.get_link_uids().items():
        if j not in dbs:
          dbs[j] = []
        dbs[j] += k
    if not dbs:
      return None
    self.check_unexpected_dbnum(dbs)
    for i in dbs:
      return {'db': i, 'id' : dbs[i]}

  def check_unexpected_dbnum(self, dbs):
    """Deal with more databases than expected when linking. Expecting one
    database per request for linking. Abort if more are present since this is
    unexpected.  It shouldn't happen, but make sure to catch such a case, report
    it and abort.

    :param dbs dbs: unique database names encountered in all LinkSets
    """
    if len(dbs) > 1:
      sys.exit(json.dumps({__name__:
                           {'Unexpected': 'more than 1 dbto in history linking' \
                            'parameter. Contact developer and/or raise issue/bug',
                            'dbs' : [x for x in dbs],
                            'action' : 'abort'}}))
