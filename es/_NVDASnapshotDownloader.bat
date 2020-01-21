@echo off
title NVDA snapshot downloader
:: Author: Alberto buffolino
:: License: GPL V3
:: Spanish translation: Noelia Ruiz Martínez
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
powershell -command "echo ¡Disponible!">nul 2>nul
if %errorlevel% == 0 (
 set using=powershell
 goto start
) else (
 echo ERROR: la descarga no es posible,
 echo instala curl o wget, p. ej. desde
 echo https://eternallybored.org/misc/wget/
 pause
 goto finish
)

:start
echo Utilizando %using%
echo Obteniendo información sobre la versión...
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
 echo Error al obtener información sobre la versión, por favor vuelve a intentarlo más tarde.
 pause
 goto finish
)

set choices=,
for /f "usebackq tokens=2 delims=<>" %%a in (`findstr "<h2>" %pageFile%`) do (set choices=!choices!, %%a)
set choices=!choices:~3!
set /p snapshot=¿Qué versión en desarrollo de NVDA deseas? (%choices%): 
set stop=1
for %%a in (%choices%) do (if %snapshot% == %%a set stop=0)
if %stop% == 1 (
 echo %snapshot% no es una versión en desarrollo válida, por favor vuelve a intentarlo.
 pause
 goto finish
)

for /f "usebackq tokens=4 delims==" %%a in (`findstr /r "_%snapshot% _[0-9]*\.[0-9]%snapshot%" %pageFile%`) do (
 set line=%%a
 set cutline=!line:~0,-6!
 call :confirm !cutline!
 goto finish
)

:confirm
if %snapshot% == beta (set tokens=2) else (set tokens=3)
for /f "tokens=%tokens%* delims=_" %%a in ("%~n1") do (set version=%%a%%b)
echo La última %snapshot% es %version%
set /p answer=¿Quieres descargarla? (s/n): 
if %answer% == s goto download
if %answer% == n (
 echo Ah, vale... ¡Hasta la próxima^^!
 pause
)
goto :eof

:download
echo Descargando...
if %using% == powershell (echo %using% no proporciona información de progreso, así que ten paciencia...)
%downloader% !cutline!
del %pageFile%
:: last in next line is bell char
echo ¡LISTO!^^! 
pause
goto :eof

:psget
powershell -command "(New-Object System.Net.WebClient).DownloadFile('%1', '%~dp0%~nx1')"
goto :eof

:finish
chcp %cp%>nul 2>&1
