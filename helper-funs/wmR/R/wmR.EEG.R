# wmR::EEG, set of functions for EEG processing/plotting
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

##' @title TF_ggplot
##' @description creates a time-frequency plot. Optionally with a highlighted
##' area and/or contours. Can deal with logarithmic spacing of frequency axis.
##' Note that this function internally smoothes both axis because TF data from
##' EEGlab usuallyhave very small numerical imprecisions and are thus not 100%
##' linear, which irritates ggplot. By default, values are interpolated to
##' create a smooth visual experience. The plot imitates Matlab's 'jet' colors.
##'
##' @param TF a \code{data.table} in long format with columns for at least the
##' following: Frequencies, Time, power. Must not be "longer" than this; i.e.,
##' this function cannot handle more than one value per Frequency*Time
##' combination. So make sure to average over channels before calling this
##' function.
##' @param zlim limits of the colorscale; length 2 numerical vector; e.g., \code{c(-2, 2)}
##' @param do_interpolate boolean: Smooth plot via interpolation? (Default: TRUE)
##' @param contours boolean: Display contour lines on top? (Default: FALSE)
##' @param Timecol name of the column in TF coding time (default: 'Time')
##' @param Freqcol name of the column in TF coding frequency (default: 'Hz')
##' @param Zcol name of the column in TF containing data (default: 'pow')
##' @param Time_unit unit of the time axis, used for label (default: 'ms')
##' @param Freq_unit unit of the frequency axis, used for label (default: 'Hz')
##' @param Z_unit unit of the z-axis axis, used for label (default: 'dB')
##' @param highlight length 4 numeric vector defining the boundaries of the
##' (optional) rectangle highlighting an area. Default \code{NA} does not show
##' anything. Otherwise use: \code{c(ymin, ymax, xmin, xmax)}
##' @param x_breaks numerical vector with desired breaks on x-axis. Will
##' approximate and round internally.
##' @param y_breaks numerical vector with desired breaks on x-axis. Will
##' approximate and round internally.
##' @param precise_time Due to the smoothing process, there may be rare
##' imprecisions on the time axis. For instance, the smoothed axis might display
##'  "1000ms", whereas this datum is actually "1001.2ms". If you set this
##'  parameter to TRUE, you'll see the true time axis (default: FALSE).
##' @param x_labs only if x_breaks is given and precise_time is FALSE. Define
##' a string vector with labels corresponding to x_breaks.
##' @return a \code{ggplot} object
##' @examples
##' library(data.table)
##' TF <- data.table(Time = rep(seq(-500, 3000, 10), 30))
##' TF[, Hz := 1:30, by = Time][, pow := 0]
##' TF[Time %between% c(2000, 2500) & Hz %between% c(7, 14), pow := 2]
##' TF_ggplot(TF, c(-2,2), highlight = c(7, 14, 2000, 2500))
##'
##' @author Wanja Mössing
##' @name TF_ggplot
##' @seealso ggplot, geom_raster
##' @import data.table ggplot2 colorRamps scales ggthemes
##' @export TF_ggplot
##' @importFrom data.table data.table
TF_ggplot <- function(TF, zlim, do_interpolate = T, contours = F,
                      Timecol = 'Time', Freqcol = 'Hz', Zcol = 'pow',
                      Time_unit = 'ms', Freq_unit = 'Hz', Z_unit = 'dB',
                      highlight = NA, x_breaks = NA, y_breaks = NA,
                      precise_time = FALSE, x_labs = NA) {

  # usually, there are some imprecisions, so smooth out the y and x axes
  TF[, smooth_Time := seq(min(get(Timecol)), max(get(Timecol)), length.out = .N),
     by = get(Freqcol)]
  TF[, smooth_Hz := 1:.N, by = smooth_Time]

  # create a function to look up labels that are true values, not smoothed
  TimeTable <- TF[, .(Time = round(mean(get(Timecol)))), by = .(smooth_Time)]
  FreqTable <- TF[, .(Hz = mean(get(Freqcol))), by = .(smooth_Hz)]
  setattr(TimeTable, 'sorted', 'smooth_Time')
  setattr(FreqTable, 'sorted', 'smooth_Hz')


  true_x_labels <- function(i) {
    setkey(TimeTable, smooth_Time)
    as.character(round(
      sapply(i, function(x) TimeTable[J(x), roll = 'nearest'][, Time])
    ))
  }
  true_y_labels <- function(i) {
    setkey(FreqTable, smooth_Hz)
    as.character(round(
      sapply(i, function(x) FreqTable[J(x), roll = 'nearest'][, Hz])
    ), 1)
  }

  # use a matlab-like color palette
  matlab.jet <- colorRamps::matlab.like(7)

  plt <- ggplot(TF) +
    aes(x = smooth_Time, y = smooth_Hz, z = get(Zcol), fill = get(Zcol)) +
    geom_raster(interpolate = do_interpolate) +
    scale_fill_gradientn(colors = matlab.jet, limits = zlim,
                         oob = scales::squish, name = Z_unit) +
    ggthemes::theme_tufte() +
    xlab(paste0('Time [', Time_unit, ']')) +
    ylab(Freq_unit)

  ## take care of Frequency axis
  # custom breaks
  if (!is.na(y_breaks[1])) {
    setkey(FreqTable, Hz)
    y_breaks = FreqTable[J(y_breaks), roll = 'nearest'][, smooth_Hz]
    plt <- plt + scale_y_continuous(expand = c(0,0), labels = true_y_labels,
                                    breaks = y_breaks)
  } else {
    # no custom breaks
    plt <- plt + scale_y_continuous(expand = c(0,0), labels = true_y_labels)
  }

  ## Take care of Time axis
  if (!is.na(x_breaks[1]) & precise_time) {
    setkey(TimeTable, Time)
    x_breaks = TimeTable[J(x_breaks), roll = 'nearest'][, smooth_Time]
    plt <- plt + scale_x_continuous(expand = c(0,0), labels = true_x_labels,
                                    breaks = x_breaks)
  } else if (!is.na(x_breaks[1]) & !precise_time) {
    # check if x_labs is defined
    if (any(is.na(x_labs))) {
      x_labs = x_breaks
    }
    setkey(TimeTable, Time)
    x_true_breaks = TimeTable[J(x_breaks), roll = 'nearest'][, smooth_Time]
    plt <- plt + scale_x_continuous(expand = c(0,0), breaks = x_true_breaks,
                                    labels = x_labs)
  } else if (is.na(x_breaks[1]) & precise_time) {
    plt <- plt + scale_x_continuous(expand = c(0,0), labels = true_x_labels)
  } else {
    plt <- plt + scale_x_continuous(expand = c(0,0))
  }

  ## take care of contour
  if (contours) {
    plt <- plt + geom_contour(color = "white", alpha = 0.5)
  }

  ## highlight area
  if (!is.na(highlight[1])) {
    h = highlight
    setkey(FreqTable, Hz)
    h[1] = FreqTable[J(h[1]), roll = 'nearest'][, smooth_Hz]
    h[2] = FreqTable[J(h[2]), roll = 'nearest'][, smooth_Hz]
    setkey(TimeTable, Time)
    h[3] = TimeTable[J(h[3]), roll = 'nearest'][, smooth_Time]
    h[4] = TimeTable[J(h[4]), roll = 'nearest'][, smooth_Time]
    #highlight should be c(Freq1, Freq2, Time1, Time2)
    plt <- plt + geom_rect(aes(ymin = h[1], ymax = h[2], xmin = h[3],
                               xmax = h[4]), inherit.aes = FALSE,
                           colour = 'white', fill = 'transparent',
                           lwd = 1)

  }
  return(plt)
}



