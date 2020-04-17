# wmR::oneliners, set of shortcuts to frequently used things
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

##' @title computername
##' @description  returns computername; shortcut for \code{Sys.info()['nodename']}
##'
##' @return Returns character with computername
##'
##' @examples
##' thispc <- computername()
##' print(thispc)
##'
##' if (computername() == 'LinuxServer') {
##'    rootdir = '/home/wanja/data'
##' } else if (computername() == 'Laptop') {
##'    rootdir = 'C:/Users/Wanja/data'
##' }
##'
##'
##' @author Wanja Mössing
##' @name computername
##' @export computername
##' @importFrom data.table data.table
computername <- function(){
  return(as.character(Sys.info()['nodename']))
}

##' @title pcswitch
##' @description  Does something specific to the host it's running on.
##'
##' @return Returns the result of whatever it is supposed to evaluate
##'
##' @param Names a vector of Names to be compared to the \code{computername()}
##' @param ... number of elements to be evaluated upon a match.
##' Order must match Names. That is, if \code{Names[1] == computername()}, the
##' first element in \code{...} will be evaluated
##' @param append append this string to the result. silently ignored, if the
##' result isn't a string
##' @examples
##' \donttest{
##' rootdir <- pcswitch(c('LinuxServer', 'WinLaptop', 'WinStation'),
##'                       append = 'User',
##'                       '/', 'C:/', 'F:/')
##'
##' rootdir <- pcswitch(c('LinuxServer', 'WinLaptop', 'WinStation'),
##'                       mean(1:99), 77, 'F:/')
##'}
##'
##' @author Wanja Mössing
##' @name pcswitch
##' @export pcswitch
##'
pcswitch <- function(Names = nastr(3), ..., append = ''){
  res <- switch(which(Names == computername()), ...)
  if (is.character(res)) {
    return(paste0(res, append))
  } else {
    return(res)
  }
}

##' @title NaNs
##' @description Generates a vector of NaNs with variable length
##'
##' @param n an \code{integer}. Length of vector.
##' @return Returns a 1-row \code{vector} with N NaNs
##' @seealso \code{nastr(), NAs()}
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

##' @title NAs
##' @description Generates a vector of NAs with variable length
##'
##' @param n an \code{integer}. Length of vector.
##' @return Returns a 1-row \code{vector} with N NaNs
##' @seealso \code{NaNs(), nastr()}
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

##' @title  nastr
##' @description  Generates a vector of NA_character_ with variable length.
##' Useful for preallocating a character variable.
##'
##' @param n an \code{integer}. Length of vector.
##' @return Returns a 1-row \code{vector} with N NaNs
##' @seealso \code{NaNs(), NAs()}
##' @examples
##' mynas <- nastr(100)
##'
##' library(data.table)
##' DT <- data.table(A = nastr(50))
##'
##' @author Wanja Mössing
##' @name nastr
##' @export nastr
##'
nastr <- function(n){
  return(rep(NA_character_, n))
}

##' @title  Load multiple libraries with one command
##' @description loads multiple libraries in one line without massive printing
##' to console.
##' @param ... comma-separated library names without or with quotes. Or a
##' character vector of library names.
##' @return Nothing. Unloadable packs will throw errors.
##' @seealso \code{library()}
##' @examples
##' wmR::libraries(data.table, lme4, ggplot2)
##' wmR::libraries('data.table', 'lme4', 'ggplot2')
##' packs <- c('data.table', 'lme4', 'ggplot2')
##' wmR::libraries(packs)
##'
##' @author Wanja Mössing
##' @name libraries
##' @export libraries
##'
libraries <- function(...){
  packs <- as.character(as.list(substitute(list(...)))[-1L])
  # 'packs' will be nonsense if a vector was entered...
  if (length(packs) == 1 &&
      (substr(packs, 1, 2) == 'c(' | grepl('packs', packs))) {
    packs <- c(...)
  }
  invisible(sapply(packs, library, character.only = TRUE))
}


##' @title  Debug on error behavior shortcut
##' @description sets global options to use \code{recover} or not upon non-
##' catastrophical errors. If used without input, it will work like a switch,
##' changing whatever the current state is to the opposite.
##' @param do_pause logical. enable or disable recovering upon errors. NA
##' (default) checks what the current state is and switches debugging on or off.
##' @return Nothing.
##' @seealso \code{options(error)}
##' @examples
##' library(wmR)
##' pause_on_error(TRUE)
##' \donttest{sum('THREEPLUSFOUR')}
##' pause_on_error(FALSE)
##' \donttest{sum('THREEPLUSFOUR')}
##'
##' @author Wanja Mössing
##' @name pause_on_error
##' @export pause_on_error
pause_on_error <- function(do_pause = NA) {
  if (is.na(do_pause)) {
    # get current status
    stat = getOption('error')
    if (is.null(stat)) {
      options(error = utils::recover)
      print('Turning recover() upon errors on.')
    } else if (.fun_overlap(stat, utils::recover) > .8) {
      options(error = NULL)
      print('Turning recover() upon errors off.')
    } else if (!is.null(grep('.rs.breakOnError|.rs.recordTraceback',
                             deparse(stat)))) {
      options(error = NULL)
      warning(paste0('Trying to turn off error handling. You seem to be using',
                     ' Rstudio.\nSo you might want to use the toolbar-menu ',
                     '(Debug -> On Error) instead of this function.'))
    }
  } else if (do_pause == TRUE) {
    options(error = utils::recover)
    print('Turning recover() upon errors on.')
  } else if (do_pause == FALSE) {
    options(error = NULL)
    print('Turning recover() upon errors off.')
  }
}

.fun_overlap <- function(fun1, fun2) {
  A = deparse(fun1)
  B = deparse(fun2)
  return(
    (sum(A %in% B) - sum(!(A %in% B))) / (sum(!(A %in% B)) + sum(A %in% B))
    )
}
