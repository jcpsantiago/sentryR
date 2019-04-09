context("test-sentry")

test_that("setting configuration works", {
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

  expect_equal(.sentry.header(), c("X-Sentry-Auth" = glue::glue("Sentry sentry_version=7,sentry_client=sentryR/{packageVersion('sentryR')},sentry_timestamp={as.integer(Sys.time())},sentry_key=1234")))

  # with the deprecated secret key
  .SentryEnv$secret_key <- "5678"
  expect_equal(.sentry.header(), c("X-Sentry-Auth" = glue::glue("Sentry sentry_version=7,sentry_client=sentryR/{packageVersion('sentryR')},sentry_timestamp={as.integer(Sys.time())},sentry_key=1234,sentry_secret=5678")))

  rm(list = ls(envir = .SentryEnv), envir = .SentryEnv)
})

test_that("captureException complains", {
  source(test_path("mocks.R"))

  with_mock(sentry.configured = not_configured, {
    expect_warning(sentry.captureException(error_nocalls, req))
  }, .env = "sentryR")

  rm(list = ls(envir = .SentryEnv), envir = .SentryEnv)
})

test_that("inform about Sentry responses", {
  source(test_path("mocks.R"))

  mockery::stub(sentry.captureException, "sentry.configured", TRUE)
  mockery::stub(sentry.captureException, "httr::POST", "foobar")
  mockery::stub(sentry.captureException, "httr::status_code", 200)

  expect_warning(sentry.captureException(error_nocalls, req),
                 "Error successfully sent to Sentry, check your project for more details.\n")

  mockery::stub(sentry.captureException, "httr::status_code", 400)
  mockery::stub(sentry.captureException, "httr::content", " error from sentry")
  expect_warning(sentry.captureException(error_nocalls, req),
                 paste("Error connecting to Sentry:",
                        "error from sentry"))


  rm(list = ls(envir = .SentryEnv), envir = .SentryEnv)
})

