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

.. module:: entrezpy.elinker.elink_analyzer
   :synopsis: Exports the ElinkeAnalzyer class to analyze Elink query results.

.. moduleauthor:: Jan P Buchmann <jan.buchmann@sydney.edu.au>
"""


import sys
import json
import logging
import xml.etree.ElementTree

import entrezpy.base.analyzer
import entrezpy.elink.elink_result
from entrezpy.elink.linkset import bare
from entrezpy.elink.linkset import linked
from entrezpy.elink.linkset import relaxed


logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)
logger.addHandler(logging.StreamHandler())


class ElinkAnalyzer(entrezpy.base.analyzer.EutilsAnalyzer):
  """ElinkAnalyzer implements parsing and superficial analysis of responses
  from ELink queries. ElinkAnalyzer implements the virtual methods
  :meth:`.analyze_result` and :meth:`.analyze_error`. The variety in possible
  Elink response formats results in several specialized parser. Default is to
  obtain results in JSON.

  ElinkAnalyzer instances create :class:`linked.Linkset` or
  :class:`relaxed.Linkset` instances, depending on the request Elink result.
  :func:`entrezpy.elink.linkset.bare.Linkset.new_unit` is called to set the
  type of LinkSet unit based ont he used Elink command.

  .. warning:: Expect for 'llinkslib', all responses are expected in JSON.
                 ElinkAnalyzer will abort if a response from another command is
                 not in JSON.
  """

  def __init__(self):
    """:ivar result: :class:`entrezpy.elink.elink_result.ElinkResult`"""
    super().__init__()

  def init_result(self, response, request):
    """Inits :class:`entrezpy.elink.elink_result.ElinkResult`"""
    if not self.result:
      self.result = entrezpy.elink.elink_result.ElinkResult(request.query_id,
                                                            request.cmd)

  def analyze_error(self, response, request):
    """Implements virtual function :func:`entrezpy.base.analyzer.analyze_error`.
    """
    logger.info(json.dumps({__name__:{'Response-Error':
                                      {'request-dump' : request.dump_internals(),
                                       'error' : response}}}))

  def analyze_result(self, response, request):
    """Implements virtual method :meth:`entrezpy.base.analyzer.analyze_result`.

    Checks used elink command and runs according parser to populate result.
    """
    self.init_result(response, request)
    if request.cmd != 'llinkslib' and request.retmode != 'json':
      sys.exit(logger.info(json.dumps({__name__:{'Not implemented Error':
                                                 {'Command' : request.cmd,
                                                  'Format' : request.retmode}}})))
    if request.retmode == 'json':
      logger.debug(json.dumps({__name__: {"Response" : response}}))
    else:
      logger.debug(json.dumps({__name__: {"Response" : response.getvalue()}}))
    if request.cmd == 'llinkslib':  # only available as XML, groan
      self.parse_llinkslib(response, request.cmd)
    elif request.cmd in entrezpy.elink.linkset.bare.LinkSet.link_linksets:
      self.analyze_links(response['linksets'], request.cmd)
    elif request.cmd in entrezpy.elink.linkset.bare.LinkSet.list_linksets:
      self.analyze_linklist(response['linksets'], request.cmd)
    else:
      sys.exit(logger.debug(json.dumps({__name__: {'Error' : {'Unknown elink cmd' : request.cmd,
                                                              'action' : 'abort'}}})))

  def analyze_linklist(self, linksets, cmd):
    """Parses ELink responses listing link information for UIDs.

    :param dict linksets: 'linkset' part in an ELink JSON response from NCBI.
    :param str cmd: ELink command.
    """
    for i in linksets:
      if 'idurllist' in i:
        for j in i.get('idurllist'):
          lset = linked.LinkedLinkset(j['id'], i['dbfrom'], canLink=False)
          logger.debug(json.dumps({__name__ : "Created {}".format(lset.dump())}))
          for k in j['objurls']:
            lset.add_linkunit(bare.LinkSet.new_unit(cmd).new(k))
            logger.debug(json.dumps({__name__ : "Added {}".format(lset.linkunits[-1].dump())}))
          self.result.add_linkset(lset)
      elif 'idlinksets' in i['idchecklist']:
        for j in i['idchecklist'].get('idlinksets'):
          lset = linked.LinkedLinkset(j['id'], i['dbfrom'], canLink=False)
          logger.debug(json.dumps({__name__ : "Created {}".format(lset.dump())}))
          for k in j['linkinfos']:
            lset.add_linkunit(bare.LinkSet.new_unit(cmd).new(k['dbto'],
                                                             k['linkname'],
                                                             k.get('menutag'),
                                                             k.get('htmltag'),
                                                             k.get('priority')))
            logger.debug(json.dumps({__name__ : "Added {}".format(lset.linkunits[-1].dump())}))
          self.result.add_linkset(lset)
      elif 'ids' in i['idchecklist']:
        for j in i['idchecklist'].get('ids'):
          lset = linked.LinkedLinkset(j['value'], i['dbfrom'], canLink=False)
          logger.debug(json.dumps({__name__ : "Created {}".format(lset.dump())}))
          if 'hasneighbor' in j:
            lset.add_linkunit(bare.LinkSet.new_unit(cmd).new(i['dbfrom'], j['hasneighbor']))
            logger.debug(json.dumps({__name__ : "Added {}".format(lset.linkunits[-1].dump())}))
          if 'haslinkout' in j:
            lset.add_linkunit(bare.LinkSet.new_unit(cmd).new(i['dbfrom'], j['haslinkout']))
            logger.debug(json.dumps({__name__ : "Added {}".format(lset.linkunits[-1].dump())}))
          self.result.add_linkset(lset)

  def analyze_links(self, linksets, cmd):
    """Parses ELink responses with links  as UIDs or History server references.

    :param dict linksets: 'linkset' part in an ELink JSON response from NCBI.
    :param str cmd: ELink command.
    """
    for i in linksets:
      lset = linked.LinkedLinkset(i['ids'][0], i['dbfrom'])  #assume 1-to-many link as default
      if len(i['ids']) > 1: # OK, it's many-to-many
        lset = relaxed.RelaxedLinkset(i['ids'], i['dbfrom'])
        logger.debug(json.dumps({__name__ : "Created {}".format(lset.dump())}))
      if 'linksetdbs' in i:
        for j in i['linksetdbs']:
          if 'ERROR' in j:
            logger.info(json.dumps({__name__:{'Response-Error':{'error' : j['ERROR']}}}))
            self.hasErrorResponse = True
          if 'links' in j:
            for k in j['links']:
              lset.add_linkunit(bare.LinkSet.new_unit(cmd).new(k, j['dbto'], j['linkname']))
              logger.debug(json.dumps({__name__ : "Added {}".format(lset.linkunits[-1].dump())}))
      elif 'linksetdbhistories' in i:
        for j in i['linksetdbhistories']:
          lset.add_linkunit(bare.LinkSet.new_unit(cmd).new(j['dbto'], j['linkname'],
                                                           i['webenv'], j['querykey']))
          logger.debug(json.dumps({__name__ : "Added {}".format(lset.linkunits[-1].dump())}))
      else:
        logger.debug(json.dumps({__name__ : 'Empty'}))
        continue
      self.result.add_linkset(lset)

  def parse_llinkslib(self, response, cmd, lset=None):
    """Exclusive XML parser for 'llinkslib' responses. Its approach is ugly but
    parses the XML. The cmd parametes is always 'llinkslib' but retains the
    calling signature.

    :param io.StringIO response: XML response from Entrez
    :param str cmd: used ELink command command
    """
    provider_tagmap = {'iconurl', 'id', 'url', 'name', 'nameabbr'}
    unit_tagmap = {'iconurl', 'url', 'name', 'nameabbr', 'attribute',
                   'category', 'linkname', 'subjecttype'}
    unit = {'attributes' : [], 'provider' : {}}
    dbfrom = None
    isLinkset = False
    isObjurl = False
    isProvider = False
    for event, elem in xml.etree.ElementTree.iterparse(response, events=['start', 'end']):
      if event == 'start':
        if elem.tag == 'LinkSet':
          isLinkset = True
        if elem.tag == 'ObjUrl':
          isObjurl = True
          unit = {'attributes' : [], 'provider' : {}}

      if event == 'end':
        if elem.tag == 'LinkSet':
          isLinkset = False
        if elem.tag == 'ObjUrl':
          isObjurl = False
          lset.add_linkunit(bare.LinkSet.new_unit(cmd).new(unit))
          logger.debug(json.dumps({__name__ : "Added {}".format(lset.linkunits[-1].dump())}))
        if elem.tag == 'IdUrlSet':
          self.result.add_linkset(lset)

      if isLinkset and not isObjurl:
        if event == 'end' and elem.tag == 'DbFrom':
          dbfrom = elem.text
        if elem.tag == 'Id' and not isObjurl:
          lset = linked.LinkedLinkset(int(elem.text), dbfrom, canLink=False)
          logger.debug(json.dumps({__name__ : "Created {}".format(lset.dump())}))

      if isLinkset and isObjurl:
        if elem.tag == 'Provider':
          isProvider = bool(event == 'start')

        if event == 'end' and elem.tag.lower() in unit_tagmap:
          if elem.tag.lower() == 'attribute':
            unit['attributes'].append(elem.text)
          elif isProvider and elem.tag.lower() in provider_tagmap:
            unit['provider'][elem.tag.lower()] = elem.text
          else:
            unit[elem.tag.lower()] = elem.text
          elem.clear()
