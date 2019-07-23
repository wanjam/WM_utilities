# wmR::plot.SEM takes a vector and provides what you need for SEM errorbars
#     Copyright (C) 2018-2019 Wanja Mössing
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

##' Calculate default between group standard error of the mean.
##' @description \code{sem} returns the standard error of the mean
##' \deqn{\sigma_\bar{x} = \frac{\sigma}{\sqrt{n}}}
##' \code{plotSEM} is useful for ggplot. It returns a vector with:
##' mean-SEM, mean, mean+SEM; so very handy for errorbars.
##' \code{plotSEMminmax} additionally returns minimum and maximum for more elaborate errorbars.
##' For within group comparisons, use Cosineau-Morey CIs/SEs (e.g., \code{Rmisc::summarySEwithin}).
##' Use \code{stat_CosineauMoreyCI} as a layer for ggplot.
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
##' @seealso Rmisc::summarySEwithin, plotSEM, stat_CosineauMoreyCI, plotSEMminmax

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



##' Add layer with Cosineau-Morey 95\% within group CIs/ SE to ggplot
##'
##' Cosineau-Morey CIs for within subject factors. For more information, see
##' Cosineau (2005) and Morey (2008)
##'\\
##' \code{stat_CosineauMoreyCI} adds confidence intervals\\
##' \code{stat_CosineauMoreySE} adds standard errors
##'
##' see \code{Rmisc::summarySEwithin} for calculations
##'
##'
##' @param conf.interval default is 0.95
##' @param na.rm remove NaNs? Default is TRUE
##' @param geom which geom to use? works only for geoms expecting ymin and ymax.
##' Default is 'pointrange', 'errorbar' works fine as well.
##' @param ... further arguments passed to geom
##' @return a ggplot layer with errorbars
##'
##' Standard layer arguments you probably never need to change (descriptions copied from stat_summary in ggplot2 package)
##' @param mapping Set of aesthetic mappings created by aes() or aes_(). If specified and inherit.aes = TRUE (the default), it is combined with the default mapping at the top level of the plot. You must supply mapping if there is no plot mapping.
##' @param data The data to be displayed in this layer. There are three options:
##' If NULL, the default, the data is inherited from the plot data as specified in the call to ggplot().
##' A data.frame, or other object, will override the plot data. All objects will be fortified to produce a data frame. See fortify() for which variables will be created.
##'
##' A function will be called with a single argument, the plot data. The return value must be a data.frame, and will be used as the layer data.
##' @param position Position adjustment, either as a string, or the result of a call to a position adjustment function.
##' @param show.legend logical. Should this layer be included in the legends? NA, the default, includes if any aesthetics are mapped. FALSE never includes, and TRUE always includes. It can also be a named logical vector to finely select the aesthetics to display.
##' @param inherit.aes If FALSE, overrides the default aesthetics, rather than combining with them. This is most useful for helper functions that define both data and aesthetics and shouldn't inherit behaviour from the default plot specification, e.g. borders().
##'
##' @examples
##' # example usage in ggplot
##' require(ggplot2)
##' dat <- data.frame(datasets::UCBAdmissions)
##' ggplot(data = dat, aes(x = Gender, y = Freq, idvar = Dept)) +
##'        stat_CosineauMoreyCI()
##'
##' # use errorbar instead
##' ggplot(data = dat, aes(x = Gender, y = Freq, idvar = Dept)) +
##'        stat_CosineauMoreyCI(geom='errorbar')
##'
##' # use SE instead of CI
##' ggplot(data = dat, aes(x = Gender, y = Freq, idvar = Dept)) +
##'        stat_CosineauMoreySE(geom='errorbar')
##'
##' # show difference
##' ggplot(data = dat, aes(x = Gender, y = Freq, idvar = Dept)) +
##'        stat_CosineauMoreyCI(alpha=.5, color='red', lwd=3) +
##'        stat_CosineauMoreySE(alpha=.5, color='blue', lwd=3)
##'
##' # color by group
##' ggplot(data = dat, aes(x = Gender, y = Freq, idvar = Dept, color = Gender,
##'                        group = Gender)) +
##'        stat_CosineauMoreyCI() +
##'        ggtitle('95% Cosineau-Morey within Subject CIs')
##'
##' @author Wanja Mössing
##' @name stat_CosineauMoreyCI
##' @export stat_CosineauMoreyCI
##' @seealso Rmisc::summarySEwithin, plotSEM, stat_CosineauMoreyCI, plotSEMminmax
##' @import ggplot2
##' @import data.table
##' @import Rmisc
stat_CosineauMoreyCI <- function(mapping = NULL, data = NULL, geom = "pointrange",
                                 position = "identity", show.legend = NA,
                                 inherit.aes = TRUE, na.rm = TRUE,
                                 conf.interval = .95, ...) {
  layer(
    stat = .CosiMoreCIs, data = data, mapping = mapping, geom = geom,
    position = position, show.legend = show.legend, inherit.aes = inherit.aes,
    params = list(na.rm = na.rm, conf.interval = conf.interval,...)
  )
}

