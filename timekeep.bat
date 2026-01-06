@echo off
setlocal EnableDelayedExpansion
cls

:: --- Log file ---
set "LOGFILE=.txt"

echo ~~~~~~~~~~~~~~~~~~~~~~~~ >> "%LOGFILE%"
echo   Time Checker Software  >> "%LOGFILE%"
echo ~~~~~~~~~~~~~~~~~~~~~~~~ >> "%LOGFILE%"
echo. >> "%LOGFILE%"
echo By using this software, you agree that this is a time-checking utility.
echo. >> "%LOGFILE%"

:: --- Agreement ---
set /p choice="Do you agree? Enter 1 for yes, 2 for no: "

if "%choice%"=="2" (
    echo Exiting program.
    exit /b
)

if not "%choice%"=="1" (
    echo Invalid choice.
    exit /b
)

:: --- Initialize totals ---
set total=0
set typeTotal=0
set reasonCount=0

call :StartTask
goto :EOF

:: --------------------------------------------------
:: Start a task
:: --------------------------------------------------
:StartTask
call :GetTimeSeconds begin
echo.
echo Task started at %TIME% >> "%LOGFILE%"

call :timeGate "End your task?" TaskEnd StartTask
exit /b

:: --------------------------------------------------
:: Decision gate (yes/no → jump)
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

:: Store current task time for this session
set currentTaskTime=%elapsed%

echo.
echo Task ended at %TIME% >> "%LOGFILE%"
echo Time spent on task: %elapsed% seconds >> "%LOGFILE%"

goto Reason

:: --------------------------------------------------
:: Reason entry loop
:: --------------------------------------------------
:Reason
echo.
call :GetTimeSeconds typeStart
set /p "REASON=What did you work on? (type EXIT to finish): "
call :GetTimeSeconds typeEnd

if /i "%REASON%"=="EXIT" goto Summary

:: --- Calculate typing elapsed time ---
set /a typeElapsed=typeEnd-typeStart
if %typeElapsed% lss 0 set /a typeElapsed+=86400
set /a typeTotal+=typeElapsed

:: --- Store reason with its times ---
set /a reasonCount+=1
set "reason[%reasonCount%]=%REASON%"
set /a "reasonTaskTime[%reasonCount%]=%currentTaskTime%"
set /a "reasonTypeTime[%reasonCount%]=%typeElapsed%"

echo Recorded at %TIME%: %REASON% >> "%LOGFILE%"

call :timeGate "Want to start a new task?" StartTask Summary

:: --------------------------------------------------
:: Summary
:: --------------------------------------------------
:Summary
set /a totalTime=total+typeTotal
set /a precision=10000

:: --- Calculate hours with 4 decimal places ---
:: Multiply by 10000 to preserve 4 decimals
set /a taskHrsScaled=total*precision/3600
set /a typeHrsScaled=typeTotal*precision/3600
set /a totalHrsScaled=totalTime*precision/3600

:: Extract integer and fractional parts
set /a taskHrsInt=taskHrsScaled/precision
set /a taskHrsFrac=taskHrsScaled%%precision

set /a typeHrsInt=typeHrsScaled/precision
set /a typeHrsFrac=typeHrsScaled%%precision

set /a totalHrsInt=totalHrsScaled/precision
set /a totalHrsFrac=totalHrsScaled%%precision

:: --- Pad fractional parts with leading zeros to 4 digits ---
set "taskHrsFracStr=000%taskHrsFrac%"
set "taskHrsFracStr=%taskHrsFracStr:~-4%"

set "typeHrsFracStr=000%typeHrsFrac%"
set "typeHrsFracStr=%typeHrsFracStr:~-4%"

set "totalHrsFracStr=000%totalHrsFrac%"
set "totalHrsFracStr=%totalHrsFracStr:~-4%"

echo. >> "%LOGFILE%"
echo ======================== >> "%LOGFILE%"
echo BREAKDOWN BY REASON >> "%LOGFILE%"
echo ======================== >> "%LOGFILE%"

