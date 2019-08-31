@echo off
title NVDA snapshot downloader
:: Author: Alberto buffolino
:: License: GPL V3
:: Italian translation: Christian LeoMameli
setlocal enabledelayedexpansion
:: backup current codepage, and change it to 1252, more useful for translators
:: saving in ANSI is recomended
for /f "tokens=2 delims=:." %%a in ('chcp') do (set cp=%%a)
chcp 1252>nul 2>&1
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
powershell -command "echo Disponibile!">nul 2>nul
if %errorlevel% == 0 (
 set using=powershell
 goto start
) else (
 echo ERROR: Impossibile scaricare,
 echo instala curl o wget, p. ej. da
 echo https://eternallybored.org/misc/wget/
 pause
 goto finish
)

:start
echo in uso %using%
echo Ricerca di informazioni sulla versione...
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
 echo Si è verificato un errore nel recuperare informazioni di versione, riprova più tardi.
 pause
 goto finish
)

set choices=,
for /f "usebackq tokens=2 delims=<>" %%a in (`findstr "<h2>" %pageFile%`) do (set choices=!choices!, %%a)
set choices=!choices:~3!
set /p snapshot=Quale versione di NVDA vuoi scaricare? (%choices%): 
set stop=1
for %%a in (%choices%) do (if %snapshot% == %%a set stop=0)
if %stop% == 1 (
 echo %snapshot% non è una versione in sviluppo valida, riprova inserendo il nome corretto.
 pause
 goto finish
)

for /f "usebackq tokens=4 delims==" %%a in (`findstr "_%snapshot%" %pageFile%`) do (
 set line=%%a
 set cutline=!line:~0,-6!
 call :confirm !cutline!
 goto finish
)

:confirm
for /f "tokens=3* delims=_" %%a in ("%~n1") do (set version=%%a%%b)
echo l'ultima %snapshot% pubblicata è la versione %version%
set /p answer=Desideri scaricarla? (s/n): 
if %answer% == s goto download
if %answer% == n (
 echo Ah, grazie lo stesso... Arrivederci^^!
 pause
)
goto :eof

:download
echo Download in corso...
if %using% == powershell (echo %using% non da informazioni di progresso, attendere qualche minuto...)
%downloader% !cutline!
del %pageFile%
:: last in next line is bell char
echo Download completato!^^! 
pause
goto :eof

:psget
powershell -command "(New-Object System.Net.WebClient).DownloadFile('%1', '%~dp0%~nx1')"
goto :eof

:finish
chcp %cp%>nul 2>&1
