#This set of functions is a port of Paul Bays' Matlab code used to analyze circular data

#We use degree instead of rad. Auto-convert inside of function.
#Also, we just input error directly instead of calculating it. So E=vector of errors
deg2precision <- function(E,includeBias=FALSE){
  require(pracma)
  require(circular)
  require(data.table)
  E = circular(deg2rad(E),units = "radians")
  N = length(E);
  x = logspace(-2,2,100)
  P0 = pracma::trapz(x,N/(sqrt(x)*exp(x+N%*%exp(-x)))); # Expected precision under uniform distribution
  
  P = 1/sd(E) - P0 # Corrected precision
  
  # Bias
  if(includeBias){
  B = mean(E)
  P = data.table(P=P,B=B)
  }
  return(P)
}