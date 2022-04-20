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

.. module:: entrezpy.requester.requester
  :synopsis: Exports class Requester handling HTTP requests for entrezpy.

.. moduleauthor:: Jan P Buchmann <jan.buchmann@sydney.edu.au>
"""


import sys
import random
import json
import time
import socket
import logging
import urllib.parse
import urllib.request
import urllib.error

logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)
logger.addHandler(logging.StreamHandler())


class Requester:
  """Requester implements the sendong of HTTP POST requests and the receiving
  of the result. It checks for request connection errors and performs retries
  when possible. If the maximum number of retries is reached, the request is
  conisdered failed.  In case of connections errors, abort if the error is not
  due to timeout. The initial timeout is increased insteps until the maximum
  timeout has been reached.

  :param float wait: wait time in seconds between requests
  :param int max_retries: number of rertries before giving up.
  :param int init_timeout: number of seconds before the initial request is consid
                           considered a timeout error
  :param int timeout_max: maximum requet timeout before giving up
  :param int timeout_steps: increase value for timeout errors
  """
  def __init__(self, wait, max_retries=9, init_timeout=10, timeout_max=60, timeout_step=5):
    self.wait = wait
    self.max_retries = max_retries
    self.init_timeout = init_timeout
    self.timeout_max = timeout_max
    self.timeout_step = timeout_step
    logger.info(json.dumps({__name__ : {'settings' : {'wait[s]' : self.wait,
                                                      'timeout-min[s]' : self.init_timeout,
                                                      'timeout-max[s]' : self.timeout_max,
                                                      'timeout-increase[s]' : self.timeout_step,
                                                      'max-retries' : self.max_retries}}}))
  def request(self, req):
    """Request the request

    :param req: entrezpy request
    :type  req: :class:`entrezpy.base.request.EutilsRequest`
    """
    retries = 0
    success = False
    req_timeout = self.init_timeout
    while not success:
      wait = self.wait
      try:
        data = urllib.parse.urlencode(req.get_post_parameter(), doseq=req.doseq).encode('utf-8')
        req.qry_url = data.decode()
        logger.debug(json.dumps({__name__ : {'Request' : {'try' : retries,
                                                          'req-id' : req.id,
                                                          'req-query' : req.query_id,
                                                          'req-url' : req.url,
                                                          'qry-url' : req.qry_url}}}))
        req.set_status_success()
        return urllib.request.urlopen(urllib.request.Request(req.url, data=data),
                                      timeout=req_timeout)
      except urllib.error.HTTPError as http_err:
        log_msg = {'HTTP-error': {'code' : http_err.code, 'reason' : http_err.reason}}
        if http_err.code == 400: # Bad request form, stop right now
          log_msg['HTTP-error'].update({'action' : 'abort'})
          logger.debug(json.dumps({__name__ : {'Request-error' : log_msg}}))
          sys.exit()
        log_msg['HTTP-error'].update({'action' : 'retry'})
        logger.debug(json.dumps({__name__ : {'HTTP-error': log_msg}}))
        retries += 1
        wait = random.randint(1, 3)
      except urllib.error.URLError as url_err:
        req.set_request_error(url_err.reason)
        print(url_err.reason)
        logger.debug(json.dumps({__name__ : {'Request-error' : {'URL-error' : url_err.reason,
                                                                'action' : 'retry'}}}))
        retries += 1
        wait = random.randint(1, 3)
      except socket.timeout:
        req_timeout += self.timeout_step
        logger.info(json.dumps({__name__ : {'Timeout' :{'action' : 'retry',
                                                        'wait' : wait,
                                                        'timeout' : req_timeout,
                                                        'increase' :self.timeout_step}}}))
        retries += 1
        if req_timeout > self.timeout_max:
          logger.info(json.dumps({__name__: {'MaxTimeout' : {'action' : 'giving up on request',
                                                             'timeout': req_timeout}}}))
          req.set_request_error("MaxTimeout")
          return None
      else:
        if retries > self.max_retries:
          logger.info(json.dumps({__name__ : {'MaxRetry' : {'action' : 'giving up on this request',
                                                            'retries' : retries,
                                                            'max' : self.max_retries}}}))
          req.set_request_error("MaxRetry")
          return None
        success = True
      time.sleep(wait)
