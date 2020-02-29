# Round 1
## Test environments
- R-hub windows-x86_64-devel (r-devel)
- R-hub ubuntu-gcc-release (r-release)
- R-hub fedora-clang-devel (r-devel)

## R CMD check results
> On windows-x86_64-devel (r-devel), ubuntu-gcc-release (r-release)
  checking CRAN incoming feasibility ... NOTE
  Maintainer: 'Joao Santiago <santiago@billie.io>'
  New submission
  
  
  License components with restrictions and base license permitting such:
    MIT + file LICENSE
    
    Copyright (c) 2020 Billie GmbH
    
    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:
    
    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.
    
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
  File 'LICENSE':
    MIT License

> On fedora-clang-devel (r-devel)
  checking CRAN incoming feasibility ...NB: need Internet access to use CRAN incoming checks
   NOTE
  Maintainer: ‘Joao Santiago <santiago@billie.io>’
  
  License components with restrictions and base license permitting such:
    MIT + file LICENSE
  File 'LICENSE':
    MIT License
    
    Copyright (c) 2019 Billie GmbH
    
    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:
    
    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.
    
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.

0 errors ✓ | 0 warnings ✓ | 2 notes x

* This is a new release.

# Round 2
## Reviewer comments

2020-02-28 Jelena Saf

```
The Description field is intended to be a (one paragraph) description of what the package does and why it may be useful. Please elaborate.

Please always write non-English usage, package names, software names and API names in single quotes in title and description. e.g: --> 'Sentry'

Thanks, we see you are using installed.packages() in your code.
F.i.: core.R
As mentioned in the notes of installed.packages() help page, this can be very slow:
    "This can be slow when thousands of packages are installed, so do not use this to find out if a named package is installed (use system.file or find.package) nor to find out if a package is usable (call require and check the return value) nor to find details of a small number of packages (use packageDescription). It needs to read several files per installed package, which will be slow on Windows and on some network-mounted file systems." [installed.packages() help page]
    If possible please adapt your code accordingly.

You have an example for an unexported function which cannot run in this way.
Please either add sentryR::: to the function call in the example, omit the example or export the function.
See: calls_to_stacktrace.R

Please fix and resubmit, and document what was changed in the submission comments.
```

## Submission comments

2020-02-29

Thank you Jelena for the comments and taking the time to review sentryR.

I expanded the description and used '' where necessary.

Regarding the use of installed.packages(): the sentry.io cloud service attaches
the runtime environment with each error report, which ideally includes a list
of packages and their versions. This is useful to debug problems.
The lack of this functionality is not necessary for sentryR to run, but it
reduces its usefuleness, and reduces the features available in comparison to
clients written in other languages such as python or javascript.

As a final argument for the inclusion of this function, I would argue the
use-case for this package are Plumber APIs or long running jobs in interactive mode,
both of which don't usually have such a high number of packages.
I understand that is the case at CRAN though.

If the reviewer doesn't agree with the inclusion of the installed.packages()
function, I would appreciate a suggestion for an alternative.
This is my first CRAN submission.


