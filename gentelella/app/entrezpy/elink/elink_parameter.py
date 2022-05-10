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

.. module:: entrezpy.elink.elink_parameter
  :synopsis:
    Exports class ElinkParameters  for NCBI E-Utils queries.

.. moduleauthor:: Jan P Buchmann <jan.buchmann@sydney.edu.au>
"""


import sys
import json
import logging

from app.entrezpy.base import parameter


logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)
logger.addHandler(logging.StreamHandler())


class ElinkParameter(parameter.EutilsParameter):
  """ElinkParameter checks query specific parameters and configures a
  :class:`entrezpy.elink.elink_query.ElinkQuery` instance. A link gets its size
  from :attr:`entrezpy.elink.elink_parameter.ElinkParameter.uids` (from the `id`
  Eutils parameter) or earlier result stored on the Entrez history server.
  :attr:`entrezpy.elink.elink_parameter.ElinkParameter.retmode` is JSON where
  possible and :attr:`entrezpy.elink.elink_parameter.ElinkParameter.cmd` is
  `neighbor`. ELink has no set maximum for UIDs which can be linked in one
  query, fixing :attr:`entrezpy.elink.elink_parameter.ElinkParameter.query_size`,
  :attr:`entrezpy.elink.elink_parameter.ElinkParameter.request_size`, and
  :attr:`entrezpy.elink.elink_parameter.ElinkParameter.expected_requests` to 1.

  :param dict parameter: Eutils Elink parameter
  """

  nodb_cmds = {'acheck', 'ncheck', 'lcheck', 'llinks', 'llinkslib', 'prlinks'}
  """Elink commands not requiring the `db` parameter"""

  retmodes = {'llinkslib' : 'xml'}
  """The llinkslib elink command is the only command only returning XML"""

  def_retmode = 'json'
  """Use JSON whenever possible"""


  def __init__(self, parameter):
    super().__init__(parameter)
    self.cmd = parameter.get('cmd', 'neighbor')
    self.dbfrom = parameter.get('dbfrom')
    self.uids = parameter.get('id', [])
    self.retmode = self.set_retmode(parameter.get('retmode'))
    self.linkname = parameter.get('linkname')
    self.term = parameter.get('term')
    self.holding = parameter.get('holding')
    self.datetype = parameter.get('datetype')
    self.reldate = parameter.get('reldate')
    self.mindate = parameter.get('mindate')
    self.maxdate = parameter.get('maxdate')
    self.doseq = parameter.get('link', True)
    self.query_size = 1
    self.request_size = 1
    self.expected_requests = 1
    self.check()
    logger.debug(json.dumps({__name__ : {'dump' : self.dump()}}))

  def check(self):
    """
    Implements :meth:`parameter.check` and aborts if required
    parameters  are missing.
    """
    if self.cmd not in ElinkParameter.nodb_cmds and not self.haveDb():
      logger.error(json.dumps({__name__ : {'error' : {'Missing required parameters' : 'db, cmd'},
                                           'action' : 'abort'}}))
      sys.exit()
    if not self.dbfrom:
      logger.error(json.dumps({__name__ : {'error' : {'Missing required parameter' : 'dbfrom'},
                                           'action' : 'abort'}}))
      sys.exit()

    if not self.uids and not self.haveWebenv and not self.haveQuerykey:
      logger.error(json.dumps({__name__ : {'error' : {'Missing required parameters' : {
      'ids' : self.uids,
      'QueryKey' : self.querykey,
      'WebEnv' : self.webenv}},
                                           'action' : 'abort'}}))
      sys.exit()

  def set_retmode(self, retmode):
    """Checks for valid and supported Elink retmodes

    :param str retmode: requested retmode
    :return: default or cmd adjusted cretmode
    :rtype: str
    """
    if retmode == 'ref':
      logger.info(json.dumps({__name__ : "retmode ref not supported. Check documentation." \
                                         "Using {}".format(ElinkParameter.def_retmode)}))
      return ElinkParameter.def_retmode
    return ElinkParameter.retmodes.get(self.cmd, ElinkParameter.def_retmode)

  def dump(self):
    """:return: Instance attributes
    :rtype: dict
    """
    return {'db' : self.db,
            'WebEnv':self.webenv,
            'query_key' : self.querykey,
            'dbfrom' : self.dbfrom,
            'cmd' : self.cmd,
            'uids' : self.uids,
            'retmode' : self.retmode,
            'linkname' : self.linkname,
            'term' : self.term,
            'holding' : self.holding,
            'datetype' : self.datetype,
            'doseq' : self.doseq,
            'reldate' : self.reldate,
            'mindate' : self.mindate,
            'maxdate' : self.maxdate,
            'query_size' : self.query_size,
            'request_size' : self.request_size,
            'expected_requets' : self.expected_requests}
