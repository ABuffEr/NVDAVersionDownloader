@echo off
title NVDA snapshot downloader
:: Author: Alberto buffolino
:: License: GPL V3
setlocal enabledelayedexpansion
wget --version>nul 2>nul
if %errorlevel% == 0 (
 set using=wget
 goto download
)
curl --version>nul 2>nul
if %errorlevel% == 0 (
 set using=curl
 goto download
)
powershell -command "echo Present!">nul 2>nul
if %errorlevel% == 0 (
 set using=powershell
 goto download
) else (
 echo ERROR: download not possible,
 echo install curl or wget, i.e. from:
 echo https://eternallybored.org/misc/wget/
 pause
 goto :eof
)

:download
echo Using %using%
echo Getting version info...
set pageURL=https://www.nvaccess.org/files/nvda/snapshots/
set pageFile=%tmp%\NVDASnapshotsPage.htm
if %using% == wget (
 wget -q %pageURL% -O %pageFile%
 set downloader=wget -q --show-progress -c -N
)
if %using% == curl (
 curl --retry 2 -s %pageURL% -o %pageFile%
 set downloader=curl --retry 2 --ssl -O -L -# -C -
)
if %using% == powershell (
 powershell -command "(New-Object System.Net.WebClient).DownloadFile('%pageURL%', '%pageFile%')"
 set downloader=call :psget
)

if not exist %pageFile% (
 echo Error getting version info, please retry again later.
 pause
 goto :eof
)

echo.
set /p snapshot=What NVDA snapshot you want? (alpha/beta): 
if not %snapshot% == alpha if not %snapshot% == beta (
 echo %snapshot% is not a valid snapshot, please retry.
 pause
 goto :eof
)

for /f "usebackq tokens=4 delims==" %%a in (`findstr /r "_%snapshot% _[0-9]*\.[0-9]%snapshot%" %pageFile%`) do (
 set line=%%a
 set cutline=!line:~0,-6!
 echo Downloading...
 if %using% == powershell (echo %using% does not provide progress info, so, be patient...)
 %downloader% !cutline!
 del %pageFile%
 echo DONE^^!
 pause
 goto :eof
)

:psget
powershell -command "(New-Object System.Net.WebClient).DownloadFile('%1', '%~dp0%~nx1')"
goto :eof
