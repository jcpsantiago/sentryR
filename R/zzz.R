# sentryR uses an environment to track state within the package
# plays well with the glue package too
.SentryEnv <- new.env()

# shut up R CMD check
globalVariables(".")
