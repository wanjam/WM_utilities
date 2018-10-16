# wmR::fair_distribution attempts to create a somewhat-fair distribution for the topics in a seminar
#     Copyright (C) 2018 Wanja Mössing
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

##' Generates a somewhat fair distribution of topics for a given set of groups with ordered preferences per group.
##'
##' @param DT a \code{data.table} where each column represents one group and the rows contain their choices in the preferred order.
##' @return Returns a 1-row \code{data.table} with the final topic per group.
##'
##' @examples
##' require(data.table)
##' DT <- data.table(group1 = sample(5), group2 = sample(5), group3 = sample(5),
##'                  group4 = sample(5), group5 = sample(5))
##' fair_distribution(DT)
##'
##' @author Wanja Mössing
##' @name fair_distribution
##' @export fair_distribution
##' @import data.table
##'
fair_distribution <- function(DT){
  require(data.table)
  # DT should be a data.table with each column representing 1 group and each row showing their choices in descending order (integers)
  # sanity checks
  if(nrow(DT) < ncol(DT)){
    stop('Fewer options than groups is unfair!')
  } # more rows than columns would mean that there are topics that won't be presented

  for(cnames in colnames(DT)){
    if(any(duplicated(DT[,..cnames]))) {
      stop('Some groups have multiple entries')
    }
  }

  # use group 1 as reference and check if all other groups have the same values
  ref = DT[,1][,.I]
  for(igrp in 2:ncol(DT)){
    for(iopt in ref){
      if(!any(iopt == DT[,..igrp][,.I])){
        stop('groups contain different sets of options!')
      }
    }
  }

  # Do the actual fair distribution

  result <- DT[1,]
  result[1,] <- NA
  used <- c()
  cnames <- colnames(DT)

  for(iopt in 1:nrow(DT)){
    curchoices <- as.matrix(DT[iopt,])
    Ns <- table(curchoices)
    Ns = as.data.table(Ns)
    Ns = Ns[!(curchoices %in% used)]
    # check if anyone has an option that nobody else wants
    if(any(Ns$N==1)){
      for(iiopt in Ns[N==1, curchoices]){
        groupchoice = names(curchoices[,curchoices == iiopt])
        result[,eval(groupchoice)] <- as.integer(iiopt)
        used = c(used, as.integer(iiopt))
        if(length(used)==ncol(result)){break}
        DT[,eval(groupchoice)] <- NULL
        curchoices <- as.matrix(DT[iopt,])
      }
    }
    # once all single-choices are sorted out, we randomly choose another group per option that's been chosen multiple times
    Ns <- table(curchoices)
    Ns = as.data.table(Ns)
    Ns = Ns[!(curchoices %in% used)]
    if(any(Ns$N>1)){
      for(iiopt in Ns[N>1, curchoices]){
        groups = names(curchoices[,curchoices == iiopt])
        groupchoice = sample(groups, 1)
        result[,eval(groupchoice)] <- as.integer(iiopt)
        used = c(used, as.integer(iiopt))
        if(length(used)==ncol(result)){break}
        DT[,eval(groupchoice)] <- NULL
        curchoices <- as.matrix(DT[iopt,])
      }
    }
  }
  return(result)
}
