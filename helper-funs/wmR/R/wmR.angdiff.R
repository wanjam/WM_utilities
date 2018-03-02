#' Take two angles in degree and calculates their difference
#'
#' \code{wmR.angdiff} returns the difference between deg1 and deg2
#'
#' @param deg1 Numeric in range 0:360
#' @param deg2 Numeric in range 0:360
#'
#' @return a single floating point number representing the difference between the two angles.
#'   Can take on negative values, as it show the orientation of deg1 IN RELATION to deg2.
#'   So a result of -1 means, that deg1 is 1° less than deg2.
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
#' @importFrom CircStats deg rad
#' @importFrom base atan2 cos
#' @export
wmR.angdiff <- function(deg1, deg2) {
  if (deg1 > 360 || deg2 > 360 || deg1 < 0 || deg2 < 0) {
    warning('wmR.angdiff: deg1 and/or deg2 are >360° and/or <0°; using deg %% 360 instead')
  }

  #This avoids confusion, where wmR.angdiff(0,360) is non-zero.
  if (deg1 == 0) {deg1 <- 360}
  if (deg2 == 0) {deg2 <- 360}

  a = deg(atan2(sin(rad(deg1 - deg2)), cos(rad(deg1 - deg2))))
  return(a)
}
