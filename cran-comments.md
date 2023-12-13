# Round 1
## R CMD check results

0 errors | 0 warnings | 1 note

* This is an update to a package previously released, but then removed due to an unreachable maintainer email. The copyright has moved to a new owner (the main developer), and the email updated accordingly.

# Round 2
## Reviewer response
Thanks,

You have examples for unexported functions. Please either omit these 
examples or export these functions.
Used ::: in documentation:
      man/calls_to_stacktrace.Rd:
         sentryR:::calls_to_stacktrace(sys.calls())

Please fix and resubmit.

Best,
Benjamin Altmann

## Author response

Thank you for your time reviewing this application Benjamin, I appreciate the comments.
I have updated the documentation and examples to match your comments.

Best,
Joao Santiago