##' @title Importing eeg tables from EEGlab
##' @description This is the only way to import eeglab data to eegUtils that
##' really worked for me. This assumes that you wrangled your data in eeglab/matlab
##' into a long table and then exported it as a csv. The csv should have the
##' following format:
##'\itemize{
##' \item one columns per Electrode, column names should be electrode names.
##' \item one column coding participant ID, column name must be 'participant_id' (can also be used for trials)
##' \item one column coding time, called 'time'
##' \item one column with a unique value representing sampling rate, called 'srate'
##' \item one column with a unique value representing the used reference, called 'reference'
##'}
##' How to get your data into that format likely depends heavily on the specific
##'  situation. Thus, there's no matlab-pendant to this function. Nevertheless,
##' in the examples section below, you can find one possible way of accomplishing
##'  this in Matlab.
##'
##' Note that this function can currently read neither the EEG.events structure
##' (good luck flattening that to a csv...), nor the EEG.chanlocs structure.
##' Chanlocs are substituted by reading the channel locations from a .txt file
##' instead.
##'
##'
##' Note: depends on Matt Craddock's eegUtils package, which is not available on
##' CRAN. Use \code{remotes::install_github("craddm/eegUtils")} instead.
##'
##'
##' @param DT a \code{data.table} with exactly the columns specified for the csv above
##' @param channel_locfile a .txt file with spherical coordinates for your channels.
##' defaults to the scalp-channels of the custom Easycap montage used in our lab
##' at the WWU Münster, Germany.
##' @return an \code{eegUtils} object
##' @examples
##' # Matlab first, R below
##' \dotrun{
##' #%%%%% EXPORTING IN MATLAB %%%%% (usage in R below)
##' # EEG.bsldata are baselined data (64x1900x30; chan x time x id)
##' # stack the third dimension, so this becomes 2D
##' #FLAT = reshape(EEG.bsldata, size(EEG.bsldata,1),[],1);
##' #
##' #% make this a table
##' #FLAT = array2table(FLAT');
##' #
##' #% set column names to channel names
##' #CHANS = {EEG.chanlocs.labels};
##' #FLAT.Properties.VariableNames = CHANS;
##' #
##' #% Add column that codes ID
##' #ID = repelem(1:size(EEG.bsldata, 3), size(EEG.bsldata, 2))';
##' #                   FLAT.participant_id = ID;
##' #
##' #% add column that codes time
##' #TIME = repmat(EEG.times, 1, size(EEG.bsldata,3))';
##' #FLAT.time = TIME;
##' #
##' #% add column with unique sampling rate value
##' #FLAT.srate = repelem(EEG.srate, height(FLAT), 1);
##' #
##' #% add column with unique reference name
##' #FLAT.reference = repelem('average', height(FLAT), 1);
##' #
##' #% write table to csv
##' #writetable(FLAT, 'foo.csv')
##' #
##' #-----------------------------
##' #-----------------------------
##' #-----------------------------
##' ###### Importing in R #######
##' wmR::libraries(data.table, eegUtils, ggplot2, wmR)
##' EEG <- fread('foo.csv')
##' EEG <- EEG = eeglabCSV2eegUtils(EEG)
##' subEEG = select_times(EEG, c(0,100))
##' ggplot(subEEG  , aes(x = x, y = y, fill = amplitude)) + geom_topo()
##' }
##' @author Wanja Mössing
##' @name eeglabCSV2eegUtils
##' @seealso eegUtils txt_elec_2_eegUtils
##' @import data.table eegUtils assertthat
##' @export eeglabCSV2eegUtils
##' @importFrom data.table data.table
eeglabCSV2eegUtils <- function(DT, channel_locfile = NULL) {
  # create artifical sample info (needs to be an ongoing counter)
  DT[, sample := .I]

  # now act as if participants were epochs
  DT[, epoch := participant_id]
  assert_that(DT[, is.numeric(participant_id)],
              msg = 'please use numbers for `participant_id`.')
  EPOCH = dplyr::tibble(
    DT[, .(participant_id = '001', recording = NA, epoch_label = NA),
             by = epoch]
    )

  # get sampling rate
  srate <- DT[, unique(srate)]
  assert_that(length(srate) == 1, msg = 'srate not uniform. please read ?eeglabCSV2eegUtils')

  # get chanlocs
  chanlocs <- wmR::txt_elec_2_eegUtils(channel_locfile)

  # reduce dataset to eeg channels
  CHANS = colnames(DT)[!(colnames(DT) %like% 'participant_id|time|srate|sample|epoch|reference')]
  DATA = as.data.frame(DT[,.SD, .SDcols = CHANS])

  # construct timings
  TIMINGS = dplyr::tibble(DT[, .(epoch = as.double(epoch),
                                 sample = as.double(sample), time) ])

  # construct reference info
  REF <- list(ref_chans = DT[, unique(reference)],
              excluded = NULL)


  # create the eeg_data object
  EEG = eegUtils:::eeg_data(data = DATA, srate = srate, chan_info = chanlocs,
                            timings = TIMINGS,
                            epochs = EPOCH,
                            reference = REF
                            )

EEG = eegUtils:::validate_eeg_epochs(EEG)
return(EEG)
# - might have to fake event structure?
}


