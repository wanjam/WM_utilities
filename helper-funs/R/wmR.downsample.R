my_downsample <- function (pddt, by, Hz = 100) 
{
  sampleTime <- pddt[, Time[2] - Time[1]]
  binSize <- 1000/Hz
  if (binSize%%sampleTime != 0) {
    warning("Sample frequency of data is not a multiple of the target frequency specified in the by argument")
  }
  pddt$DS <- pddt$Time%/%binSize
  allF <- c(by, "DS")
  
  my_mode <- function(vect){
    res = sort(vect,decreasing = T)[1]
    return(res)
  }
  
  pddt <- pddt[, .(Dil = median(Dil), X = median(X), Y = median(Y),
                   ttl = my_mode(TTL), IthSaccadePerSubject = my_mode(IthSaccadeThisSubject),
                   Blink = my_mode(Blink), Fixation = my_mode(Fixation),
                   Saccade = my_mode(Saccade), AverageVelocity = my_mode(AverageVelocity),
                   PeakVelocity = my_mode(PeakVelocity)), 
               by = allF]
  pddt$Time <- pddt$DS * binSize
  pddt$DS <- NULL
  return(pddt)
}