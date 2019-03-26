context("test-sentry")

test_that("setting configuration works", {
  expect_error(sentry.config(""))
  expect_error(sentry.config("http://www.purple.com"))
})

test_that("configuration is properly set", {

  expect_false(sentry.configured())

  .SentryEnv$public_key <- "1234"
  .SentryEnv$host <- "sentry.io"
  .SentryEnv$project_id <- "1"

  expect_true(sentry.configured())

  rm(list = ls(envir = .SentryEnv), envir = .SentryEnv)

  sentry.config("https://1234@sentry.io/1")

  fields <- purrr::map_lgl(
    c("dsn", "protocol", "public_key", "ignore",
      "secret_key", "host", "project_id"),
    ~exists(., envir = .SentryEnv))

  expect_true(all(fields))

  rm(list = ls(envir = .SentryEnv), envir = .SentryEnv)
})

test_that("we build the correct response url", {
  .SentryEnv$protocol <- "https"
  .SentryEnv$host <- "sentry.io"
  .SentryEnv$project_id <- "1"

  expect_equal(.sentry.url(), "https://sentry.io/api/1/store/")

  rm(list = ls(envir = .SentryEnv), envir = .SentryEnv)
})

test_that("we build the correct headers", {
  # without deprecated secret key
  .SentryEnv$public_key <- "1234"
  .SentryEnv$secret_key <- NA

  expect_equal(.sentry.header(), c("X-Sentry-Auth" = glue::glue("Sentry sentry_version=7,
                                   sentry_client=sentryR/{packageVersion('sentryR')},
                                   sentry_timestamp={as.integer(Sys.time())},
                                   sentry_key=1234")))

  # with the deprecated secret key
  .SentryEnv$secret_key <- "5678"
  expect_equal(.sentry.header(), c("X-Sentry-Auth" = glue::glue("Sentry sentry_version=7,
                                   sentry_client=sentryR/{packageVersion('sentryR')},
                                   sentry_timestamp={as.integer(Sys.time())},
                                   sentry_key=1234,
                                   sentry_secret=5678")))

  rm(list = ls(envir = .SentryEnv), envir = .SentryEnv)
})

test_that("payload is built", {

  req <- new.env()
  req$postBody <- "{a: 123}"
  req$PATH_INFO <- "/endpoint"
  req$REQUEST_METHOD <- "POST"
  req$HTTP_CONTENT_TYPE <- "application/json"
  req$HTTP_HOST <- "127.0.0.1"

  error <- "simple.error"

  .SentryEnv$public_key <- "1234"
  .SentryEnv$host <- "sentry.io"
  .SentryEnv$project_id <- "1"

  not_configured <- mockery::mock(FALSE)

  with_mock(sentry.configured = not_configured, {
    expect_message(sentry.captureException(error, req))
  }, .env = "sentryR")
})

