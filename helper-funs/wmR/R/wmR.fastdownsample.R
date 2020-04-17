# wmR::fast_downsample downsamples pupil dilation data to a given frequency
#     Copyright (C) 2018  Hedderik van Rijn, Jacolien van Rij, (modifications) Wanja Mössing
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

##' Fast downsampling of eyetracking data. Originally based on pR::downsample
##' However, it's *much faster* and can handle with more sorts of input
##' (see below). Needs a column 'Trial', which can
##' simply be **1** if it should be ignored.
##'
##' new documentation:
##'
##' Downsample pupil dilation data to a given frequency
##'
##' This is a modified version of pR::downsample (see github.com/hedderik/pR).
##' In comparison to the original, this version can process additional information
##' as captured on-line by the eyetracker. For example:
##' - TTL trigger sent to the SR-host-PC
##' - Saccades
##' - Blinks
##' - Fixations
##' - Velocity
##'
##'Please indicate all columns that are not always the same within a trial
##'(i.e., that cannot go into the "by" argument) and that should not be averaged
##' over (i.e., not X, Y, or Dil) in \code{non.average.columns}.
##'  Typically, that's saccade, ttl, blink, and fixation statistics.
##'
##' ----------------------------------
##' Original documentation
##' ----------------------------------
##'
##' Downsamples the data in the pupil dilation \code{data.table} to a given frequency by calculating the \code{\link{median}}
##' values for subsequent bins. This is the simplest type of downsampling possible, but one that - given the slow
##' pupillary response - is appropriate as long as the output frequency is sufficiently high. Furture work might
##' incorporate more refined sampling methods as defined in the \code{signal} package.
##'
##' @param pddt a pupil dilation \code{data.table} of a single participant containing at least the following
##' four columns:
##' \itemize{
##' \item{Dil} containing the dilation samples
##' \item{X} X coordinate of the eye associated with each sample
##' \item{Y} Y coordinate of the eye associated with each sample
##' \item{Time} time stamp in ms associated with each sample
##' \item{Trial} indicating to which trial the current sample belongs
##' }
##' @param by a vector of character names of the columns defining unique trials. As the returned \code{data.table}
##' only contains the columns listed above and the columns specified in this \code{by} argument, typically the
##' \code{by} parameter also contains the names of the columns containing condition and participant information.
##'
##' @param Hz target Hz
##' @param useref boolean (default: FALSE). Can be set TRUE to squeeze the last bit of performance out of it. Only do so if you're absolutely sure you don't mind your original pddt-data.table to be messed with.
##'
##' @return Returns a downsampled copy of the original \code{data.table} with the following columns:
##' \itemize{
##' \item{\code{Dil}} downsampled dilation value
##' \item{\code{X}} downsampled X coordinate
##' \item{\code{Y}} downsampled Y coordinate
##' \item{\code{Time}} downsampled time stamp in ms
##' \item{\code{Trial}} indicating to which trial this downsampled sample belongs
##' \item{\code{...}} all columns listed in the \code{by} argument.
##' }
##'
##' @author Hedderik van Rijn, Jacolien van Rij, (modifications) Wanja Mössing
##' @name fast_downsample
##' @export fast_downsample
##' @import data.table
##' @importFrom stats median
fast_downsample <- function(pddt, by, Hz = 100, useref = FALSE,
                            non.average.columns = c('TTL', 'IthSaccadeThisSubject', 'Blink',
                                                    'Fixation', 'Saccade', 'AverageVelocity', 'PeakVelocity')) {
  if (!useref) {
  pddt.tmp <- copy(pddt) # avoid overwriting global variable
  } else {
    pddt.tmp <- pddt
  }
  ## determine sampling frequency
  sampleTime <- pddt.tmp[, Time[2] - Time[1]]
  binSize <- 1000 / Hz
  if (binSize %% sampleTime != 0) {
    warning("Sample frequency of data is not a multiple of the target frequency specified in the by argument")
  }

  ## Downsample ----
  pddt.tmp[, DS := Time %/% binSize]
  setorder(pddt.tmp, Trial, DS, Time)
  # add 'DS' to the list of values we want to reduce the data.table by
  allF <- c(by, "DS")

  ## Do our downsampling per group of cells defined by the combination of the by
  ##  argument *and* the DS variable that we just defined.

  ## This is the part that differs from pR::downsample. This version can deal
  ## with all the other information captured online by the eyetracker.
  if (!any(colnames(pddt.tmp) == 'Trial')) {
    stop(paste0('This fast version requires a column called \'Trial\'.',
                '\nIf you don\'t have trials, simply run pddt[,Trial:=1].',
                '\nIf you do have trials, run pddt[,Trial=YourTrialColumnName]'))
  }
  non.average.columns <- c(non.average.columns, 'DS', 'Trial')
  subsamples <- pddt.tmp[, .SD, .SDcols = non.average.columns]
  setorder(subsamples, Trial, DS)
  Nsubsamples <- subsamples[,.SD[.N],by = .(Trial, DS)]
  setorder(Nsubsamples, Trial, DS)
  downsamplecols <- c('Dil', 'X', 'Y')
  pddt.tmp <- pddt.tmp[, .(Dil = median(Dil), X = median(X), Y = median(Y)), by = allF]
  pddt.tmp <- merge(pddt.tmp, Nsubsamples, by = c('Trial','DS'))

  ## Recreate a Time column with time in ms, and remove the column on which the split the data.
  pddt.tmp[, Time := DS * binSize]
  pddt.tmp[, DS := NULL]
  return(pddt.tmp)
}
