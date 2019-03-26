[![Travis build status](https://travis-ci.org/ozean12/sentryR.svg?branch=master)](https://travis-ci.org/ozean12/sentryR)
[![Coverage status](https://codecov.io/gh/ozean12/sentryR/branch/master/graph/badge.svg)](https://codecov.io/github/ozean12/sentryR?branch=master)
[![lifecycle](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://www.tidyverse.org/lifecycle/#experimental)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)


# sentryR

Connect your APIs to [Sentry](https://sentry.io) and get stacktraces, analyze
the payloads.


## Installation
You can install the current development version of `sentryR` with:

``` r
# install.packages("devtools")
devtools::install_github("ozean12/sentryR")
```

## Example

Configure your project in Sentry and set its DSN as an environment variable.

Example Plumber API:
```r
library(plumber)
library(sentryR)

sentry.config(Sys.getenv('SENTRY_DSN'))

defaultErrorHandler <- plumber:::defaultErrorHandler()

errorHandler <- function(req, res, err) {
  sentry.captureException(err, req)
  defaultErrorHandler(req, res, err)
}

r <- plumb("R/api.R")
r$setErrorHandler(errorHandler)
r$run(host = "0.0.0.0", port = 8000)
```

also wrap your functions with `withCapturedCalls` and you're good to go!
```r
#* @get /error
api.error <- withCapturedCalls(function(res, req){
  stop("error")
})
```
