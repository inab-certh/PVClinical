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

.. module:: entrezpy.base.analyzer
  :synopsis: Exports the base class for entrezpy analzyer for NCBI E-Utils
    responses

.. moduleauthor:: Jan P Buchmann <jan.buchmann@sydney.edu.au>
"""


import io
import sys
import json
import logging
import xml.etree.ElementTree


logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)
logger.addHandler(logging.StreamHandler())


class EutilsAnalyzer:
  """EutilsAnalyzer is the base class for an entrezpy analyzer.
  It prepares the response based on the requested format and checks for
  E-Utilities errors. The function parse() is invoked after every request by the
  corresponding query class, e.g. Esearcher. This allows analyzing data as it
  arrives without waiting until larger queries have been fetched. This approach
  allows implementing analyzers which can store already downloaded data to
  establish checkpoints or trigger other actions based on the received data.

  Two virtual classes are the core and need their own implementation to support
  specific queries:

  - :meth:`.analyze_error`
  - :meth:`.analyze_result`

  .. note::
    Responses from NCBI are not very well documented and functions will
    be extended as new errors are encountered."""

  known_fmts = {'xml', 'json', 'text'}
  """Store formats known to EutilsAnalzyer"""

  def __init__(self):
    """Inits EutilsAnalyzer with unknown type of result yet. The result needs to
    be set upon receiving the first response by :meth:`.init_result`.

    :ivar bool hasErrorResponse: flag indicating error in response
    :ivar result: result instance
    :type result: :class:`entrezpy.base.result.EutilsResult`
    """
    self.hasErrorResponse = False
    self.result = None

  def init_result(self, response, request):
    """Virtual function to initialize result instance. This allows to set
    attributes from the first response and request.

    :param response: converted response from :meth:`.convert_response`
    :type  response: dict or `io.StringIO`
    :raises NotImplementedError: if implementation is missing
    """
    raise NotImplementedError("Require implementation of analyze_error()")

  def analyze_error(self, response, request):
    """Virtual function to handle error responses

    :param response: converted response from :meth:`.convert_response`
    :type  response: dict or `io.StringIO`
    :raises NotImplementedError: if implementation is missing
    """
    raise NotImplementedError("Require implementation of analyze_error()")

  def analyze_result(self, response, request):
    """Virtual function to handle responses, i.e. parsing them and prepare
    them for :class:`entrezpy.base.result.EutilsResult`

    :param response: converted response from :meth:`.convert_response`
    :type  response: dict or `io.StringIO`
    :raises NotImplementedError: if implementation is missing
    """
    raise NotImplementedError("Require implementation of analyze_result()")

  def parse(self, raw_response, request):
    """Check for errors and calls parser for the raw response.

    :param raw_response: response from :class:`entrezpy.requester.requester.Requester`
    :type  raw_response: :class:`urllib.request.Request`
    :param request: query request
    :type  request: :class:`entrezpy.base.request.EutilsRequest`
    :raises NotImplementedError: if request format is not in
      :attr:`EutilsAnalyzer.known_fmts`"""
    if request.retmode not in EutilsAnalyzer.known_fmts:
      raise NotImplementedError("Unknown format: {}".format(request.retmode))
    response = self.convert_response(raw_response, request)
    if self.isErrorResponse(response, request):
      self.hasErrorResponse = True
      self.analyze_error(response, request)
    else:
      self.analyze_result(response, request)

    if self.result is None:
      logger.error(json.dumps({__name__ : {'Error' : 'result attribute not set. Something went wrong',
                                           'action' : 'abort'}}))
      sys.exit()

  def convert_response(self, raw_response, request):
    """Converts raw_response into the expected format, deduced from request and
    set via the retmode parameter.

    :param raw_response:  response :class:`entrezpy.requester.requester.Requester`
    :type  raw_response: :class:`urllib.request.Request`
    :param request: query request
    :type  request: :class:`entrezpy.base.request.EutilsRequest`
    :return: response in parseable format
    :rtype: dict or :class:`io.stringIO`"""
    if request.retmode == 'json':
      return json.loads(raw_response.read().decode('utf-8'))
    return io.StringIO(raw_response.read().decode('utf-8'))

  def isErrorResponse(self, response, request):
    """Checking for error messages in response from Entrez Servers and set flag
    :attr:`.hasErrorResponse`.

    :param response: parseable response from :meth:`.convert_response`
    :type  response: dict or :class:`io.stringIO`
    :param request: query request
    :type  request: :class:`entrezpy.base.request.EutilsRequest`
    :return: error status
    :rtype: bool"""
    if request.retmode == 'xml':
      self.hasErrorResponse = self.check_error_xml(response)
      response.seek(0)
    if request.retmode == 'json':
      self.hasErrorResponse = self.check_error_json(response)
    return self.hasErrorResponse

  def check_error_xml(self, response):
    """Checks for errors in XML responses

    :param response: XML response
    :type response: :class:`io.stringIO`
    :return: if XML response has error message
    :rtype: bool"""
    for _, elem in xml.etree.ElementTree.iterparse(response, events=["end"]):
      if elem.tag == 'ERROR':
        elem.clear()
        return True
      elem.clear()
    return False

  def check_error_json(self, response):
    """Checks for errors in JSON responses. Not unified among Eutil functions.

    :param dict response: reponse
    :return: status if JSON response has error message
    :rtype: bool"""
    if response['header']['type'] == 'esearch' and 'ERROR' in response['esearchresult']:
      return True
    if response['header']['type'] == 'elink' and 'ERROR' in response:
      return True
    if 'esummaryresult' in response:
      if response['esummaryresult'][0].split(' ')[0] == 'Invalid':
        return True
    if 'error' in response:
      return True
    return False

  def isSuccess(self):
    """Test if response has errors

    :rtype: bool"""
    if self.hasErrorResponse:
      return False
    return True

  def get_result(self):
    """Return result

    :return: result instance
    :rtype: :class:`entrezpy.base.result.EutilsResult`
    """
    return self.result

  def follow_up(self):
    """Return follow-up parameters if available

    :return: Follow-up parameters
    :rtype: dict
    """
    return self.result.get_link_parameter()

  def isEmpty(self):
    """Test for empty result

    :rtype: bool
    """
    if self.result.size() == 0:
      return True
    return False
