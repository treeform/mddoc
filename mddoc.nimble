version       = "0.1.0"
author        = "Andre von Houck"
description   = "Generate Nim API docs in markdown for GitHub's README.md files."
license       = "MIT"
srcDir        = "src"

bin = @["mddoc"]

requires "nim >= 1.4.0"
