# wmR::detectblinks detects blinks in a pupil dilation data.table
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

##' Detect blinks in (Eyelink 1000) pupil dilation data
##'
##' @param pddt a pupil dilation \code{data.table} of a single participant
##' containing at least the following columns:
##' \itemize{
##' \item{Dil} containing the dilation samples
##' \item{Time} time stamp in ms associated with each sample
##' \item{Trial} indicating to which trial the current sample belongs
##' }
##' An optional column coding Blinks in 0 or 1 (as provided by the edfR package)
##' can be used as basis for blink detection and/or comparison of the two
##' methods.
##'
##' @param minDilation Dilations lower than this are considered a 'Blink'
##' @param maxDeltaDilation By how much are samples allowed to differ from the
##' following sample? Any sample exceeding this threshold is considered a blink.
##' @param TrialCol \code{char}, the name of the column coding trials (default:
##' \code{'Trial'})
##' @param SR_Blink_Col \code{char}, the name of the column containing the
##' online-detected blinks. Jason Hubbard's \code{edfR} provides a column
##' 'Blink', which is 1 for blink samples and 0 for non-blink samples.
##' @param use_SR \code{logical}, ignore minDilation and maxDeltaDilation and
##' base blink detection solely on SR-Research's online detection (default:
##' \code{FALSE})
##' @param verbose \code{logical}, if \code{TRUE} (default), will print some
##' statistics comparing on- and offline detection, if SR_Blink_Col is
##' available.
##' @param expandblinks \code{integer}, just before and after a blink, the pupil
##' dilation is often affected. expand blinks by N ms. Default is 0.
##'
##' @return Returns the same data.table with column \code{Dil} set to \code{NA}
##' for blink samples.
##'
##' @author Wanja Mössing
##' @name blink.detect
##' @export blink.detect
##' @import data.table
blink.detect <- function(pddt, minDilation = 500, maxDeltaDilation = 5,
                         TrialCol = 'Trial', SR_Blink_Col = NA,
                         use_SR = FALSE, verbose = TRUE, expandblinks = 0) {
  if (!is.na(SR_Blink_Col) && verbose) {
    online_blinks <- pddt[get(SR_Blink_Col) == 1, .N]
    offline_blinks <- pddt[Dil < minDilation, .N]
    combi_blinks <- pddt[(get(SR_Blink_Col) == 1) & (Dil < minDilation), .N]
    of_off_in_both <- offline_blinks / combi_blinks * 100
    of_on_in_both <- online_blinks / combi_blinks * 100
    cat(sprintf(paste('\nProportion of blink-samples detected offline (without',
                      'maxDelta) compared to blink samples detected online:',
                      '%.2f (should be ~1)\n%.2f%% of offline blinks have',
                      'been detected online\n%.2f%% of online blinks have',
                      'not been detected offline\n'),
                offline_blinks/online_blinks, of_off_in_both,
                of_on_in_both - of_off_in_both))
  }

  if (use_SR) {
    if (is.na(SR_Blink_Col)) {stop('Please indicate column name for Blinks!')}
    pddt[Blink == 1, Dil := NA]
  } else {
    pddt[Dil < minDilation, Dil := NA]
    pddt[, DilP := data.table::shift(Dil, -1), by = get(TrialCol)]
    pddt[, DilDiff := abs(DilP - Dil)]
    pddt[, DilP := NULL]
    pddt[DilDiff > maxDeltaDilation, Dil := NA]
  }

  if (expandblinks > 0) {
    pddt[, ':='(FOO = data.table::shift(Dil, -expandblinks),
                BAR = data.table::shift(Dil, expandblinks))]
    pddt[is.na(FOO) | is.na(BAR), Dil := NA]
    pddt[, FOO := NULL]
    pddt[, BAR := NULL]
  }
  cat(sprintf('Proportion of data that is blinks: %.2f\n', pddt[,sum(is.na(Dil))/.N]))
  return(pddt)
}


##' @title Interpolate blinks in Eyetracking data measured with Eyelink 1000+
##' @description interpolates blinks in pupil dilation data, as detected by
##' \code{blink.detect}. Currently supports linear and spline interpolation.
##' Linear interpolation is based on \code{pR::interpolateblinks} by Hedderik
##' van Rijn (see \code{github.com/hedderik/pR}). The cubic spline interpolation
##' implements the interpolation part of Mathot, 2013. Note that this function
##' does not run blink detection as described in that paper.
##' @param pddt A pupil dilation data.table, containing at least the columns:
##' \code{Dil} and \code{Trial} for linear interpolation or \code{Dil} for
##' spline interpolation.
##' @param type character. Type of interpolation. Can be 'spline' (default) or
##' 'linear'
##' @return Returns the same data.table with column \code{Dil} interpolated for
##' blink periods and an additional column \code{IthBlink} counting blinks per
##' subject (assuming you're running this on single subjects).
##'
##' @author Wanja Mössing
##' @name blink.interolate
##' @export blink.interpolate
##' @import data.table
##' @import stats
blink.interpolate <- function (pddt, type = "spline") {
  setorder(pddt, ID, Trial, RelTime)
  if (type == "linear") {
    .dil.na.approx <- function(Dil) {
      if (all(is.na(Dil))) {
        return(Dil)
      }
      return(na.approx(Dil, na.rm = FALSE))
    }
    pddt[, `:=`(Dil, .dil.na.approx(Dil)), by = Trial]
  }
  if (type == "spline") {
    # algo based on Mathot, 2013 (A simple way to reconstruct pupil size during eye blinks)
    # define four timepoints
    pddt <- .blink.onset_offset_marker(pddt)
    pddt[, ':='(UrDil = Dil, idx = 1:.N)]
    OnOff <- pddt[BlinkOnOff %in% c(-1, 1), ]
    foundnewblink = FALSE
    BlinkCount = 1;
    for (i in 1:OnOff[,.N]){
      if (OnOff[i, BlinkOnOff == 1]) {
        y2 = OnOff[i, idx]
        if (foundnewblink) {
          stop('Blink onset found prior to blink offset?')
        }
        foundnewblink = TRUE
      }
      if (OnOff[i, BlinkOnOff == -1] && foundnewblink) {
        y3 = OnOff[i, idx]
        y1 = y2-y3+y2;
        y4 = y3-y2+y3;
        foundnewblink = FALSE

        # run spline interpolation
        interpdat <- pddt[, spline(c(y1,y2,y3,y4), Dil[c(y1,y2,y3,y4)], xout = y2:y3)]
        pddt[y2:y3, ':='(Dil = interpdat$y, IthBlink = BlinkCount)]
        interpdat <- NULL
        BlinkCount = BlinkCount + 1
      }
    }
    set(pddt, j = c('UrDil', 'idx', 'BlinkOnOff'), value = NULL)
  }
  return(pddt)
}

.blink.onset_offset_marker <- function(pddt) {
  pddt[, BlinkOnOff := diff(c(FALSE, is.na(Dil)))]
  return(pddt)
}
