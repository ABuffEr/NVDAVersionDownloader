@echo off
title NVDA Version downloader
:: Author: Alberto Buffolino
:: Version: 4.1 (2022/11/05)
:: License: GPL V3
setlocal EnableDelayedExpansion
:: flag to enable debug
:: (no .htm deletion)
set debug=0
:: backup current codepage, and change it to 1252, more useful for translators
for /f "tokens=2 delims=:." %%a in ('chcp') do (
 set cp=%%a
)
chcp 1252>nul 2>&1
:: language management
if not exist "%~dp0\locales" (
 echo No language file, download the program again^^!
 pause
 goto :eof
)
if exist "%~dpn0.ini" (
	call :setLang
) else (
 call :initLang
)
for /f "usebackq tokens=1,2 delims==" %%a in ("%~dp0\locales\%lang%.ini") do (
 set %%a=%%b
)
:: verify downloader availability
wget --version>nul 2>nul
if %errorlevel% == 0 (
 set using=wget
 goto start
)
curl --version>nul 2>nul
if %errorlevel% == 0 (
 set using=curl
 goto start
)
powershell -command "echo Ok!">nul 2>nul
if %errorlevel% == 0 (
 set using=powershell
 goto start
) else (
 echo %downErrPt1%
 echo %downErrPt2%
 echo https://eternallybored.org/misc/wget/
 pause
 goto finish
)

:setLang
for /f "usebackq tokens=1,2 delims==" %%a in ("%~dpn0.ini") do (
 set %%a=%%b
)
goto :eof

:initLang
echo Choose language for this wizard (first time)
echo.
:langLoop
set langs=,
for /f "" %%a in ('dir "%~dp0\locales\*.ini" /b') do (
 set langs=!langs!, %%~na
)
set langs=!langs:~3!
set /p lang=Write code of your desired language (%langs%): 
set stop=1
for %%a in (%langs%) do (
 if %lang% == %%a set stop=0
)
if %stop% == 1 (
 echo %lang% is not a valid choice, please retry.
 goto langLoop
) else (
 echo lang=%lang%>"%~dpn0.ini"
)
goto :eof

:start
echo %usingMsg%
echo %getVerMsg%
set snapURL="https://www.nvaccess.org/files/nvda/snapshots/"
set snapPage="%~dp0\NVDASnapshotsPage.htm"
if %using% == wget (
 wget -q %snapURL% -O %snapPage%
 set downloader=wget -q --show-progress -c -N
)
if %using% == curl (
 curl --retry 2 -s %snapURL% -o %snapPage%
 set downloader=curl --retry 2 --ssl -O -L -# -C -
)
if %using% == powershell (
 powershell -command "(New-Object System.Net.WebClient).DownloadFile('%snapURL%', '%snapPage%')"
 set downloader=call :psget
)
call :checkSnapPage %snapPage%
if %errorlevel% equ 1 goto finish
set choices=,
for /f "usebackq tokens=2 delims=<>" %%a in (`findstr "<h2>" %snapPage%`) do (
 set choices=!choices!, %%a
)
findstr /r "_[0-9.]*rc[0-9]*" %snapPage%>nul 2>nul
if %errorlevel% == 0 (
 set choices=!choices!, rc
)
set choices=!choices!, stable
set choices=!choices:~3!
set /p snapshot=%snapAsk% (%choices%): 
set stop=1
for %%a in (%choices%) do (
 if %snapshot% == %%a set stop=0
)
if %stop% == 1 (
 echo %snapWarn%
 pause
 goto finish
)
:: manage stable releases
if %snapshot% == stable (
 call :askStable
 goto finish
)
:: manage other branches
for /f "usebackq tokens=4 delims==" %%a in (`findstr /r "_%snapshot% _[0-9.]*%snapshot%" %snapPage%`) do (
 set line=%%a
 set fileURL=!line:~0,-6!
 call :confirmBranch !fileURL!
 goto finish
)

:checkSnapPage
set stop=0
if not exist %snapPage% (
 set stop=1
)
:: snapPage is <= 1KB (site down?)
if "%~z1" leq "1" (
 set stop=1
)
if %stop% equ 1 (
 echo %errVerMsg%
 pause
)
exit /b %stop%

:askStable
set /p veranswer=%stableAsk% 
set fileURL="https://www.nvaccess.org/download/nvda/releases/%veranswer%/nvda_%veranswer%.exe"
set /p answer=%stableWarn% (%yes%/%no%): 
call :yesNoAnswers %answer%
goto :eof

:confirmBranch
set vertokens=0
set verstring=%~n1
:tokenLoop
for /f "tokens=1* delims=_" %%a in ("%verstring%") do (
 set /a vertokens+=1
 set verstring=%%b
 goto tokenLoop
)
for /f "tokens=%vertokens%* delims=_" %%a in ("%~n1") do (
 set version=%%a%%b
)
echo %lastVerMsg%
set /p answer=%downAsk% (%yes%/%no%): 
call :yesNoAnswers %answer%
goto :eof

:yesNoAnswers
if %answer% == %yes% goto download
if %answer% == %no% (
 echo %byeMsg%
 pause
)
goto :eof

:download
echo %downMsg%
if %using% == powershell (
 echo %psWarn%
)
%downloader% !fileURL!
:: last in next line is bell char
echo %doneMsg% 
pause
goto :eof

:psget
powershell -command "(New-Object System.Net.WebClient).DownloadFile('%1', '%~dp0%~nx1')"
goto :eof

:finish
chcp %cp%>nul 2>&1
if %debug% == 0 (
 del %snapPage%>nul 2>&1
)
