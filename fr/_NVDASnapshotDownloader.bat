@echo off
title NVDA snapshot downloader
:: Author: Alberto buffolino
:: License: GPL V3
:: French translation: Rémy Ruiz
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
powershell -command "echo Disponible!">nul 2>nul
if %errorlevel% == 0 (
 set using=powershell
 goto start
) else (
 echo ERREUR: le téléchargement n'est pas possible,
 echo installe curl ou wget, p. ex. depuis
 echo https://eternallybored.org/misc/wget/
 pause
 goto finish
)

:start
echo Utilisant %using%
echo Obtenant des informations sur la version...
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
 echo Erreur lors de l'obtention des informations de version, veuillez réessayer ultérieurement.
 pause
 goto finish
)

set choices=,
for /f "usebackq tokens=2 delims=<>" %%a in (`findstr "<h2>" %pageFile%`) do (set choices=!choices!, %%a)
set choices=!choices:~3!
set /p snapshot=Quelle version de développement de NVDA voulez-vous? (%choices%): 
set stop=1
for %%a in (%choices%) do (if %snapshot% == %%a set stop=0)
if %stop% == 1 (
 echo %snapshot% n'est pas une version de développement valide, veuillez réessayer.
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
echo La dernière %snapshot% est %version%
set /p answer=Voulez-vous la télécharger? (o/n): 
if %answer% == o goto download
if %answer% == n (
 echo Ah, ok ... à la prochaine fois ^^!
 pause
)
goto :eof

:download
echo Téléchargement en cours...
if %using% == powershell (echo %using% ne fournit pas d'informations sur le progrè, alors soyez patient...)
%downloader% !cutline!
del %pageFile%
:: last in next line is bell char
echo ¡PRÊT!^^! 
pause
goto :eof

:psget
powershell -command "(New-Object System.Net.WebClient).DownloadFile('%1', '%~dp0%~nx1')"
goto :eof

:finish
chcp %cp%>nul 2>&1
