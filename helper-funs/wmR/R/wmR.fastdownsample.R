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

##' @title fast_downsample
##' @description Fast downsampling of eyetracking data. Originally based on pR::downsample
##' However, it's *much faster* and can handle with more sorts of input
##' (see below). Downsampling is done via computing bin-wise medians.
##' This is a very simple solution, but one that is appropriate, given the slow
##' pupil response -- as long as the output frequency is sufficiently high.
##'
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
##' Please indicate all columns that are not always the same within a trial
##' (i.e., that cannot go into the "by" argument) and that should not be averaged
##' over (i.e., not X, Y, or Dil) in \code{non.average.columns}.
##' Typically, that's saccade, ttl, blink, and fixation statistics.
##'
##' @param pddt a pupil dilation \code{data.table} of a single participant containing at least the following
##' four columns:
##' \itemize{
##' \item{Dil} containing the dilation samples
##' \item{X} X coordinate of the eye associated with each sample
##' \item{Y} Y coordinate of the eye associated with each sample
##' \item{Time} time stamp in ms associated with each sample
##' \item{Trial} indicating to which trial the current sample belongs. If your data has no trials, create a column \code{Trial} and set all rows to \code{1}
##' }
##' @param by a vector of character names of the columns defining unique trials.
##' This should contain all columns that (i) have just one unique value per trial
##' (e.g., stimulus_image, response_correct, RT, etc.), and that (ii) should be
##' included in the final dataset. Use \code{non.average.colums} to indicate
##' other factors.
##'
##' @param non.average.columns a vector of column names. This is especially useful
##' to integrate blink/saccade/fixation/ttl statistics as included in Eyelink's
##' EDF files. For each column, the most frequent value is returned to the bin in
##' the resulting data.table. For columns coding blinks/saccades/fixations as
##' logicals, make sure they are NA whenever not happening.
##'
##' @param non.average.columns.na.rm same as \code{non.average.columns}, with the
##' difference that NAs are ignored. This is especially useful for TTL triggers.
##' The TTL column is likely mostly NA and has just very few TTLs. You don't want
##' to lose that information, but instead you want to have that trigger assigned
##' to the bin.
##'
##'
##' @param Hz target Hz
##' @param useref boolean (default: FALSE). Defines whether internally a
##' \code{copy()} of data.table is used, or the original data.table by reference.
##' Can be set TRUE to squeeze the last bit of performance out of it.
##' Only do so if you're absolutely sure you don't mind your original pddt-data.table to be messed with.
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
##' @examples
##' \dontrun{
##' foo = colnames(samples)
##' non.average.columns = foo[foo %like% '(^(sacc|fix|blink|event))']
##' BY = foo[!(foo %in% c('Dil', 'X', 'Y', 'Flags', 'DilDiff', 'TTL',
##'                      'RelTime', 'Baseline','Time','ID',
##'                      non.average.columns))]
##'
##' samples <- fast_downsample(samples, by = BY, Hz = 100, useref = TRUE)
##' }
##' @author (2020) Wanja Mössing; basis: Jacolien van Rij, Hedderik van Rijn
##' @name fast_downsample
##' @export fast_downsample
##' @import data.table
##' @importFrom stats median
##' @importFrom collapse fmode
fast_downsample <- function(pddt, by, Hz = 100, useref = FALSE,
                            non.average.columns = c('IthSaccadeThisSubject',
                                                    'Blink', 'Fixation',
                                                    'Saccade', 'avel', 'pvel'),
                            non.average.columns.na.rm = 'TTL') {
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
  non.average.columns.na.rm <- c(non.average.columns.na.rm, 'DS', 'Trial')
  subsamples <- pddt.tmp[, .SD, .SDcols = non.average.columns]
  subsamples.na.rm <- pddt.tmp[, .SD, .SDcols = non.average.columns.na.rm]
  setorder(subsamples, Trial, DS)
  setorder(subsamples.na.rm, Trial, DS)
  # for each bin, select the most frequent value, including NAs
  # collapse::fmode slows the whole function down considerably - there should be
  # a faster version, but it's not data.table::fsort
  Nsubsamples <- subsamples[, lapply(.SD, collapse::fmode, na.rm = F), by = .(Trial, DS)]
  Nsubsamples.na.rm <- subsamples.na.rm[, lapply(.SD, collapse::fmode, na.rm = T), by = .(Trial, DS)]
  Nsubsamples <- merge(Nsubsamples, Nsubsamples.na.rm, by = c('Trial', 'DS'))
  setorder(Nsubsamples, Trial, DS)
  dscols <- c('Dil', 'X', 'Y')
  pddt.tmp <- pddt.tmp[, lapply(.SD, median), by = allF, .SDcols = dscols]
  pddt.tmp <- merge(pddt.tmp, Nsubsamples, by = c('Trial','DS'))

  ## Recreate a Time column with time in ms, and remove the column on which the split the data.
  pddt.tmp[, Time := DS * binSize]
  pddt.tmp[, DS := NULL]
  return(pddt.tmp)
}
