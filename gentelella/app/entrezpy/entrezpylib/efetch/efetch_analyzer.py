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

.. module:: entrezpy.efetch.efetch_analyzer
  :synopsis: Exports the class EfetchAnalyzer implementing the entrezpy analysis
    of Efetch Eutils results from NCBI Eutils queries

.. moduleauthor:: Jan P Buchmann <jan.buchmann@sydney.edu.au>
"""


import json
import logging

import entrezpy.base.analyzer


logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)
logger.addHandler(logging.StreamHandler())


class EfetchAnalyzer(entrezpy.base.analyzer.EutilsAnalyzer):
  """EfetchAnalyzer implements a basic analysis of Efetch E-Utils responses.
  Stores results in a :class:`entrezpy.efetch.efetch_result.EfetchResult`
  instance.

  .. note:: This is a very superficial analyzer for documentation and
    educational purposes. In almost all cases a more specific analyzer has to be
    implemented in inheriting :class:`entrezpy.base.analyzer.EutilsAnalyzer`
    and implementing the virtual functions
    :meth:`entrezpy.base.analyzer.EutilsAnalzyer.analyze_result` and
    :meth:`entrezpy.base.analyzer.EutilsAnalzyer.analyze_error`.
  """

  def __init__(self):
    """:ivar result: :class:`entrezpy.efetch.efetch_result.EfetchResult`"""
    super().__init__()
    self.result = None

  def init_result(self, response, request):
    """Should be implemented if used properly"""
    if not self.result:
      self.result = True
      print(self.norm_response(response, request.rettype))
      return True
    return False

  def analyze_result(self, response, request):
    if not self.init_result(response, request):
      print(self.norm_response(response, request.rettype))

  def analyze_error(self, response, request):
    logger.info(json.dumps({__name__:{'Response':
                                      {'dump' : request.dump(),
                                       'error' : self.norm_response(response, request.rettype)}}}))

    logger.debug(json.dumps({__name__:{'Response-Error':
                                       {'dump' : request.dump_internals(),
                                        'error' : self.norm_response(response, request.rettype)}}}))

  def norm_response(self, response, rettype=None):
    """Normalizes response for printing

    :param response: efetch response
    :type  response: dict or `io.StringIO`
    :return: str or dict
    """
    if rettype == 'json':
      return response
    return response.getvalue()

  def isEmpty(self):
    if not self.result:
      return True
    return False
