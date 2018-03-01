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

if not exist %pageFile% (
 echo Error getting version info, please retry again later.
 pause
 goto :eof
)

echo.
set /p branch=What NVDA branch you want? (master/next/rc) 
if not %branch% == master if not %branch% == next if not %branch% == rc (
 echo %branch% is not a valid branch, please retry.
 pause
 goto :eof
)

for /f "usebackq tokens=4 delims==" %%a in (`find "_%branch%" %pageFile%`) do (
 set line=%%a
 set cutline=!line:~0,-6!
 echo Downloading...
 %downloader% !cutline!
 del %pageFile%
 echo DONE^^!
 pause
 goto :eof
)