##' @rdname stat_CosineauMoreyCI
##' @name stat_CosineauMoreySE
##' @export stat_CosineauMoreySE
stat_CosineauMoreySE <- function(mapping = NULL, data = NULL, geom = "pointrange",
                                 position = "identity", show.legend = NA,
                                 inherit.aes = TRUE, na.rm = TRUE,
                                 conf.interval = .95, ...) {
  layer(
    stat = .CosiMoreSEs, data = data, mapping = mapping, geom = geom,
    position = position, show.legend = show.legend, inherit.aes = inherit.aes,
    params = list(na.rm = na.rm, conf.interval = conf.interval,...)
  )
}

##' @rdname stat_CosineauMoreyCI
##' @name .CosiMoreCIs
.CosiMoreCIs <- ggproto("CosiMoreCIs", Stat,
                       extra_params = c('na.rm', 'conf.interval'),
                       setup_params = function(...){
                         elli = list(...)
                         return(elli[[2]])
                       },
                       setup_data = function(data, scales) {
                         res = summarySEwithin(data, measurevar = 'y',
                                               withinvars = 'x',
                                               idvar = 'idvar',
                                               conf.interval = scales$conf.interval,
                                               na.rm = scales$na.rm)
                         data = data.table(data)
                         res = data.table(res)
                         res = res[, x := as.integer(x)]
                         res = merge(data, res, by.x = 'x', by.y = 'x', no.dups = T)
                         res = res[, y.x := NULL][, y := y.y][, y.y := NULL]
                         res = res[, ':='(ymin = y - ci, ymax = y + ci)]
                         return(res)
                       },
                       compute_group = function(data, scales) {
                         data
                       },

                       required_aes = c("x", 'y', 'idvar')
)

##' @rdname stat_CosineauMoreyCI
##' @name .CosiMoreSEs
.CosiMoreSEs <- ggproto("CosiMoreSEs", Stat,
                       extra_params = c('na.rm', 'conf.interval'),
                       setup_params = function(...){
                         elli = list(...)
                         return(elli[[2]])
                       },
                       setup_data = function(data, scales) {
                         res = summarySEwithin(data, measurevar = 'y',
                                               withinvars = 'x',
                                               idvar = 'idvar',
                                               conf.interval = scales$conf.interval,
                                               na.rm = scales$na.rm)
                         data = data.table(data)
                         res = data.table(res)
                         res = res[, x := as.integer(x)]
                         res = merge(data, res, by.x = 'x', by.y = 'x', no.dups = T)
                         res = res[, y.x := NULL][, y := y.y][, y.y := NULL]
                         res = res[, ':='(ymin = y - se, ymax = y + se)]
                         return(res)
                       },
                       compute_group = function(data, scales) {
                         data
                       },

                       required_aes = c("x", 'y', 'idvar')
)
