context("test-sentry")

test_that("parsing the dsn works", {
  expect_error(parse_dsn(888))

  test_dsn <- "https://1234@sentry.io"
  expect_error(
    parse_dsn(test_dsn),
    paste0(
      "Invalid DSN! Expected format is 'https://<public_key>@<host>/<project_id>' but received ",
      "'https://1234@sentry\\.io' instead\\."
    )
  )

  test_dsn <- "https://1234@sentry.io/"
  expect_error(
    parse_dsn(test_dsn),
    paste0(
      "Expected fields 'https://<public_key>@<host>/<project_id>', ",
      "but can't find project_id in 'https://1234@sentry\\.io/'",
      "\\. Please check your DSN\\."
    )
  )

  test_dsn <- "https://1234@sentry.io/1"
  expect_equal(
    names(parse_dsn(test_dsn)),
    c("dsn", "protocol", "public_key", "ignore", "secret_key", "host", "project_id")
  )
  expect_equal(
    parse_dsn(test_dsn),
    list(
      dsn = test_dsn, protocol = "https", public_key = "1234",
      ignore = NA_character_, secret_key = NA_character_,
      host = "sentry.io", project_id = "1"
    )
  )
})

test_that("setting configuration works", {
  expect_error(configure_sentry(42))
  expect_error(configure_sentry(c("https://1234@sentry.io/1", "https://1234@sentry.io/2")))

  configure_sentry(dsn = "https://1234@sentry.io/1",
                   app_name = "el appo", app_version = "8.8.8",
                   environment = "production")

  expect_equal(.sentry_env$payload_skeleton$contexts$app$app_name, "el appo")
  expect_equal(.sentry_env$payload_skeleton$contexts$app$app_version, "8.8.8")
  expect_equal(.sentry_env$payload_skeleton$environment, "production")
  expect_equal(.sentry_env$dsn, "https://1234@sentry.io/1")
  expect_equal(.sentry_env$protocol, "https")
  expect_equal(.sentry_env$public_key, "1234")
  expect_equal(.sentry_env$ignore, NA_character_)
  expect_equal(.sentry_env$secret_key, NA_character_)
  expect_equal(.sentry_env$host, "sentry.io")
  expect_equal(.sentry_env$project_id, "1")

  rm(list = ls(envir = .sentry_env), envir = .sentry_env)

})

test_that("builds payload correctly", {
  expect_error(prepare_payload(message = "foo", "bar"))

  expect_match(
    prepare_payload(message = "foo", level = "info"),
    '\\{.*,"message":"foo","level":"info"\\}'
  )
})

test_that("configuration is properly set", {
  expect_message(
    is_sentry_configured(),
    "Expected public_key, host and project_id to be present but can't find public_key, host, project_id\\."
  )
  expect_false(is_sentry_configured())

  .sentry_env$public_key <- "1234"
  .sentry_env$host <- "sentry.io"

  expect_message(
    is_sentry_configured(),
    "Expected public_key, host and project_id to be present but can't find project_id\\."
  )
  expect_false(is_sentry_configured())


  .sentry_env$project_id <- "1"

  expect_true(is_sentry_configured())

  rm(list = ls(envir = .sentry_env), envir = .sentry_env)


  configure_sentry("https://1234@sentry.io/1")

  fields <- sapply(
    c(
      "dsn", "protocol", "public_key", "ignore",
      "secret_key", "host", "project_id"
    ),
    function(x) exists(x, envir = .sentry_env)
  )

  expect_true(all(fields))

  rm(list = ls(envir = .sentry_env), envir = .sentry_env)
})

test_that("we build the correct sentry.io call url", {
  .sentry_env$protocol <- "https"
  .sentry_env$host <- "sentry.io"
  .sentry_env$project_id <- "1"

  expect_equal(sentry_url(), "https://sentry.io/api/1/store/")

  rm(list = ls(envir = .sentry_env), envir = .sentry_env)
})

test_that("we build the correct headers", {
  # without deprecated secret key
  .sentry_env$public_key <- "1234"
  .sentry_env$secret_key <- NA
  .sentry_env$pkg_version <- "8.8.8"

  expect_match(
    sentry_headers()[[1]],
    "Sentry sentry_version=7,sentry_client=sentryR/.*,sentry_timestamp=.*sentry_key=1234"
  )

  # with the deprecated secret key
  .sentry_env$secret_key <- "5678"
  expect_match(
    sentry_headers()[[1]],
    "Sentry sentry_version=7,sentry_client=sentryR/.*,sentry_timestamp=.*sentry_key=1234,sentry_secret=5678"
  )

  rm(list = ls(envir = .sentry_env), envir = .sentry_env)
})
