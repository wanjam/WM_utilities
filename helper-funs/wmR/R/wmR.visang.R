# wmR::visang, set of functions to tranform between degree and pixels
#     Copyright (C) 2020 Wanja Mössing
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

##' @title pix2deg
##' @description converts pixels to degree, defaults are set to the parameters in the buschlab.
##'
##' @param n_pix how many pixels?
##' @param screen_width width of the screen in cm
##' @param distance viewing distance in cm
##' @param res_x horizontal screen resolution in pixels
##' @return n_pix in degree visual angle
##' @examples pix2deg(1)
##'
##' @author Wanja Mössing
##' @name pix2deg
##' @seealso deg2pix wmR.angdiff
##' @export pix2deg
pix2deg <- function(n_pix, screen_width = 52.2, distance = 86, res_x = 1920){
  phi <- atan2(1, distance) * 180 / pi
  deg <- (phi/ (res_x / screen_width) ) * n_pix
  return(deg)
}

##' @title deg2pix
##' @description converts degree to pixels, defaults are set to the parameters in the buschlab.
##'
##' @param n_deg how many degree?
##' @param screen_width width of the screen in cm
##' @param distance viewing distance in cm
##' @param res_x horizontal screen resolution in pixels
##' @return n_deg in pixels
##' @examples deg2pix(1)
##'
##' @author Wanja Mössing
##' @name deg2pix
##' @seealso pix2deg wmR.angdiff
##' @export deg2pix
deg2pix <- function(n_deg, screen_width = 52.2, distance = 86, res_x = 1920){
  phi <- atan2(1, distance) * 180 / pi
  pix <- n_deg / (phi / (res_x / screen_width))
  return(pix)
}
