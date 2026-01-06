@echo off
setlocal EnableDelayedExpansion
cls

echo ~~~~~~~~~~~~~~~~~~~~~~~~ >> ".txt"
echo   Time Checker Software  >> ".txt"
echo ~~~~~~~~~~~~~~~~~~~~~~~~ >> ".txt"
echo.
echo By using this software, you agree that this is a time-checking utility. >> ".txt"
echo.

set /p choice="Do you agree? Enter 1 for yes, 2 for no: "

if "%choice%"=="2" (
    echo Exiting program.
    exit /b
)

if not "%choice%"=="1" (
    echo Invalid choice.
    exit /b
)

set total=0
set typeTotal=0

call :StartTask
goto :EOF

:: --------------------------------------------------
:: Start a task
:: --------------------------------------------------
:StartTask
call :GetTimeSeconds begin
echo.
echo Task started at %TIME% >> ".txt"

call :timeGate "End your task?" TaskEnd StartTask
exit /b

:: --------------------------------------------------
:: Decision gate (yes/no → jump)
:: Params:
::   %1 = prompt text
::   %2 = yes-label
::   %3 = no-label
:: --------------------------------------------------
:timeGate
setlocal EnableDelayedExpansion
set "TEXT=%~1"
set "YES=%~2"
set "NO=%~3"

:timeGate_prompt
set /p choice="%TEXT% (1 = yes, 2 = no): "

if "!choice!"=="1" (
    endlocal
    goto %YES%
) else if "!choice!"=="2" (
    endlocal
    goto %NO%
) else (
    echo Invalid choice. Please try again.
    goto timeGate_prompt
)

:: --------------------------------------------------
:: End current task
:: --------------------------------------------------
:TaskEnd
call :GetTimeSeconds end
set /a elapsed=end-begin
if %elapsed% lss 0 set /a elapsed+=86400

set /a total+=elapsed

echo.
echo Task ended at %TIME% >> ".txt"
echo Time spent on task: %elapsed% seconds >> ".txt"
goto Reason

:: --------------------------------------------------
:: Reason entry loop
:: --------------------------------------------------
:Reason
echo.
set /p "REASON=What did you work on? (type EXIT to finish): "

if /i "%REASON%"=="EXIT" goto Summary

call :GetTimeSeconds typing
set /a typeTotal+=typing

echo "Recorded at %TIME%: %REASON%" >> ".txt"
goto Reason

:: --------------------------------------------------
:: Summary
:: --------------------------------------------------
:Summary
echo.
echo ======================== >> ".txt"
echo Total task time   : %total% seconds >> ".txt"
echo Time typing notes : %typeTotal% seconds >> ".txt"
echo ======================== >> ".txt"
pause
exit /b

:: --------------------------------------------------
:: Utility: Get current time in seconds
:: Usage:
::   call :GetTimeSeconds varName
:: --------------------------------------------------
:GetTimeSeconds
set "t=%TIME%"
set "t=%t: =0%"
set /a %1=(%t:~0,2%*3600)+(%t:~3,2%*60)+%t:~6,2%
exit /b