##' @title txt_elec_2_eegUtils
##' @description This is adjusted from \code{eegUtils:::import_chans}, which did
##' not work for me. Only tested this function with our custom layout file with
##' the specific constellation used in our lab at the WWU.
##'
##' Note: depends on Matt Craddock's eegUtils package, which is not available on
##' CRAN. Use \code{remotes::install_github("craddm/eegUtils")} instead.
##'
##' If you need your own chanlocs, check the necessary format in the file:
##' \code{system.file("extdata","easycap_m43v3_biosemi_buschlab_scalponly.txt", package = "wmR")}
##' @param file_name path+name to the .txt file with spherical coordinates. Default
##' is our custom Easycap montage (Buschlab WWU Münster).
##' @return a \code{eegUtils} channel location tibble
##' @examples
##' chanlocs <- txt_elec_2_eegUtils()
##' @author Wanja Mössing
##' @name txt_elec_2_eegUtils
##' @seealso eegUtils eeglabCSV2eegUtils
##' @import data.table eegUtils assertthat
##' @export txt_elec_2_eegUtils
##' @importFrom data.table data.table
txt_elec_2_eegUtils <- function(file_name = NULL) {
  if (is.null(file_name)) {
    file_name = system.file("extdata",
                            "easycap_m43v3_biosemi_buschlab_scalponly.txt",
                            package = "wmR")
    cat('txt_elec_2_eegUtils: no user input, using default easycap_m43v3_biosemi_buschlab_scalponly layout')
  }
  raw_locs = data.table::fread(file_name)

  # deal with naming differences
  setnames(raw_locs, 'Theta', 'theta', skip_absent = T)
  setnames(raw_locs, 'Phi', 'phi', skip_absent = T)
  setnames(raw_locs, new = rep('electrode', 7), skip_absent = T,
           old = c('Name', 'name', 'Names', 'names', 'electrodes',
                       'Electrode', 'Electrodes'))

  # phi & theta are supposed to be double, not integer (breaks topoplots?!)
  # raw_locs[, ':='(phi = as.double(phi), theta = as.double(phi))]


  cart_xyz = eegUtils:::sph_to_cart(raw_locs[, theta], raw_locs[, phi])

  final_locs = tibble::tibble(
    raw_locs[, .(electrode = electrode, theta, phi)][, radius := 1]
    )

  xy <- eegUtils:::project_elecs(final_locs, method = "stereographic")
  final_locs = cbind(final_locs, cart_xyz, xy)
  final_locs = tibble::as_tibble(final_locs)

  # fix order of columns to be consistent with demo dataset in eegUtils pack
  final_locs = dplyr::relocate(final_locs, electrode, radius, theta, phi,
                               cart_x, cart_y, cart_z, x, y)


  return(final_locs)
}
