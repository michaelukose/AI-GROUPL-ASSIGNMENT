param(
    [ValidateSet("run", "test")]
    [string] $Mode = "run",

    [string] $Scenario = ""
)

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
if ($Mode -eq "test") {
    & sbcl --script (Join-Path $projectRoot "tests\run-tests.lisp")
} else {
    if ($Scenario -ne "") {
        & sbcl --script (Join-Path $projectRoot "src\main.lisp") $Scenario
    } else {
        & sbcl --script (Join-Path $projectRoot "src\main.lisp")
    }
}
exit $LASTEXITCODE
