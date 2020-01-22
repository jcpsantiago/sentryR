[![Travis build status](https://travis-ci.org/ozean12/sentryR.svg?branch=master)](https://travis-ci.org/ozean12/sentryR)
[![Coverage status](https://codecov.io/gh/ozean12/sentryR/branch/master/graph/badge.svg)](https://codecov.io/github/ozean12/sentryR?branch=master)
[![lifecycle](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://www.tidyverse.org/lifecycle/#experimental)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

# sentryR <img src="man/figures/logo.png" align="right" width="180px"/>

`sentryR` is an unofficial R SDK for [Sentry](https://sentry.io).
It includes an error handler for Plumber for uncaught exceptions.

## Installation
You can install the current development version of `sentryR` with:

``` r
# install.packages("remotes")
remotes::install_github("ozean12/sentryR")
```

## Using sentryR

`configure_sentry` and `capture` are the two core functions of `sentryR`.
The first sets up an isolated environment with your Sentry project's DSN,
optionally your app's name, version and the environment it's running in,
and any additional fields you want to pass on to Sentry as named lists:

```r
library(sentryR)

configure_sentry(dsn = Sys.getenv("SENTRY_DSN"),
                 appname = "myapp", appversion = "8.8.8",
                 environment = Sys.getenv("APP_ENV"),
                 tags = list(foo = "tag1", bar = "tag2"),
                 runtime = NULL)

capture(message = "my message", .level = "info")
```

while the latter builds the payload and sends it to Sentry.

The package includes two wrappers around `capture` for convenience:
`capture_exception` and `capture_message`.


## Example with Plumber

In a Plumber API, besides the initial configuration for Sentry, 
you'll also have to set the error handler to `sentry_error_handler`

```r
library(plumber)
library(sentryR)

configure_sentry(dsn = Sys.getenv('SENTRY_DSN'), 
                 appname = "myapp", appversion = "1.0.0")

r <- plumb("R/api.R")
r$setErrorHandler(sentry_error_handler)
r$run(host = "0.0.0.0", port = 8000)
```

and wrap your endpoint functions with `with_captured_calls`

```r
#* @get /error
api_error <- with_captured_calls(function(res, req){
  stop("error")
})
```

once this is done, Plumber will handle any errors, send them to Sentry using
`capture_exception`, and respond with status `500` and the error message.
You don't need to do any further configuration.

## Contributing

PRs and issues are welcome! :tada:
