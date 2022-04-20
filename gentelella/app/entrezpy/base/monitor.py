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

.. module:: entrezpy.base.monitor
  :synopsis: Exports class QueryMonitor implementing monitoring of entrezpy
    queries and requsts

.. moduleauthor:: Jan P Buchmann <jan.buchmann@sydney.edu.au>
"""


import sys
import threading
import logging
import time


logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)
logger.addHandler(logging.StreamHandler())


class QueryMonitor:
  """The QueryMonitor class implements the monitoring of entrezpy requests in
  entrezpy queries. It controls individual Observers which are linked to one
  entrezpy query.
  """

  class Observer(threading.Thread):
    """The Observer class implements the observation of one entrezpy query. It
    uses Python's multithreading deamon when using multithreading."""
    def __init__(self):
      super().__init__(daemon=True)
      self.expected_requests = 0
      self.processed_requests = 0
      self.doObserve = True
      self.requests = []
      self.duration = None

    def recall(self):
      """Stops an observation for a query"""
      self.doObserve = False
      print('\n', file=sys.stderr)
      for i in self.requests:
        print(i.get_observation(), file=sys.stderr)
      self.join()

    def dispatch(self, parameter):
      """Starts observation

      :param parameter: query parameter
      :type  parameter: 'class':`entrezpy.base.EutilsParameter`
      """
      self.expected_requests = parameter.expected_requests
      if not self.is_alive():
        self.start()

    def observe(self, request):
      """Adds one query request for observation"""
      self.requests.append(request)

    def run(self):
      """Observes requests from an entrezpy query"""
      while self.doObserve:
        for i in self.requests:
          print("{0}/{1}\t{2}".format(self.processed_requests,
                                      self.expected_requests,
                                      i.get_observation()), end='\r', file=sys.stderr)
        time.sleep(1)

  def __init__(self):
    """:ivar dict observers: observer storage for queries"""
    self.observers = {}
    #self.locks = {}

  def register_query(self, query):
    """Adds a query for observation

    :param query: entrezpy query
    :type  query: :class:`entrezpy.base.query.EutilsQuery`
    """
    #self.locks[query.id] = threading.Lock()
    self.observers[query.id] = self.Observer()

  def get_observer(self, query_id):
    """Returns an observer for a specific query.

    :param str query_id: entrezpy query id
    :rtype: :class:`base.mnonitor.QueryMonitor.Observer`
    """
    return self.observers.get(query_id, None)

  def dispatch_observer(self, query, parameter):
    """Start the observer for an entrezpy query

    :param query: entrezpy query
    :type  query: :class:`entrezpy.base.query.EutilsQuery`
    :param parameter: query parameter
    :type  parameter: 'class':`entrezpy.base.EutilsParameter`
    """
    observer = self.observers.get(query.id, None)
    if observer:
      observer.dispatch(parameter)

  def recall_observer(self, query):
    """Stops the observer for an entrezpy query

    :param query: entrezpy query
    :type  query: :class:`entrezpy.base.query.EutilsQuery`
    """
    observer = self.observers.get(query.id, None)
    if observer:
      observer.recall()

  def update_observer(self, query, parameter):
    """ Function updating the settings for a thread. Honestly, I have no idea if
    the lock is really required. It works without locks, just updating the
    parameter.

    :param query: entrezpy query
    :type  query: :class:`entrezpy.base.query.EutilsQuery`
    :param parameter: query parameter
    :type  parameter: 'class':`entrezpy.base.EutilsParameter`
    """
    self.observers[query.id].expected_requests = parameter.expected_requests
