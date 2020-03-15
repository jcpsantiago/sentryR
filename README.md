[![Travis build status](https://travis-ci.org/ozean12/sentryR.svg?branch=master)](https://travis-ci.org/ozean12/sentryR)
[![Coverage status](https://codecov.io/gh/ozean12/sentryR/branch/master/graph/badge.svg)](https://codecov.io/github/ozean12/sentryR?branch=master)
[![CRAN status](https://www.r-pkg.org/badges/version/sentryR)](https://CRAN.R-project.org/package=sentryR)
[![Lifecycle: stable](https://img.shields.io/badge/lifecycle-stable-brightgreen.svg)](https://www.tidyverse.org/lifecycle/#stable)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

# sentryR <img src="man/figures/logo.png" align="right" width="200px"/>

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
optionally your app's name, version and the environment it's running in.
Both `configure_sentry` and any of the `capture_` functions accept 
additional fields to pass on to Sentry as named lists. 
`NULL`ifying a field will remove it.

```r
library(sentryR)

configure_sentry(dsn = Sys.getenv("SENTRY_DSN"),
                 app_name = "myapp", app_version = "8.8.8",
                 environment = Sys.getenv("APP_ENV"),
                 tags = list(foo = "tag1", bar = "tag2"),
                 runtime = NULL)

capture(message = "my message", level = "info")
```

You are encouraged to use the two wrappers around `capture` included:
`capture_exception`, which handles the error object and then reports the error
to Sentry, and `capture_message` for transmitting messages.
Refer to the [Sentry docs](https://docs.sentry.io/development/sdk-dev/event-payloads/)
for a full list of available fields.

By default `sentryR` will send the following fields to Sentry:
```r
list(
  logger = "R",
  platform = "R", # Sentry will ignore this for now
  sdk = list(
    name = "SentryR",
    version = ...
  ),
  contexts = list(
    os = list(
      name = ...,
      version = ...,
      kernel_version = ...
    ),
    runtime = list(
      version = ...,
      type = "runtime",
      name = "R",
      build = ...
    )
  ),
  timestamp = ...,
  event_id = ...
)
```

`capture_exception` further adds the `exception` field to the payload.


## Example with Plumber

In a Plumber API, besides the initial configuration for Sentry, 
you'll also have to set the error handler.

`sentryR` ships with the default `plumber` error handler wrapped
in the convenience function `sentry_error_handler`, but you can use
your own function and wrap it as below:

```r
library(plumber)
library(sentryR)

# add list of installed packages and their versions.
# this can be slow in systems with a high number of packages installed,
# so it is not the default behavior
installed_pkgs_df <- as.data.frame(utils::installed.packages(),
stringsAsFactors = FALSE
)
versions <- installed_pkgs_df$Version
names(versions) <- installed_pkgs_df$Package
packages <- as.list(versions)

configure_sentry(dsn = Sys.getenv('SENTRY_DSN'), 
                 app_name = "myapp", app_version = "1.0.0",
		 modules = packages)

my_sentry_error_handler <- wrap_error_handler_with_sentry(my_error_handler)

r <- plumb("R/api.R")
r$setErrorHandler(my_sentry_error_handler)
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

## Acknowledgements

`sentryR` took inspiration from
[raven-clj](https://github.com/sethtrain/raven-clj) a Clojure interface to Sentry.

## Contributing

PRs and issues are welcome! :tada:
