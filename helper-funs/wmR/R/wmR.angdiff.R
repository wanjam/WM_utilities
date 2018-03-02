# wmR::wmR.angdiff computes the angular difference between two degrees
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

#' Take two angles in degree and calculate their difference
#'
#' \code{wmR.angdiff} returns the difference between deg1 and deg2
#'
#' @param deg1 Numeric in range 0:360
#' @param deg2 Numeric in range 0:360
#'
#' @return a single floating point number representing the difference between the two angles.
#'   Can take on negative values, as it show the orientation of deg1 IN RELATION to deg2.
#'   So a result of -1 means, that deg1 is 1 less than deg2.
#'
#' @examples
#' #deg1 higher
#' diff = wmR.angdiff(5, 355)
#' #deg1 lower
#' diff = wmR.angdiff(5, 10)
#'
#' \dontrun{
#' diff = wmR.angdiff(5000, Inf)
#' }
#'
#' @author Wanja Mössing
#' @name wmR.angdiff
#' @export wmR.angdiff
#'
#' @importFrom CircStats deg rad
wmR.angdiff <- function(deg1, deg2) {
  if (deg1 > 360 || deg2 > 360 || deg1 < 0 || deg2 < 0) {
    warning('wmR.angdiff: deg1 and/or deg2 are >360 and/or <0; using deg %% 360 instead')
  }

  #This avoids confusion, where wmR.angdiff(0,360) is non-zero.
  if (deg1 == 0) {deg1 <- 360}
  if (deg2 == 0) {deg2 <- 360}

  a = deg(atan2(sin(rad(deg1 - deg2)), cos(rad(deg1 - deg2))))
  return(a)
}
