context("test-sentry")

test_that("parsing the dsn works", {
  expect_error(parse_dsn(888))

  test_dsn <- "https://1234@sentry.io"
  expect_error(parse_dsn(test_dsn),
               paste0("Invalid DSN! Expected format is 'https://<public_key>@<host>/<project_id>' but received ",
                      "'https://1234@sentry\\.io' instead\\."))

  test_dsn <- "https://1234@sentry.io/"
  expect_error(parse_dsn(test_dsn),
               paste0("Expected fields 'https://<public_key>@<host>/<project_id>', ",
                      "but can't find project_id in 'https://1234@sentry\\.io/'",
                      "\\. Please check your DSN\\."))

  test_dsn <- "https://1234@sentry.io/1"
  expect_equal(
    names(parse_dsn(test_dsn)),
    c("dsn", "protocol", "public_key", "ignore", "secret_key", "host", "project_id")
  )
  expect_equal(parse_dsn(test_dsn),
               list(dsn = test_dsn, protocol = "https", public_key = "1234",
                    ignore = NA_character_, secret_key = NA_character_,
                    host = "sentry.io", project_id = "1")
               )
})

test_that("setting configuration works", {
  expect_error(configure_sentry(42))
  expect_error(configure_sentry(c("https://1234@sentry.io/1", "https://1234@sentry.io/2")))
})

test_that("builds payload correctly", {
  expect_error(prepare_payload(message = "foo", "bar"))

  expect_match(
    prepare_payload(message = "foo", level = "info"),
    '\\{"timestamp":.*,"logger":"R","platform":"R","sdk":\\{"name":"SentryR","version":.*\\},"event_id":.*,"message":"foo","level":"info"\\}'
  )
})

test_that("configuration is properly set", {

  expect_message(is_sentry_configured(),
                 "Expected public_key, host and project_id to be present but can't find public_key, host, project_id\\.")
  expect_false(is_sentry_configured())

  sentry_env$public_key <- "1234"
  sentry_env$host <- "sentry.io"

  expect_message(is_sentry_configured(),
                 "Expected public_key, host and project_id to be present but can't find project_id\\.")
  expect_false(is_sentry_configured())


  sentry_env$project_id <- "1"

  expect_true(is_sentry_configured())

  rm(list = ls(envir = sentry_env), envir = sentry_env)


  configure_sentry("https://1234@sentry.io/1")

  fields <- sapply(
    c("dsn", "protocol", "public_key", "ignore",
      "secret_key", "host", "project_id"),
    function(x) exists(x, envir = sentry_env))

  expect_true(all(fields))

  rm(list = ls(envir = sentry_env), envir = sentry_env)
})

test_that("we build the correct response url", {
  sentry_env$protocol <- "https"
  sentry_env$host <- "sentry.io"
  sentry_env$project_id <- "1"

  expect_equal(sentry_url(), "https://sentry.io/api/1/store/")

  rm(list = ls(envir = sentry_env), envir = sentry_env)
})

test_that("we build the correct headers", {
  # without deprecated secret key
  sentry_env$public_key <- "1234"
  sentry_env$secret_key <- NA

  expect_equal(sentry_headers(),
               c("X-Sentry-Auth" = glue::glue("Sentry sentry_version=7,sentry_client=sentryR/{packageVersion('sentryR')},sentry_timestamp={as.integer(Sys.time())},sentry_key=1234")))

  # with the deprecated secret key
  sentry_env$secret_key <- "5678"
  expect_equal(sentry_headers(),
               c("X-Sentry-Auth" = glue::glue("Sentry sentry_version=7,sentry_client=sentryR/{packageVersion('sentryR')},sentry_timestamp={as.integer(Sys.time())},sentry_key=1234,sentry_secret=5678")))

  rm(list = ls(envir = sentry_env), envir = sentry_env)
})

test_that("captureException complains", {
  source(test_path("mocks.R"))

  with_mock(is_sentry_configured = not_configured, {
    expect_warning(sentry.captureException(error_nocalls, req))
  }, .env = "sentryR")

  rm(list = ls(envir = sentry_env), envir = sentry_env)
})

test_that("inform about Sentry responses", {
  source(test_path("mocks.R"))

  mockery::stub(sentry.captureException, "is_sentry_configured", TRUE)
  mockery::stub(sentry.captureException, "httr::POST", "foobar")
  mockery::stub(sentry.captureException, "httr::status_code", 200)

  expect_message(sentry.captureException(error_nocalls, req),
                 "Error successfully sent to Sentry, check your project for more details.\n")

  mockery::stub(sentry.captureException, "httr::status_code", 400)
  mockery::stub(sentry.captureException, "httr::content", " error from sentry")
  expect_warning(sentry.captureException(error_nocalls, req),
                 paste("Error connecting to Sentry:",
                       "error from sentry"))


  rm(list = ls(envir = sentry_env), envir = sentry_env)
})

