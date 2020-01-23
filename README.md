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
```json
{
   "logger":[
      "R"
   ],
   "platform":[
      "R"
   ],
   "sdk":{
      "name":[
         "SentryR"
      ],
      "version":[
         "1.0.0"
      ]
   },
   "contexts":{
      "os":{
         "name":[
            "Darwin"
         ],
         "version":[
            "19.2.0"
         ],
         "kernel_version":[
            "Darwin Kernel Version 19.2.0: Sat Nov  9 03:47:04 PST 2019; root:xnu-6153.61.1~20/RELEASE_X86_64"
         ]
      },
      "runtime":{
         "version":[
            "3.6.1"
         ],
         "type":[
            "runtime"
         ],
         "name":[
            "R"
         ],
         "build":[
            "R version 3.6.1 (2019-07-05)"
         ]
      }
   },
   "timestamp":[
      "2020-01-23T17:41:56Z"
   ],
   "event_id":[
      "768451143e0711eab7b6a683e743921a"
   ],
   "modules":{
      "assertthat":[
         "0.2.1"
    ], ...
  }
}
```

`capture_exception` further adds the `exception` field to the payload.


## Example with Plumber

In a Plumber API, besides the initial configuration for Sentry, 
you'll also have to set the error handler to `sentry_error_handler`

```r
library(plumber)
library(sentryR)

configure_sentry(dsn = Sys.getenv('SENTRY_DSN'), 
                 app_name = "myapp", app_version = "1.0.0")

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

## Ackknowledgements

`sentryR` uses code from [Plumber](https://github.com/rstudio/plumber)
and [Sentry](https://github.com/rstudio/shiny/) and took inspiration from
[raven-clj](https://github.com/sethtrain/raven-clj) a Clojure interface to Sentry.

## Contributing

PRs and issues are welcome! :tada:
