% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/utils.R
\name{force_positivity}
\alias{force_positivity}
\title{Enforce the Assumption of Positivity}
\usage{
force_positivity(A, W, pos_min = 0.1, q_init = 10)
}
\arguments{
\item{A}{Numeric giving the levels of the (discretized) treatment variable.}

\item{W}{Data.Frame or Matrix containing the covariates in the adjustment set
to be discretized against the levels of the treatment variable.}

\item{pos_min}{Numeric indicating the minimum mass (as a proportion) of the
observations to be included in any cell of the table composed of the
levels of the treatment against levels of an adjustment covariate.}

\item{q_init}{Numeric indicating the initial number of levels to discretize a
given adjustment variable into. This defaults to quantiles.}
}
\value{
A numeric vector with the adjustment variables re-coded into discrete
        levels respecting the minimum mass requested in each table comparing
        levels of the treatment against levels of an adjustment covariate.
}
\description{
Discretize continuous variables in the adjustment set (W) of a TMLE procedure
in order to avoid practical violations of the assumption of positivity.
Discretizes the numeric columns of an input matrix such that the newly
created levels of each variable individually contain at least a specified
mass when considering each level against levels of the treatment variable.
INTERNAL USE ONLY.
}
\keyword{internal}
