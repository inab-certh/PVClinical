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

.. module:: entrezpy.base.query
  :synopsis: Exports the base class for entrezpy queries to NCBI E-Utils

.. moduleauthor:: Jan P Buchmann <jan.buchmann@sydney.edu.au>
"""


import os
import uuid
import base64
import atexit
import queue
import threading

import entrezpy.requester.requester
import entrezpy.base.monitor


class EutilsQuery:
  """ EutilsQuery implements the base class for all entrezpy queries to
  E-Utils. It handles the information required by every query, e.g. base query
  url, email address, allowed requests per second, apikey,  etc. It declares
  the virtual method :meth:`.inquire` which needs to be implemented by every
  request since they differ among queries.

  An NCBI API key will bet set as follows:

  - passed as argument during initialization
  - check enviromental variable passed as argument
  - check enviromental variable NCBI_API_KEY

  Upon initalization, following parameters are set:

  - set unique query id
  - check for / set NCBI apikey
  - initialize :class:`entrezpy.requester.requester.Requester` with allowed
    requests per second
  - assemble Eutil url for desire EUtils function
  - initialize Multithreading queue and register query at
    :class:`entrezpy.base.monitor.QueryMonitor` for logging

  Multithreading is handled using the nested classes
  :class:`entrezpy.base.query.EutilsQuery.RequestPool` and
  :class:`entrezpy.base.query.EutilsQuery.ThreadedRequester`."""

  base_url = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils"
  """Base url for all Eutil request"""

  query_requester = None
  """References :class:`entrezpy.requester.requester.Requester` """

  query_monitor = entrezpy.base.monitor.QueryMonitor()
  """References :class:`entrezpy.base.monitor.QueryMonitor` """

  @staticmethod
  def run_one_request(request):
    """Processes one request from the queue and logs its progress.

    :param request: single entrezpy request
    :type  request: :class:`entrezpy.base.request.EutilsRequest`
    """
    request.start_stopwatch()
    o = EutilsQuery.query_monitor.get_observer(request.query_id)
    o.observe(request)
    response = EutilsQuery.query_requester.request(request)
    request.calc_duration()
    o.processed_requests += 1
    return response

  class RequestPool:
    """ Threading Pool for requests. This class inits the threading pool,
    adds requests waits until all threads finish. A request consist of a tuple
    with the request and corresponding analyzer. Failed requests are stored
    separately to handle them later. If the number of threads is 0, use
    :meth:`entrezpy.base.query.EutilsQuery.RequestPool.run_single`. Otherwise,
    call :class:`entrezpy.base.query.EutilsQuery.ThreadedRequester`
    This is useful in cases where analyzers are calling not thread-safe methods
    or classes, e.g. Sqlite3
    """

    def __init__(self, num_threads, failed_requests):
      """Initiates a threading pool with a given number of threads.

      :param int num_threads: number of threads
      :param reference failed_requests:
        :attr:`entrezpy.base.query.EutilsQuery.failed_requests`
      :ivar requests: request queue
      :type requests: :class:`queue.Queue`
      :ivar bool useThreads: flag to use single ot multithreading
      """
      self.requests = queue.Queue(num_threads)
      self.failed_requests = failed_requests
      atexit.register(self.destructor)
      self.useThreads = True if num_threads > 0 else False
      if self.useThreads:
        for _ in range(num_threads):
          EutilsQuery.ThreadedRequester(self.requests, self.failed_requests)

    def add_request(self, request, analyzer):
      """Adds one request into the threading pool as
      **tuple**\ (`request`, `analzyer`).

      :param  request: entrezpy request instance
      :type   request: :class:`entrezpy.base.request.EutilsRequest`
      :param analyzer: entrezpy analyzer instance
      :type  analyzer: :class:`entrezpy.base.analyzer.EutilsAnalyzer`
      """
      self.requests.put((request, analyzer))

    def drain(self):
      """Empty threading pool and wait until all requests finish"""
      if self.useThreads:
        self.requests.join()
      else:
        self.run_single()

    def run_single(self):
      """Run single threaded requests."""
      while not self.requests.empty():
        request, analyzer = self.requests.get()
        response = EutilsQuery.run_one_request(request)
        if response:
          analyzer.parse(response, request)
        else:
          self.failed_requests.append(request)

    def destructor(self):
      """ Shutdown all ongoing threads when exiting due to an error.

      .. note::
        Deamon processes don't always stop when the main
        program exits and hang aroud. atexit.register(self.desctructor) seems
        to be a way to implement a dectructor. Currently not used.
      """
      pass

  class ThreadedRequester(threading.Thread):
    """ThreadedRequester handles multitthreaded request. It inherits from
    :class:`threading.Thread`. Requests are fetched  from
    :class:`entrezpy.base.query.EutilsQuery.RequestPool` and processed in
    :meth:`.run`.
    """
    def __init__(self, requests, failed_requests):
      """Inits :class:`.ThreadedRequester` to handle multithreaded requests.

      :param reference requests:
        :attr:`entrezpy.base.query.EutilsQuery.RequestPool.requests`
      :type reference failed_request:
        :attr:`entrezpy.base.query.EutilsQuery.failed_requests`
      """
      super().__init__(daemon=True)
      self.requests = requests
      self.failed_requests = failed_requests
      self.start()

    def run(self):
      """Overwrite :meth:`threading.Thread.run` for multithreaded requests."""
      while True:
        request, analyzer = self.requests.get()
        response = EutilsQuery.run_one_request(request)
        if response:
          analyzer.parse(response, request)
        else:
          self.failed_requests.append(request)
        self.requests.task_done()

  def __init__(self, eutil, tool, email, apikey=None, apikey_var=None, threads=None, qid=None):
    """Inits EutilsQuery instance with eutil, toolname, email, apikey,
    apikey_envar, threads and qid.

    :param str eutil: name of eutil function on EUtils server
    :param str tool: tool name
    :param str email: user email
    :param str apikey: NCBI apikey
    :param str apikey_var: enviroment variable storing NCBI apikey
    :param int threads: set threads for multithreading
    :param str qid: unique query id

    :ivar id: unique query id
    :ivar base_url: unique query id
    :ivar int requests_per_sec:  default limit of requests/sec (set by NCBI)
    :ivar int max_requests_per_sec:  max.requests/sec with apikeyby (set NCBI)
    :ivar str url:  full URL for Eutil function
    :ivar str contact:  user email (required by NCBI)
    :ivar str tool:  tool name (required by NCBI)
    :ivar str apikey:  NCBI apikey
    :ivar int num_threads:  number of threads to use
    :ivar list failed_requests: store failed requests for analysis if desired
    :ivar request_pool: :class:`entrezpy.base.query.EutilsQuery.RequestPool` instance
    :ivar int request_counter: requests counter for a EutilsQuery instance
    """
    self.id = base64.urlsafe_b64encode(uuid.uuid4().bytes).decode('utf-8') if not qid else qid
    self.eutil = eutil
    self.requests_per_sec = 3
    self.max_requests_per_sec = 10
    self.url = '/'.join([EutilsQuery.base_url, self.eutil])
    self.contact = email
    self.tool = tool
    self.apikey = self.check_ncbi_apikey(apikey, apikey_var)
    self.num_threads = 0 if not threads else threads
    self.failed_requests = []
    self.request_pool = EutilsQuery.RequestPool(self.num_threads, self.failed_requests)
    self.request_counter = 0
    EutilsQuery.query_requester = entrezpy.requester.requester.Requester(1/self.requests_per_sec)
    EutilsQuery.query_monitor.register_query(self)

  def inquire(self, parameter, analyzer):
    """Virtual function starting query. Each query requires its own implementation.

    :param dict parameter: E-Utilities parameters
    :param analzyer: query response analyzer
    :type  analzyer: :class:`entrezpy.base.analyzer.EutilsAnalzyer`
    :returns: analyzer
    :rtype: :class:`entrezpy.base.analyzer.EutilsAnalzyer`
    """
    raise NotImplementedError("{} requires inquire() implementation".format(__name__))

  def check_requests(self):
    """Virtual function testing and handling failed requests. These requests
    fail due to HTTP/URL issues and stored
    :attr:`entrezpy.base.query.EutilsQuery.failed_requests`
    """
    raise NotImplementedError("{} requires check_failed_requests() implementation".format(__name__))

  def check_ncbi_apikey(self, apikey=None, env_var=None):
    """Checks and sets NCBI apikey.

    :param str apikey: NCBI apikey
    :param str env_var: enviromental variable storing NCBI apikey
    """
    if 'NCBI_API_KEY' in os.environ:
      self.requests_per_sec = self.max_requests_per_sec
      return os.environ['NCBI_API_KEY']
    if apikey:
      self.requests_per_sec = self.max_requests_per_sec
      return apikey
    if env_var and (env_var in os.environ):
      self.requests_per_sec = self.max_requests_per_sec
      return os.environ[env_var]
    return None

  def prepare_request(self, request):
    """Prepares request for sending to E-Utilities with require quey attributes.

    :param request: entrezpy request instance
    :type  request: :class:`entrezpy.base.request.EutilsRequest`
    :returns: request instance with EUtils parameters
    :rtype: :class:`entrezpy.base.request.EutilsRequest`
    """
    request.id = self.request_counter
    request.query_id = self.id
    request.contact = self.contact
    request.url = self.url
    request.tool = self.tool
    request.apikey = self.apikey
    return request

  def add_request(self, request, analyzer):
    """Adds one request and corresponding analyzer to the request pool.

    :param request: entrezpy request instance
    :type  request: :class:`entrezpy.base.request.EutilsRequest`
    :param analzyer: entrezpy analyzer instance
    :type analyzer: :class:`entrezpy.base.analzyer.EutilsAnalyzer`
    """
    self.request_pool.add_request(self.prepare_request(request), analyzer)
    self.request_counter += 1

  def monitor_start(self, query_parameters):
    """Starts query monitoring

    :param query_parameters: query parameters
    :type query_parameters: :class:`entrezpy.base.parameter.EutilsParameter`
    """
    EutilsQuery.query_monitor.dispatch_observer(self, query_parameters)

  def monitor_stop(self):
    """Stops query monitoring"""
    EutilsQuery.query_monitor.recall_observer(self)

  def monitor_update(self, updated_query_parameters):
    """Updates query monitoring parameters if follow up requests are required.

    :param updated_query_parameters: updated query parameters
    :type  updated_query_parameters: :class:`entrezpy.base.parameter.EutilsParameter`
    """
    EutilsQuery.query_monitor.update_observer(self, updated_query_parameters)

  def hasFailedRequests(self):
    """Reports if at least one request failed."""
    if self.failed_requests:
      return True
    return False

  def dump(self):
    """Dump all attributes"""
    return {'id' : self.id, 'base_url' : EutilsQuery.base_url, 'eutil' : self.eutil,
            'url' : self.url, 'req/sec' : self.requests_per_sec, 'tool' : self.tool,
            'contact' : self.contact, 'apikey' : self.apikey, 'threads' : self.num_threads}
