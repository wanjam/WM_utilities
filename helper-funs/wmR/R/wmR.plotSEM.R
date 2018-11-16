# wmR::plot.SEM takes a vector and provides what you need for SEM errorbars
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

##' Calculate standard error of the mean.
##'
##' \code{sem} returns the standard error of the mean
##' \code{plotSEM} is useful for ggplot. It returns a vector with:
##' mean-SEM, mean, mean+SEM; so very handy for errorbars.
##' \code{plotSEMminmax} additionally returns minimum and maximum for more elaborate errorbars.
##'
##' @param x a \code{numeric vector}
##' @param na.rm remove NaNs? Default is FALSE.
##' @return a numeric vector with values for errorbars
##'
##' @examples
##' x <- rnorm(1000, mean = 5, sd = 90)
##'
##' sem(x)
##' plotSEM(x)
##' plotSEMminmax(x)
##'
##' # example usage in ggplot
##' require(ggplot2)
##' dat <- data.frame(measure = x, condition = c('A', 'B'))
##'
##' ggplot(data = dat, aes(x = condition, y = measure)) +
##'        stat_summary(fun.data = plotSEMminmax,
##'                     geom = "boxplot") +
##'        ggtitle("Min, Mean-1SEM, Mean, Mean+1SEM, Max")
##'
##' ggplot(data = dat, aes(x = condition, y = measure)) +
##'        stat_summary(fun.data = plotSEM,
##'                     geom = "pointrange") +
##'        ggtitle("Min, Mean-1SEM, Mean, Mean+1SEM, Max")
##'
##' @author Wanja Mössing
##' @name sem
##' @export sem
##'

sem <- function(x, na.rm = FALSE) {
  if (na.rm) {x <- na.omit(x)}
  out <- sd(x)/sqrt(length(x))
  return(out)
}

##' @rdname sem
##' @name plotSEMminmax
##' @export plotSEMminmax
plotSEMminmax <- function(x, na.rm = FALSE) {
  M <- mean(x, na.rm = na.rm)
  SEM <- sem(x, na.rm = na.rm)
  out <- c(min(x, na.rm = na.rm), M - SEM, M, M + SEM, max(x, na.rm = na.rm))
  # names are needed for stat_summary(geom = 'boxplot')
  names(out) <- c("ymin", "lower", "middle", "upper", "ymax")
  return(out)
}

##' @rdname sem
##' @name plotSEM
##' @export plotSEM
plotSEM <- function(x, na.rm = FALSE) {
  M <- mean(x, na.rm = na.rm)
  SEM <- sem(x, na.rm = na.rm)
  out <- c(M - SEM, M, M + SEM)
  # names are needed for stat_summary(geom = 'pointrange')
  names(out) <- c("ymin", "y", "ymax")
  return(out)
}
