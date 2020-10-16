# Copyright 2018, 2019 The University of Sydney
# This file is part of entrezpy.
#
#  Entrezpy is free software: you can redistribute it and/or modify it under the
#  terms of the GNU Lesser General Public License as published by the Free
#  Software Foundation, either version 3 of the License, or (at your option) any
#  later version.
#
#  Entrezpy is distributed in the hope that it will be useful, but WITHOUT ANY
#  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
#  A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with entrezpy.  If not, see <https://www.gnu.org/licenses/>.
"""
.. module:: logging
  :synopsis:
    This module is part of entrezpy. It configures logging via Python's :mod:`logging` implements the base class for all
    entrezpy analzyer for NCBI E-Utils responses.

.. moduleauthor:: Jan P Buchmann <jan.buchmann@sydney.edu.au>
"""

import os
import time
import logging

default_config = {
  'disable_existing_loggers': False,
  'version': 1,
  'formatters': {
    'short': { 'format': '%(asctime)s %(levelname)s %(name)s: %(message)s'},
  },
  'handlers': {
    'console': {
      'level': 'INFO',
      'formatter': 'short',
      'class': 'logging.StreamHandler',
    },
    'file': {
      'level': 'DEBUG',
      'formatter': 'short',
      'class': 'logging.FileHandler',
      'filename' : os.path.join(os.getcwd(), 'entrepy-{}.log'.format(time.time())),
      'delay' : True
    },
  },
  'loggers': {
        '': {
            'handlers': ['console'],
            'level': 'ERROR',
        },
    'plugins': {
            'handlers': ['console'],
            'level': 'INFO',
            'propagate': False
        }
    },
}
