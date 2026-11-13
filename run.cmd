@echo off
setlocal
set "SCRIPT_DIR=%~dp0"

if "%~1"=="" (
    sbcl --script "%SCRIPT_DIR%src\main.lisp"
) else if /i "%~1"=="test" (
    sbcl --script "%SCRIPT_DIR%tests\run-tests.lisp"
) else (
    sbcl --script "%SCRIPT_DIR%src\main.lisp" %*
)

exit /b %ERRORLEVEL%
