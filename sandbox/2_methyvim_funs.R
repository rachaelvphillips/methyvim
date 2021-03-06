# define methytmle class, core class in the package
.methytmle <- methods::setClass(
       Class = "methytmle",
       slots = list(call = "call",  # so the user can remember the args they pass in
                    screen_ind = "numeric",
                    clusters = "numeric",
                    g = "matrix",
                    Q = "matrix",
                    ic = "data.frame",
                    vim = "data.frame"),
       contains = "GenomicRatioSet"
)

# set up methyvim object, hacky to create something of class call
call <- "testing123"
class(call) <- "call" # hacking the call object
methy_tmle <- .methytmle(catch_inputs_ate$data)

#data was originally a genomic ratio set now its a methytmle object
methy_tmle@call <- call

# using LIMMA for screening
limma_screen <- function(methytmle, var_int, type, cutoff = 0.05) {
  # setup design matrix
  design <- as.numeric(colData(methytmle)[, var_int])
  design <- as.matrix(cbind(rep(1, times = length(design)), design))

  # create expression object for modeling
  if (type == "Beta") {
    methytmle_exprs <- minfi::getBeta(methytmle)
  } else if (type == "Mval") {
    methytmle_exprs <- minfi::getM(methytmle)
  }

  # fit limma model and apply empirical Bayes shrinkage
  mod_fit <- limma::lmFit(object = methytmle_exprs, design = design)
  mod_fit <- limma::eBayes(mod_fit)

  # extract indices of relevant CpG sites
  tt_out <- limma::topTable(mod_fit, coef = 2, num = Inf, sort.by = "none")
  indices_pass <- which(tt_out$P.Value < cutoff)

  #takes in methytmle object and returns same but with screen slot filled

  # add to appropriate slot in the methytmle input object
  methytmle@screen_ind <- indices_pass
  return(methytmle)
}

# function to cluster sites
cluster_sites <- function(methy_tmle, window_size = 1000) {
  gr <- SummarizedExperiment::rowRanges(methy_tmle)
  pos <- BiocGenerics::start(IRanges::ranges(gr))
  clusters <- bumphunter::clusterMaker(chr = GenomeInfoDb::seqnames(gr),
                                       pos = pos,
                                       assumeSorted = FALSE,
                                       maxGap = window_size)
  methy_tmle@clusters <- as.numeric(clusters)
  return(methy_tmle)
}
# same as above, fills in cluster slot

# force positivity assumption to hold
force_positivity <- function(A, W, pos_min = 0.1, q_init = 10) {
  stopifnot(length(A) == nrow(W))

  if (class(W) != "data.frame") W <- as.data.frame(W) # cover use of "ncol"
  out_w <- NULL # concatenate W columnwise as we discretize each covar below

  for (obs_w in seq_len(ncol(W))) {
    in_w <- as.numeric(W[, obs_w])
    discr_w <- as.numeric(as.factor(gtools::quantcut(x = in_w, q = q_init)))
    check <- sum((table(A, discr_w) / length(A)) < pos_min)
    next_guess_q <- q_init
    while (check > 0) {
      next_guess_q <- (next_guess_q - 1)
      discr_w <- as.numeric(as.factor(gtools::quantcut(x = in_w,
                                                       q = next_guess_q)))
      check <- sum((table(A, discr_w) / length(A)) < pos_min)
    }
    out_w <- cbind(out_w, discr_w)
  }
  out <- as.data.frame(out_w)
  colnames(out) <- colnames(W)
  rownames(out) <- rownames(W)
  if(length(which(colSums(out) == length(A))) > 0) {
    out <- out[, -which(colSums(out) == length(A)), drop = FALSE]
  }
  return(out)
}

set_parallel <- function(parallel = c(TRUE, FALSE),
                         future_param = NULL,
                         bppar_type = NULL) {
  # invoke a future-based backend
  doFuture::registerDoFuture()

  if (parallel == TRUE) {
    if (!is.null(future_param)) {
      set_future_param <- parse(text = paste0("future", "::", future_param))
      future::plan(eval(set_future_param))
    } else {
      future::plan(future::multiprocess)
    }
  } else if (parallel == FALSE) {
    warning(paste("Sequential evaluation is strongly discouraged.",
                  "\n Proceed with caution."))
    future::plan(future::sequential)
  }
  if (!is.null(bppar_type)) {
    bp_type <- eval(parse(text = paste0("BiocParallel", "::",
                                        bppar_type, "()")))
  } else {
    bp_type <- BiocParallel::DoparParam()
  }
  # try to use a progress bar is supported in the parallelization plan
  BiocParallel::bpprogressbar(bp_type) <- TRUE
  # register the chosen parallelization plan
  BiocParallel::register(bp_type, default = TRUE)
}

# advanced vingette discussing internals of the package
# not writing about force positivity in the
# treatment (discrete) and W is a matrix of cont measures assoc w each of the
# vars in w where vars are columns and rows are observed data
# posmin tells you the min mass you want thats created when you discretize
# a given variable of w and discretize a
# pos min created when we look at the
# w min tells you the min nuber of obs to match a cont observation to
# make sure each cell has 10% of the observations
# if thats not true it will rediscretize to nine levels
# does this for all variables of w
# now each of the obs data are now replaced with a level of that obs while
# maintaining the positivity

# somehow this is related to cTMLE
