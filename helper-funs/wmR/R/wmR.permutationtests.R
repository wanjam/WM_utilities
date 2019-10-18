# wmR::permutationtests.R contains functions to compute simple permutation tests
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

##' Run a paired two sample permutation test for timeseries (e.g., ERPs)
##' @description \code{TimeSeriesPermutationTest} runs a two-sample time-series
##' permutation test
##' Specifically, the test runs paired two sample t-tests for each timepoint and
##' compares the resulting t-statistics with a permutation distribuion. A minimal
##' cluster length for consequitive timepoints can be specified (see below.)
##'
##' @param data a \code{data.table} in long format with columns for at least the
##'  following content
##' @param condCol name of the column in data coding the condition labels
##' (default: 'condition')
##' @param dataCol name of the column in data coding the measure values (default
##' : 'mV')
##' @param idCol name of the column in data coding the IDs/Subjects (default:
##' 'ID')
##' @param timeCol name of the column in data coding the time (default: 'Time')
##' @param nperm number of permutations (default: 1000)
##' @param altrntv passed to the t.test functions (default: 'two.sided'); In
##' case of 'greater' or 'less', you need to specify \code{treatment.group}
##' @param treatment.group only necessary if \code{altrntv} is 'greater' or
##' 'less'. Indicates which group is supposed to be greater or less than the
##' other group. Should be a char matching the label in condCol. (e.g., 'A',
##' 'treatment', 'valid-cue', etc.)
##' @param alpha significance threshold used for significance detection
##' (default: 0.05)
##' @param cluster.length minimum number of consequtive significant samples to
##' be considered a significant cluster (default: 5)
##' @return a \code{data.table} with one row per timepoint. Contains columns for
##'  cluster-significance, single-sample-significance, t-value of the true
##'  t-test and permutation p-values. Two additional columns code the beginning
##'  and end of each cluster.
##' @details
##' alternative = "greater" is the alternative that the treatment.group has a
##' larger mean than the other group.
##' @examples
##' # create fake data
##' libraries(data.table, ggplot)
##' data = data.table()
##' for (id in 1:10){
##'   data = rbind(data, data.table(mV = rnorm(4000, 2, 0.5),
##'                                condition = c(rep('A', 2000), rep('B', 2000)),
##'                                Time = rep(-500:1499, 2), ID = id))
##'                                }
##' # create two "real" clusters around Time 500 & 1000
##' data[Time %between% list(490, 510) & condition == 'A', mV := mV + 10]
##' data[Time %between% list(990, 1010) & condition == 'A', mV := mV - 10]
##'
##' # plot data
##' ggplot(data[, .(mV = mean(mV)), by = .(ID, Time, condition)],
##'        aes(x = Time, y = mV, color = condition)) +
##'   geom_line()
##'
##' # run test
##' foo = TimeSeriesPermutationTest(data, nperm = 100)
##'
##' @author Wanja Mössing
##' @name TimeSeriesPermutationTest
##' @export TimeSeriesPermutationTest
##' @seealso t.test
##' @import data.table
##' @import assertthat
TimeSeriesPermutationTest <- function(data, condCol='condition', dataCol='mV',
                                      idCol = 'ID', timeCol='Time',
                                      nperm = 1000, altrntv="two.sided",
                                      alpha = 0.05, cluster.length = 5,
                                      treatment.group = '') {

  # get number of timepoints/ subjects and convert to factors
  data[, cond := as.factor(get(condCol))]
  data[, id := as.factor(get(idCol))]
  data[, dat := as.numeric(get(dataCol))]
  data[, ti := as.numeric(get(timeCol))]
  tvals = data[, unique(ti)]
  labels = data[, unique(cond)]

  # currently only for ttests, so stop if more than 2 conditons
  assert_that(length(labels) == 2, msg = "This function can only handle 2 conditions")

  # split data by condition
  DT = dcast(data, id +  ti ~ cond, value.var = 'dat')
  lvls = data[, levels(cond)]
  cols = colnames(DT)
  cols = cols[cols %in% lvls]
  if (altrntv == 'two.sided') {
    setnames(DT, cols, c('A', 'B'))
  } else {
    setnames(DT, treatment.group, 'A')
    setnames(DT, cols(cols != treatment.group), 'B')
  }


  # compute true t-statistic per timepoint
  gettval = function(..., n, maxn, pb){
    setTxtProgressBar(pb, n)
    return(as.numeric(t.test(...)$statistic))
    # print((n/maxn))
  }
  cat('\nComputing base t-statistics...\n')
  pb <- txtProgressBar(min = 0, max = length(tvals), style = 3)
  baseStat = DT[, .(t = gettval(A, B, alternative = altrntv,
                                paired = T, var.equal = T,
                                conf.level = 1 - alpha,
                                n = .GRP, maxn = .N, pb = pb)),
                by = ti]

  # shuffle labels and compute timepoint-wise permutation distributions
  cat('\nShuffling labels...')
  res = rbindlist(replicate(nperm, DT, simplify = F))
  res[, iperm := rep(1:nperm, each = DT[,.N])]
  res[, ':='(A = sample(A), B = sample(B)), by = .(id, iperm)]
  cat('\nComputing t-statistics for permutations...\n')
  pb <- txtProgressBar(min = 0, max = length(tvals) * nperm, style = 3)
  permStat = res[, .(t = gettval(A, B, alternative = altrntv, paired = T,
                                 var.equal = T, conf.level = 1 - alpha,
                                 n = .GRP, maxn = .N, pb = pb)),
                 by = .(ti, iperm)]

  # calculate p-vals
  cat('\nCalculating p-values...\n')
  if (altrntv == 'two.sided') {
    alpha = alpha/2
  }
  pb = txtProgressBar(min = 0, max = length(tvals), style = 3)
  pbcount = 0;
  for (iti in tvals) {
    permts = permStat[ti == iti, t]
    baset  = baseStat[ti == iti, t]
    i.p = sum(permts > baset) / nperm # greater
    if (altrntv == 'two.sided') {
      i.p = min(i.p, 1 - i.p)
    } else if (altrntv == 'less') {
      i.p = 1 - i.p
    }
    baseStat[ti == iti, p := i.p]
    pbcount = pbcount + 1
    setTxtProgressBar(pb, pbcount)
  }
  baseStat[, is.significant := FALSE]
  baseStat[p < alpha, is.significant := TRUE]

  cat('\ndetecting significant clusters...\n')
  # there must be a faster data.table operation for this...
  baseStat[, significant.cluster := is.significant]
  baseStat[, cluster.enum.start := 0]
  baseStat[, cluster.enum.end := 0]
  setorder(baseStat, ti)

  count = 0
  clustercount = 0
  itis = c()

  # loop over timepoints and count the consequitively significant timepoints
  pb = txtProgressBar(min = 0, max = length(tvals), style = 3)
  pbcount = 0
  for (iti in baseStat[, unique(ti)]) {
    foo = baseStat[ti == iti, is.significant]
    if (foo) {
      count = count + 1
      itis = c(itis, iti)
    } else {# when the current timepoint is not significant...
      if (count %between% list(1, cluster.length)) { # and we did't have n consequitively significant timepoints
        baseStat[ti %in% itis, significant.cluster := FALSE] # set all those to false
      } else if (count >= cluster.length) { # if we detected a cluster
        clustercount = clustercount + 1
        baseStat[ti == itis[1], cluster.enum.start := clustercount]
        baseStat[ti == tail(itis, 1), cluster.enum.end := clustercount]
      }
      count = 0
      itis = c()
    }
    pbcount = pbcount + 1
    setTxtProgressBar(pb, pbcount)
  }
  setnames(baseStat, 'ti', timeCol)
  return(baseStat)
}
