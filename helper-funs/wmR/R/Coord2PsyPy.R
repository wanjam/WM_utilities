# wmR:Coord2PsyPy converts pixels to psychopy coordinates
#     Copyright (C) 2018 Wanja Mössing
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

#' @title Coord2PsyPy
#' @description  \code{Coord2PsyPy} returns c(x,y) in psychopy format
#' Many devices assume that the top-left corner of an image (or screen) has the
#' coordinates \code{c(x=0, y=0)} and \code{c(x=max, y=max)} in the bottom right
#' corner. Psychopy assumes that \code{c(x=0, y=0)} is in the centre. This
#' function takes 'standard' coordinates and transforms them to Psychopy
#' coordinates.
#'
#' @param x positive integer x-coordinate
#' @param y positive integer y-coordinate
#' @param xmax maximum x pixel coordinate in original picture
#' @param ymax maximum y pixel coordinate in original picture
#'
#' @return a vector c(x,y) with psychopy coordinates
#'
#' @examples
#' pp.pix = Coord2PsyPy(100, 200, 1024, 768)
#'
#' @author Wanja Mössing
#' @name Coord2PsyPy
#' @export Coord2PsyPy
Coord2PsyPy <- function(x, y, xmax = 1024, ymax = 768) {
  if (x < 0 || x > xmax || y < 0 || y > ymax) {
    stop('Coord2PsyPy: x or y values out of range!')
  }
  xhalf = xmax/2
  yhalf = ymax/2
  if (x >= xhalf) {
    xout = x - xhalf
  } else {
    xout = (xhalf - x) * -1
  }
  if (y >= yhalf) {
    yout = (y - yhalf) * -1
  } else {
    yout = yhalf - y
  }
  return(c(xout, yout))
}