:: --- Display each reason with its times ---
for /l %%i in (1,1,%reasonCount%) do (
    set /a reasonTaskSec=!reasonTaskTime[%%i]!
    set /a reasonTypeSec=!reasonTypeTime[%%i]!
    set /a reasonTotalSec=reasonTaskSec+reasonTypeSec
    
    :: Calculate hours for each reason
    set /a reasonTaskHrsScaled=reasonTaskSec*precision/3600
    set /a reasonTypeHrsScaled=reasonTypeSec*precision/3600
    set /a reasonTotalHrsScaled=reasonTotalSec*precision/3600
    
    set /a reasonTaskHrsInt=reasonTaskHrsScaled/precision
    set /a reasonTaskHrsFrac=reasonTaskHrsScaled%%precision
    set "reasonTaskHrsFracStr=000!reasonTaskHrsFrac!"
    set "reasonTaskHrsFracStr=!reasonTaskHrsFracStr:~-4!"
    
    set /a reasonTypeHrsInt=reasonTypeHrsScaled/precision
    set /a reasonTypeHrsFrac=reasonTypeHrsScaled%%precision
    set "reasonTypeHrsFracStr=000!reasonTypeHrsFrac!"
    set "reasonTypeHrsFracStr=!reasonTypeHrsFracStr:~-4!"
    
    set /a reasonTotalHrsInt=reasonTotalHrsScaled/precision
    set /a reasonTotalHrsFrac=reasonTotalHrsScaled%%precision
    set "reasonTotalHrsFracStr=000!reasonTotalHrsFrac!"
    set "reasonTotalHrsFracStr=!reasonTotalHrsFracStr:~-4!"
    
    echo. >> "%LOGFILE%"
    echo Reason: !reason[%%i]! >> "%LOGFILE%"
    echo   Task time: !reasonTaskSec! sec ^(!reasonTaskHrsInt!.!reasonTaskHrsFracStr! hrs^) >> "%LOGFILE%"
    echo   Type time: !reasonTypeSec! sec ^(!reasonTypeHrsInt!.!reasonTypeHrsFracStr! hrs^) >> "%LOGFILE%"
    echo   Total: !reasonTotalSec! sec ^(!reasonTotalHrsInt!.!reasonTotalHrsFracStr! hrs^) >> "%LOGFILE%"
)

echo. >> "%LOGFILE%"
echo ======================== >> "%LOGFILE%"
echo OVERALL LABOR TOTALS >> "%LOGFILE%"
echo ======================== >> "%LOGFILE%"
echo Total task time   : %total% seconds ^(!taskHrsInt!.!taskHrsFracStr! hrs^)>> "%LOGFILE%"
echo Time typing notes : %typeTotal% seconds ^(!typeHrsInt!.!typeHrsFracStr! hrs^)>> "%LOGFILE%"
echo Total time including notes : %totalTime% seconds ^(!totalHrsInt!.!totalHrsFracStr! hrs^)>> "%LOGFILE%"
echo ======================== >> "%LOGFILE%"
goto FilePush


:: --------------------------------------------------
:: Utility: Get current time in seconds since midnight
:: Handles decimal seconds and leading zeros
:: Usage: call :GetTimeSeconds varName
:: --------------------------------------------------
:GetTimeSeconds
set "t=%TIME%"
set "t=%t: =0%"           :: pad single-digit hours

set "hh=%t:~0,2%"
set "mm=%t:~3,2%"
set "ss=%t:~6,2%"         :: integer seconds only

:: Remove leading zeros safely for set /a
set /a %1=(1%hh%-100)*3600 + (1%mm%-100)*60 + (1%ss%-100)
exit /b


:: --------------------------------------------------
:: Save log to timestamped file and reset log
:: --------------------------------------------------
:FilePush
:: Get date and time components
for /f "tokens=1-3 delims=/- " %%a in ("%DATE%") do (
    set "yy=%%c"
    set "mm=%%a"
    set "dd=%%b"
)

:: Remove spaces and decimals from time
set "hh=%TIME:~0,2%"
set "hh=%hh: =0%"
set "min=%TIME:~3,2%"
set "sec=%TIME:~6,2%"

:: Build timestamped filename
set "NEWFILE=labor-%yy%%mm%%dd%%hh%%min%%sec%.txt"

:: Copy current log to new file
copy "%LOGFILE%" "%NEWFILE%" >nul

:: Clear current log for reuse
> "%LOGFILE%" echo.

echo.
echo Log saved as %NEWFILE%
echo Ready for next session.
exit /b
