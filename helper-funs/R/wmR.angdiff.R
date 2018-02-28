my_angdiff <- function( deg1, deg2){
#MY_ANGDIFF takes two angles in degree and outputs their difference
a = deg(atan2(sin(rad(deg1-deg2)),cos(rad(deg1-deg2))))
return(a)
}