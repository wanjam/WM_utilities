# wmR::NaNs creates a vector of NaNs
#     Copyright (C) 2019 Wanja Mössing
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

##' Generates a vector of NaNs with variable length
##'
##' @param n an \code{integer}. Length of vector.
##' @return Returns a 1-row \code{vector} with N NaNs
##'
##' @examples
##' mynans <- NaNs(100)
##'
##' library(data.table)
##' DT <- data.table(A = NaNs(50))
##'
##' @author Wanja Mössing
##' @name NaNs
##' @export NaNs
##'
NaNs <- function(n){
  return(rep(NaN, n))
}

##' Generates a vector of NAs with variable length
##'
##' @param n an \code{integer}. Length of vector.
##' @return Returns a 1-row \code{vector} with N NaNs
##'
##' @examples
##' mynas <- NAs(100)
##'
##' library(data.table)
##' DT <- data.table(A = NAs(50))
##'
##' @author Wanja Mössing
##' @name NAs
##' @export NAs
##'
NAs <- function(n){
  return(rep(NA, n))
}
