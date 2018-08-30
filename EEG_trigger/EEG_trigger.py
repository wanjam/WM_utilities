# -*- coding: utf-8 -*-
"""
A custom module to make parallel port triggering more straightforward.
Depends on psychopy.parallel module

**Author** :
    Wanja Mössing, WWU Münster | moessing@wwu.de
**Version**:
    Aug 2018
**copyright** :
  Copyright (C) 2018 Wanja Mössing

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program. If not, see <http://www.gnu.org/licenses/>.
"""

# import dependencies
from psychopy import parallel
from psychopy.core import wait


def OpenTriggerPort(port=0x0378):
    """ Opens connection to triggerport
    **Author** : Wanja Mössing, WWU Münster | moessing@wwu.de \n
    *August 2018*

    Parameters:
    ----------
    port: hexadecimal port number. default is 0x0378
    """
    parallel.setPortAddress(port)
    parallel.setData(0)
    return(parallel)


def SendTrigger(triggervalue=0, duration=0.001, parallel=parallel):
    """Sends a specific trigger to the port
    **Author** : Wanja Mössing, WWU Münster | moessing@wwu.de \n
    *August 2018*

    Parameters:
    ----------
    triggervalue: integer, 0-255
    duration: float, default 0.001 (i.e., 1ms)
    """
    parallel.setData(triggervalue)
    wait(duration)
    parallel.setData(0)
