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
##' Note: This does not run cluster correction. If you want to use cluster
##' correction as in Maris and Oostenveldt (2007), use
##' `TimeSeriesClusterBasedPermutationTest` instead.
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
##' libraries(data.table, ggplot2)
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
##' @seealso t.test TimeSeriesClusterBasedPermutationTest
##' @import data.table assertthat utils
##' @importFrom data.table data.table
TimeSeriesPermutationTest <- function(data, condCol='condition', dataCol='mV',
                                      idCol = 'ID', timeCol='Time',
                                      nperm = 1000, altrntv="two.sided",
                                      alpha = 0.05, cluster.length = 5,
                                      treatment.group = '') {

  dat <- copy(data) # avoid overwriting calling environment
  # get number of timepoints/ subjects and convert to factors
  dat[, cond := as.factor(get(condCol))]
  dat[, id := as.factor(get(idCol))]
  dat[, dat := as.numeric(get(dataCol))]
  dat[, ti := as.numeric(get(timeCol))]
  tvals = dat[, unique(ti)]
  labels = dat[, unique(cond)]

  # currently only for ttests, so stop if more than 2 conditons
  assert_that(length(labels) == 2, msg = "This function can only handle 2 conditions")

  # split data by condition
  DT = dcast(dat, id +  ti ~ cond, value.var = 'dat')
  lvls = dat[, levels(cond)]
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
  pb = txtProgressBar(min = 0, max = length(tvals), style = 3)
  baseStat = DT[, .(t = gettval(A, B, alternative = altrntv,
                                paired = T, var.equal = T,
                                conf.level = 1 - alpha,
                                n = .GRP, maxn = .N, pb = pb)),
                by = ti]

  # shuffle labels and compute timepoint-wise permutation distributions
  cat('\nShuffling labels...\n')
  res = rbindlist(replicate(nperm, DT, simplify = F))
  res[, iperm := rep(1:nperm, each = DT[,.N])]
  # per partition, randomly chose 50% of participants and switch condition labels
  IDs = dat[, unique(id)]
  res[, urA:=A]
  res[, urB:=B]
  pb = txtProgressBar(min = 0, max = length(nperm), style = 3)
  for (ip in 1:nperm) {
    subs = sample(IDs, length(IDs)/2, replace = F)
    res[id %in% subs & iperm == ip, ':='(B = urA, A = urB)]
    setTxtProgressBar(pb, ip)
  }

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

  cat('\ndetecting significant temporal clusters...\n')
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




##' Run a paired two sample permutation test for timeseries (e.g., ERPs) with
##' cluster correction.
##' @description \code{TimeSeriesClusterBasedPermutationTest} runs a two-sample time-series
##' permutation test with cluster correction (see Maris and Oostenveldt, 2007).
##' Specifically, the test runs paired two sample t-tests for each timepoint and
##' defines cluster as temporally adjacent significant samples, including at least
##' `cluster.length` samples. It then computes t_sum per cluster (the sum of all
##' t-statistics of samples involved in that cluster).
##' Subsequently, `nperm` random partions are created, in which the condition
##' labels are changed for ~50% of the participants (random without replacement).
##' For each of these random partitions, t_sum for the previously detected clusters
##' is computed. Finally, the observed t_sum is compared against the permutation
##' distribution of t_sums derived from the random partitions, to compute a p-value
##' per cluster.
##'
##' Note: for a version without cluster correction, see `TimeSeriesPermutationtest`
##'
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
##' libraries(data.table, ggplot2)
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
##' foo = TimeSeriesClusterBasedPermutationTest(data, nperm = 100)
##'
##' @author Wanja Mössing
##' @name TimeSeriesClusterBasedPermutationTest
##' @export TimeSeriesClusterBasedPermutationTest
##' @seealso t.test TimeSeriesPermutationTest
##' @import data.table assertthat utils
##' @importFrom data.table data.table
TimeSeriesClusterBasedPermutationTest <- function(data, condCol='condition', dataCol='mV',
                                                  idCol = 'ID', timeCol='Time',
                                                  nperm = 1000, altrntv="two.sided",
                                                  alpha = 0.05, cluster.length = 5,
                                                  treatment.group = '') {

  dat <- copy(data) # avoid overwriting calling environment
  # get number of timepoints/ subjects and convert to factors
  dat[, cond := as.factor(get(condCol))]
  dat[, id := as.factor(get(idCol))]
  dat[, dat := as.numeric(get(dataCol))]
  dat[, ti := as.numeric(get(timeCol))]
  tvals = dat[, unique(ti)]
  labels = dat[, unique(cond)]

  # currently only for ttests, so stop if more than 2 conditons
  assert_that(length(labels) == 2, msg = "This function can only handle 2 conditions")

  # split data by condition
  DT = dcast(dat, id +  ti ~ cond, value.var = 'dat')
  lvls = dat[, levels(cond)]
  cols = colnames(DT)
  cols = cols[cols %in% lvls]
  if (altrntv == 'two.sided') {
    setnames(DT, cols, c('A', 'B'))
  } else {
    setnames(DT, treatment.group, 'A')
    setnames(DT, cols(cols != treatment.group), 'B')
  }


  # compute true t-statistic per timepoint
  gettval = function(..., n, maxn, pb, alpha){
    setTxtProgressBar(pb, n)
    foo = t.test(...)
    return(list(
      t = as.numeric(foo$statistic),
      p = as.numeric(foo$p.value),
      is.significant = as.numeric(foo$p.value) < alpha
      )
    )
    # print((n/maxn))
  }
  cat('\nComputing true t-statistics...\n')
  pb = txtProgressBar(min = 0, max = length(tvals), style = 3)
  baseStat = DT[, gettval(A, B, alternative = altrntv, paired = T, var.equal = T,
                          conf.level = 1 - alpha, n = .GRP, maxn = .N, pb = pb,
                          alpha = alpha),
                by = ti]

  cat('\ndetecting significant temporal clusters...\n')
  # there must be a faster data.table operation for this...
  baseStat[, significant.cluster := is.significant]
  baseStat[, t_sum := 0]
  baseStat[, cluster.enum.start := 0]
  baseStat[, cluster.enum.end := 0]
  baseStat[, cluster.enum := NaN]
  setorder(baseStat, ti)

  count = 0
  clustercount = 0
  itis = c()
  tvs = c()

  # loop over timepoints and count the consecutively significant timepoints
  pb = txtProgressBar(min = 0, max = length(tvals), style = 3)
  pbcount = 0
  for (iti in baseStat[, unique(ti)]) {
    foo = baseStat[ti == iti, is.significant]
    foo.t = baseStat[ti == iti, t]
    if (foo) {
      count = count + 1
      itis = c(itis, iti)
      tvs = c(tvs, foo.t)
    }

    # clusters need to have the same polarity - need to account for the highly
    # unlikely case that a positive cluster is immediately followed by a negative cluster sample or vice vers
    polaritychange = FALSE
    if (count > 1) {
      if (sign(tvs[length(tvs)]) != sign(tvs[length(tvs) - 1])) {
        polaritychange = TRUE
        if (count - 1 < 1) { # not at least two adjacent samples with same directionality and below alpha
          baseStat[ti %in% itis[1:(length(itis)-1)], significant.cluster := FALSE] # set all those to false
        } else if (count - 1 >= 1) { # if we detected a cluster
          clustercount = clustercount + 1
          baseStat[ti == itis[1], cluster.enum.start := clustercount]
          baseStat[ti == tail(itis, 2)[1], cluster.enum.end := clustercount]
          baseStat[ti %between% c(itis[1], tail(itis, 2)[1]),
                   ':='(cluster.enum = clustercount, t_sum = sum(ts[1:(length(ts)-1)]))]
        }
        count = 1
        ts = ts[length(ts)]
        itis = itis[length(itis)]
      }
    }


    if ((!foo || pbcount == baseStat[, uniqueN(ti)] - 1) & !polaritychange) {# when the current timepoint is not significant, or it's the last one
      if (count < 2) { # and we did't have n adjacent significant timepoints
        baseStat[ti %in% itis, significant.cluster := FALSE] # set all those to false
      } else if (count >= 2) { # if we detected a cluster
        clustercount = clustercount + 1
        baseStat[ti == itis[1], cluster.enum.start := clustercount]
        baseStat[ti == tail(itis, 1), cluster.enum.end := clustercount]
        baseStat[ti %between% c(itis[1], tail(itis, 1)),
                 ':='(cluster.enum = clustercount, t_sum = sum(tvs))]
      }
      count = 0
      tvs = c()
      itis = c()
    }
    pbcount = pbcount + 1
    setTxtProgressBar(pb, pbcount)
  }


  # create random partitions by shuffling labels
  cat('\nShuffling labels...\n')
  pb = txtProgressBar(min = 0, max = 7, style = 3)
  res = rbindlist(replicate(nperm, DT, simplify = F))
  setTxtProgressBar(pb, 1)
  res[, iperm := rep(1:nperm, each = DT[,.N])]
  setTxtProgressBar(pb, 2)
  res_ids = res[, .(id = unique(id)), by = iperm]
  setTxtProgressBar(pb, 3)
  res_ids[, switch := sample(c(T,F), replace = T, size = .N), by = iperm]
  setTxtProgressBar(pb, 4)
  res = merge(res, res_ids, by = c('iperm', 'id'))
  setTxtProgressBar(pb, 5)
  res[switch == T, tmp := A]
  setTxtProgressBar(pb, 6)
  res[switch == T, A := B]
  setTxtProgressBar(pb, 7)
  res[switch == T, B := tmp]
  setTxtProgressBar(pb, 8)

  cat('\nComputing t-statistics for permutations...\n')
  pb <- txtProgressBar(min = 0, max = length(tvals) * nperm, style = 3)
  permStat = res[, gettval(A, B, alternative = altrntv, paired = T,
                                 var.equal = T, conf.level = 1 - alpha,
                                 n = .GRP, maxn = .N, pb = pb, alpha = alpha),
                 by = .(ti, iperm)]

  # loop over timepoints and count the consecutively significant timepoints
  cat('\nDetecting clusters in random partitions...\n')
  setorderv(permStat, cols = c('iperm', 'ti'))
  permStat[, norm_ti := .GRP, by = ti]

  # search for positive clusters
  posdat <- permStat[is.significant & t >= 0] # should reduce dataset to ~ 2.5%
  posdat[, shift_ti := shift(norm_ti)]
  posdat[, lead_ti := shift(norm_ti, type = 'lead')]
  posdat[, has_preceding := (norm_ti - shift_ti) == 1]
  posdat[, has_following := (norm_ti - lead_ti) == -1]

  posclusts = posdat[has_preceding == T | has_following == T]

  # we only want the maximal t_sum statistic per permutation. Individual sample's
  # t of those samples involved in a cluster can't possibly be higher than their
  # cluster sum. So it doesn't hurt including them here but makes code more
  # straightforward.
  pos_t_sums = posdat[, .(max_t_sum = max(t, na.rm = T)), by = .(iperm)]

  posclt_sum = 0
  for (irow in 1:posclusts[, .N]) {
    posclt_sum = posclt_sum + posclusts[irow, t]
    if (irow == posclusts[, .N]) {
      pos_t_sums[iperm == posclusts[irow, iperm], max_t_sum := max(max_t_sum, posclt_sum)]
    } else if(posclusts[irow + 1, norm_ti] - posclusts[irow, norm_ti] != 1) {
      pos_t_sums[iperm == posclusts[irow, iperm], max_t_sum := max(max_t_sum, posclt_sum)]
      posclt_sum = 0
    }
  }

  # search for negative clusters
  negdat <- permStat[is.significant & t < 0] # should reduce dataset to ~ 2.5%
  negdat[, shift_ti := shift(norm_ti)]
  negdat[, lead_ti := shift(norm_ti, type = 'lead')]
  negdat[, has_preceding := (norm_ti - shift_ti) == 1]
  negdat[, has_following := (norm_ti - lead_ti) == -1]

  negclusts = negdat[has_preceding == T | has_following == T]

  # we only want the maximal t_sum statistic per permutation. Individual sample's
  # t of those samples involved in a cluster can't possibly be higher than their
  # cluster sum. So it doesn't hurt including them here but makes code more
  # straightforward.
  neg_t_sums = negdat[, .(min_t_sum = min(t, na.rm = T)), by = .(iperm)]

  negclt_sum = 0
  for (irow in 1:negclusts[, .N]) {
    negclt_sum = negclt_sum + negclusts[irow, t]
    if (irow == negclusts[, .N]) {
      neg_t_sums[iperm == negclusts[irow, iperm], min_t_sum := min(min_t_sum, negclt_sum)]
    } else if(posclusts[irow + 1, norm_ti] - posclusts[irow, norm_ti] != 1) {
      neg_t_sums[iperm == negclusts[irow, iperm], min_t_sum := min(min_t_sum, negclt_sum)]
      negclt_sum = 0
    }
  }

  # for each permutation: decide whether to keep nehative or positive value
  perm_dist = merge(pos_t_sums, neg_t_sums, by = 'iperm')
  perm_dist[, t_max := ifelse(max_t_sum >= abs(min_t_sum), max_t_sum, min_t_sum)]
  permdist = perm_dist$t_max

  # calculate cluster p-vals
  cat('\nCalculating p-values...\n')
  if (altrntv == 'two.sided') {
    alpha = alpha/2
  }
  # pb = txtProgressBar(min = 0, max = baseStat[, uniqueN(cluster.enum)], style = 3)
  # pbcount = 0;
  for (iclust in baseStat[, na.omit(unique(cluster.enum))]) {
    base_tsum  = baseStat[cluster.enum == iclust, unique(t_sum)]
    i.p = sum(permdist > base_tsum) / nperm # greater
    if (altrntv == 'two.sided') {
      i.p = min(i.p, 1 - i.p)
    } else if (altrntv == 'less') {
      i.p = 1 - i.p
    }
    baseStat[cluster.enum == iclust, cluster_p := i.p]
    # pbcount = pbcount + 1
    # setTxtProgressBar(pb, pbcount)
  }
  baseStat[, cluster.is.significant := FALSE]
  baseStat[cluster_p < alpha, cluster.is.significant := TRUE]
  return(baseStat)
}
