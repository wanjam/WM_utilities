#This set of functions is a port of Paul Bays' Matlab code used to analyze circular data

# ##1 Precision
# % [P B] = JV10_ERROR (X, T)
# %   Returns precision (P) and bias (B) measures for circular recall data. 
# %   Inputs X and T are (nx1) vectors of responses and target values
# %   respectively, in the range -PI <= X < PI. If T is not specified,
# %   the default target value is 0.
# %
# %   Ref: Bays PM, Catalao RFG & Husain M. The precision of visual working 
# %   memory is set by allocation of a shared resource. Journal of Vision 
# %   9(10): 7, 1-11 (2009) 
# %
# %   --> www.paulbays.com

#We use degree instead of rad. Auto-convert inside of function.
#Also, we just input error directly instead of calculating it. So E=vector of errors
deg2precision <- function(E){
  require(pracma)
  require(circular)
  E = circular(deg2rad(E),units = "radians")
  N = length(E);
  x = logspace(-2,2,100)
  P0 = pracma::trapz(x,N/(sqrt(x)*exp(x+N%*%exp(-x)))); # Expected precision under uniform distribution
  
  P = 1/sd(E) - P0 # Corrected precision
  
  # Bias
  B = mean(E)
}