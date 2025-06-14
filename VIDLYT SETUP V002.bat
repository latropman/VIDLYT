@echo off
NET SESSION >nul 2>&1
if %errorlevel% neq 0 (
    powershell -Command "Start-Process cmd -ArgumentList '/c, \"%~f0\"' -Verb runAs"
    exit /b
)
setlocal enabledelayedexpansion
chcp 65001 >nul
title Установка Latropman's VIDLYT V002 / 2025-06-14

echo Удаление старой версии Latropman's VIDLYT
reg delete "HKCR\*\shell\VIDLYT" /f
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\VIDLYT.SUBMP3" /f
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\VIDLYT.SUBMP4" /f
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\VIDLYT.SUBWAV" /f
if exist "C:\Scripts\VIDLYT" (
    rmdir /s /q "C:\Scripts\VIDLYT"
)

echo Установка новой версии Latropman's VIDLYT
mkdir "C:\Scripts\VIDLYT"
start C:\Scripts\VIDLYT

set "TARGET=C:\Scripts\VIDLYT"
set "DL_CMD=%TARGET%\DOWNLOAD.cmd"
set "CV_CMD=%TARGET%\CONVERT.cmd"
set "UNINSTALL_CMD=%TARGET%\UNINSTALL.cmd"
set "YTDLP=%TARGET%\yt-dlp.exe"
set "YTDLP_URL=https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe"
set "ICO_PS1=%TARGET%\VIDLYT_ICON.ps1"
set "ICO_FILE=%TARGET%\ICON.ico"
set "REG_PATH_FILE=%TARGET%\VIDLYT PATH.reg"
set "FFMPEG_URL=https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip"

:: yt-dlp.exe
echo Проверка yt-dlp для скачивания...
if not exist "%YTDLP%" (
    powershell -Command "Invoke-WebRequest -Uri '%YTDLP_URL%' -OutFile '%YTDLP%'"
    if errorlevel 1 (
        echo [!] Не удалось скачать yt-dlp.exe
::        pause
::        exit /b
    )
) else (
    echo yt-dlp.exe уже существует
)

echo yt-dlp установлен
timeout /t 1 >nul

:: Окно с выбором "Скачать конвертер в MP4?"
set "PS_CMD=Add-Type -AssemblyName PresentationFramework; $res = [System.Windows.MessageBox]::Show('Скачать конвертер в MP4?', 'VIDLYT', 'YesNo', 'Question'); if ($res -eq 'Yes') { Write-Output 'Yes' } else { Write-Output 'No' }"
for /f "delims=" %%a in ('powershell -Command "!PS_CMD!"') do set "choice=%%a"

if "!choice!"=="Yes" (
    goto ffmpeg_install
)
if "!choice!"=="No" (
    goto files
)

pause

:: ffmpeg.exe
:ffmpeg_install
echo Проверка ffmpeg для конвертации...
if not exist "%TARGET%\ffmpeg.exe" (
    powershell -Command "try { Invoke-WebRequest -Uri '%FFMPEG_URL%' -OutFile '%TARGET%\ffmpeg.zip' -UseBasicParsing } catch { exit 1 }"

    if errorlevel 1 (
        echo Ошибка загрузки ffmpeg
        pause
        exit /b
    )

    echo Распаковка ffmpeg.zip...
    if exist "%TARGET%\ffmpeg.zip" (
        powershell -Command "Expand-Archive -LiteralPath '%TARGET%\ffmpeg.zip' -DestinationPath '%TARGET%' -Force"
        if errorlevel 1 (
            echo Ошибка распаковки ffmpeg.zip
            pause
            exit /b
        )
        del "%TARGET%\ffmpeg.zip"
        echo ffmpeg успешно установлен.
    ) else (
        echo Архив ffmpeg.zip не найден.
        pause
        exit /b
    )
) else (
    echo ffmpeg.exe найден, продолжаем работу...
)

:: CONVERT.cmd - загрузчик
set "BEGIN=CONVERTCMDBEGIN"
set "END=CONVERTCMDEND"
for /f "tokens=1 delims=:" %%a in ('findstr /n /c:"%BEGIN%" "%~f0"') do set "start=%%a"
for /f "tokens=1 delims=:" %%a in ('findstr /n /c:"%END%" "%~f0"') do set "end=%%a"
powershell -WindowStyle Hidden -Command "(Get-Content '%~f0' -Encoding Default | Select-Object -Skip (%start%) -First (%end% - %start% - 1)) | Set-Content '%CV_CMD%' -Encoding Default"

reg add "HKCR\*\shell\VIDLYT" /v "Icon" /d "C:\\Scripts\\VIDLYT\\ICON.ico" /f
reg add "HKCR\*\shell\VIDLYT" /v "SubCommands" /d "VIDLYT.SUBMP4;VIDLYT.SUBMP3;VIDLYT.SUBWAV" /f
reg add "HKCR\*\shell\VIDLYT" /v "MUIVerb" /d "Convert to" /f

:: Команда MP4
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\VIDLYT.SUBMP4" /ve /d "MP4" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\VIDLYT.SUBMP4\command" /ve /d "\"C:\\Scripts\\VIDLYT\\CONVERT.cmd\" \"%%1\" mp4" /f

:: Команда MP3
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\VIDLYT.SUBMP3" /ve /d "MP3" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\VIDLYT.SUBMP3\command" /ve /d "\"C:\\Scripts\\VIDLYT\\CONVERT.cmd\" \"%%1\" mp3" /f

:: Команда WAV
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\VIDLYT.SUBWAV" /ve /d "WAV" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\VIDLYT.SUBWAV\command" /ve /d "\"C:\\Scripts\\VIDLYT\\CONVERT.cmd\" \"%%1\" wav" /f

:files
:: VIDLYT ICON.ps1 - скрипт для генерации иконки
set "BEGIN=ICONPS1BEGIN"
set "END=ICONPS1END"
for /f "tokens=1 delims=:" %%a in ('findstr /n /c:"%BEGIN%" "%~f0"') do set "start=%%a"
for /f "tokens=1 delims=:" %%a in ('findstr /n /c:"%END%" "%~f0"') do set "end=%%a"
powershell -WindowStyle Hidden -Command "(Get-Content '%~f0' -Encoding Default | Select-Object -Skip (%start%) -First (%end% - %start% - 1)) | Set-Content '%ICO_PS1%' -Encoding Default"

:: DOWNLOAD.cmd - загрузчик
set "BEGIN=DOWNLOADCMDBEGIN"
set "END=DOWNLOADCMDEND"
for /f "tokens=1 delims=:" %%a in ('findstr /n /c:"%BEGIN%" "%~f0"') do set "start=%%a"
for /f "tokens=1 delims=:" %%a in ('findstr /n /c:"%END%" "%~f0"') do set "end=%%a"
powershell -WindowStyle Hidden -Command "(Get-Content '%~f0' -Encoding Default | Select-Object -Skip (%start%) -First (%end% - %start% - 1)) | Set-Content '%DL_CMD%' -Encoding Default"

:: VIDLYT PATH.reg - файл реестра для пункта в контекстном меню
set "PATHBEGIN=PATHBEGIN"
set "PATHEND=PATHEND"
for /f "tokens=1 delims=:" %%a in ('findstr /n /c:"%PATHBEGIN%" "%~f0"') do set "start=%%a"
for /f "tokens=1 delims=:" %%a in ('findstr /n /c:"%PATHEND%" "%~f0"') do set "end=%%a"
powershell -WindowStyle Hidden -Command "(Get-Content '%~f0' -Encoding Default | Select-Object -Skip (%start%) -First (%end% - %start% - 1)) | Set-Content '%REG_PATH_FILE%' -Encoding Default"

:: UNINSTALL.cmd - деинсталлятор
set "BEGIN=UNINSTALLBEGIN"
set "END=UNINSTALLEND"
for /f "tokens=1 delims=:" %%a in ('findstr /n /c:"%BEGIN%" "%~f0"') do set "start=%%a"
for /f "tokens=1 delims=:" %%a in ('findstr /n /c:"%END%" "%~f0"') do set "end=%%a"
powershell -WindowStyle Hidden -Command "(Get-Content '%~f0' -Encoding Default | Select-Object -Skip (%start%) -First (%end% - %start% - 1)) | Set-Content '%UNINSTALL_CMD%' -Encoding Default"

:: Очерёдность действий с созданными файлами
cd /d %TARGET%
powershell -WindowStyle Hidden -ExecutionPolicy Bypass -Command "Start-Process powershell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File \"%ICO_PS1%\"' -Verb RunAs -Wait"
start regedit /s "%REG_PATH_FILE%"
timeout /t 2 /nobreak >nul
del /f /q "%ICO_PS1%"
del /f /q "%REG_PATH_FILE%"

powershell -Command "Add-Type -AssemblyName PresentationFramework; [System.Windows.MessageBox]::Show('Установка завершена', 'VIDLYT', 'OK', 'Information')"

exit

:: :: :: :: ::

DOWNLOADCMDBEGIN
@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
title Latropman's VIDLYT

set "TARGET=C:\Scripts\VIDLYT"
set "YTDLP=%TARGET%\yt-dlp.exe"
set "YTDLP_URL=https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe"
set "TEMP_YTDLP=%TARGET%\yt-dlp_new.exe"

echo Проверка версии yt-dlp.exe...

set "CUR_VER="
if exist "%YTDLP%" (
    for /f "tokens=1 delims=" %%v in ('"%YTDLP%" --version 2^>nul') do set "CUR_VER=%%v" & goto :ver_got
)
:ver_got

if not defined CUR_VER (
    echo yt-dlp.exe не найден, будет загружена последняя версия.
) else (
    echo Текущая версия: %CUR_VER%
)

for /f "usebackq tokens=*" %%v in (`powershell -Command "(Invoke-WebRequest -UseBasicParsing -Uri 'https://api.github.com/repos/yt-dlp/yt-dlp/releases/latest').content | ConvertFrom-Json | Select-Object -ExpandProperty tag_name"`) do set "LATEST_VER=%%v"

echo Последняя версия: %LATEST_VER%

if /i not "%CUR_VER%"=="%LATEST_VER%" (
    echo Обновление yt-dlp.exe...
    powershell -Command "Invoke-WebRequest -Uri '%YTDLP_URL%' -OutFile '%TEMP_YTDLP%'"
    if errorlevel 1 (
        echo Ошибка загрузки yt-dlp.exe
        if not exist "%YTDLP%" (
            echo yt-dlp.exe отсутствует, выходим...
            pause
            exit /b
        )
    ) else (
        move /Y "%TEMP_YTDLP%" "%YTDLP%" >nul
        echo yt-dlp.exe обновлен до версии %LATEST_VER%.
    )
) else (
    echo yt-dlp.exe актуален.
    if exist "%TEMP_YTDLP%" del /f /q "%TEMP_YTDLP%"
)

:start
echo Подготовка к скачиванию...

:: Получаем URL из буфера обмена
set "URL="
for /f "usebackq tokens=* delims=" %%i in (`powershell -command "Get-Clipboard"`) do set "URL=%%i"

if "%URL%"=="" (
    echo Буфер обмена пуст или не содержит ссылки.
    set /p URL=Пожалуйста, вставьте ссылку вручную и нажмите Enter:
    if "%URL%"=="" (
        echo Ссылка не введена, завершаем программу.
        goto :end
    )
)

:: Получаем ID видео
for /f "delims=" %%a in ('call "%YTDLP%" --get-id "!URL!"') do set "VIDEO_ID=%%a"

:: Проверка, существует ли уже файл с этим ID
set "FOUND_FILE="
for %%f in (*.mp4 *.mkv *.webm) do (
    echo %%~nf | findstr /i "!VIDEO_ID!" >nul && set "FOUND_FILE=%%f"
)

if defined FOUND_FILE (
    echo Видео уже скачано: "!FOUND_FILE!"
    set "LATEST_FILE=!FOUND_FILE!"
    goto asknewurl
)

:: Создаём уникальную папку
echo Создание папки для компиляции...
set "VIDEO_FOLDER=VIDLYT_!VIDEO_ID!"
mkdir "!VIDEO_FOLDER!"

:: Определение скорости соединения по ping (оставлю, но не влиять на потоки)
echo Определение скорости интернета для оптимизации доставки...
for /f "tokens=2 delims== " %%a in ('ping -n 4 8.8.8.8 ^| findstr /i "Average"') do set "PING=%%a"
set "PING=!PING:ms=!"

:: Жёстко задаём потоки и размер чанка, без адаптации
set "CONCURRENT_FRAGMENTS=8"
set "CHUNK_SIZE=8388608"

echo Используется потоков: !CONCURRENT_FRAGMENTS!, размер чанка: !CHUNK_SIZE!

echo Downloading: !URL!
"%YTDLP%" --no-playlist --age-limit 99 --geo-bypass --no-check-certificate --referer=https://www.youtube.com/ --user-agent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/125 Safari/537.36" --windows-filenames -f "bv*[height<=2160]+ba/b[height<=2160]" --concurrent-fragments !CONCURRENT_FRAGMENTS! --http-chunk-size !CHUNK_SIZE! --fragment-retries 15 ^ -o "!VIDEO_FOLDER!\%%(title)s-%%(id)s.%%(ext)s" -- "!URL!"

if errorlevel 1 (
    echo Ошибка при скачивании видео.
    goto asknewurl
)

move "!VIDEO_FOLDER!\*" "." >nul 2>&1
rmdir /q /s "!VIDEO_FOLDER!" >nul 2>&1

:asknewurl
echo.
echo Вставьте новую ссылку для скачивания и нажмите Enter, или просто нажмите Enter для выхода:
set /p NEW_URL=Новая ссылка:

if "%NEW_URL%"=="" (
    goto :end
) else (
    set "URL=%NEW_URL%"
    goto :start
)

:end
exit
DOWNLOADCMDEND

CONVERTCMDBEGIN
@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
title Latropman's VIDLYT (Convert)

set "INPUT_FILE=%~1"
set "FORMAT=%~2"
if not defined FORMAT set "FORMAT=mp4"
set "BASENAME=%~dpn1"
set "OUTPUT_FILE=%BASENAME%-converted.%FORMAT%"

if /i "%FORMAT%"=="mp4" (
    set "BITRATE="
    for /f "tokens=* delims=" %%B in ('mshta "javascript:var bitrate=prompt('Введите битрейт в Mbps (например, 20):','20');if(bitrate==null) close();new ActiveXObject('Scripting.FileSystemObject').GetStandardStream(1).Write(bitrate);close()"') do (
        set "BITRATE=%%B"
    )
    if not defined BITRATE (
        echo Отменено пользователем.
        exit /b
    )
    echo !BITRATE! | findstr /i "M" >nul
    if errorlevel 1 (
        set "BITRATE=!BITRATE!M"
    )
) else if /i "%FORMAT%"=="mp3" (
    set "BITRATE="
    for /f "tokens=* delims=" %%B in ('mshta "javascript:var bitrate=prompt('Введите битрейт в кбит/с (например, 192):','192');if(bitrate==null) close();new ActiveXObject('Scripting.FileSystemObject').GetStandardStream(1).Write(bitrate);close()"') do (
        set "BITRATE=%%B"
    )
    if not defined BITRATE (
        echo Отменено пользователем.
        exit /b
    )
    echo !BITRATE! | findstr /i "k" >nul
    if errorlevel 1 (
        set "BITRATE=!BITRATE!k"
    )
) else if /i "%FORMAT%"=="wav" (
    rem Запрос частоты дискретизации
    set "RATE="
    for /f "tokens=* delims=" %%r in ('mshta "javascript:var rate=prompt('Введите частоту дискретизации (44100 или 48000):','44100');if(rate==null) close();new ActiveXObject('Scripting.FileSystemObject').GetStandardStream(1).Write(rate);close()"') do (
        set "RATE=%%r"
    )
    if not defined RATE (
        echo Отменено пользователем.
        exit /b
    )
    rem Запрос количества каналов
    set "CHANNELS="
    for /f "tokens=* delims=" %%c in ('mshta "javascript:var channels=prompt('Введите количество каналов (1 - моно, 2 - стерео):','2');if(channels==null) close();new ActiveXObject('Scripting.FileSystemObject').GetStandardStream(1).Write(channels);close()"') do (
        set "CHANNELS=%%c"
    )
    if not defined CHANNELS (
        echo Отменено пользователем.
        exit /b
    )
    rem Запрос битности
    set "BITDEPTH="
    for /f "tokens=* delims=" %%b in ('mshta "javascript:var bitdepth=prompt('Введите битность (16, 24 или 32):','16');if(bitdepth==null) close();new ActiveXObject('Scripting.FileSystemObject').GetStandardStream(1).Write(bitdepth);close()"') do (
        set "BITDEPTH=%%b"
    )
    if not defined BITDEPTH (
        echo Отменено пользователем.
        exit /b
    )

    rem Валидация и установка значений по умолчанию
    if not "!RATE!"=="44100" if not "!RATE!"=="48000" set "RATE=44100"
    if not "!CHANNELS!"=="1" if not "!CHANNELS!"=="2" set "CHANNELS=2"
    if not "!BITDEPTH!"=="16" if not "!BITDEPTH!"=="24" if not "!BITDEPTH!"=="32" set "BITDEPTH=16"

    if "!BITDEPTH!"=="16" (
        set "CODEC=pcm_s16le"
    ) else if "!BITDEPTH!"=="24" (
        set "CODEC=pcm_s24le"
    ) else (
        set "CODEC=pcm_s32le"
    )
)

set "target=ffmpeg.exe"
set "search_root=C:\Scripts\VIDLYT"
set "FFMPEG_PATH="

for /r "%search_root%" %%f in (*) do (
    if /i "%%~nxf"=="%target%" (
        set "FFMPEG_PATH=%%f"
        goto :found
    )
)

echo ffmpeg не найден в %search_root%.
pause
exit /b

:found

if /i "%FORMAT%"=="mp4" (
    "%FFMPEG_PATH%" -y -hwaccel cuda -i "%INPUT_FILE%" -c:v h264_nvenc -b:v %BITRATE% -maxrate %BITRATE% -bufsize 50M -preset p3 -c:a aac -b:a 192k "%OUTPUT_FILE%"
) else if /i "%FORMAT%"=="mp3" (
    "%FFMPEG_PATH%" -y -i "%INPUT_FILE%" -vn -c:a libmp3lame -b:a %BITRATE% "%OUTPUT_FILE%"
) else if /i "%FORMAT%"=="wav" (
    "%FFMPEG_PATH%" -y -i "%INPUT_FILE%" -vn -acodec %CODEC% -ar %RATE% -ac %CHANNELS% "%OUTPUT_FILE%"
) else (
    echo Неподдерживаемый формат: %FORMAT%
    pause
    exit /b
)

echo.
echo [ ====== КОНВЕРТАЦИЯ В %FORMAT:~0,3% УСПЕШНО ЗАВЕРШЕНА ====== ]
echo Выходной файл: %OUTPUT_FILE%
echo.
timeout /t 3 >nul
exit /b
CONVERTCMDEND

ICONPS1BEGIN
Add-Type -AssemblyName System.Drawing
$width = 35
$height = 35
$bgColor = [System.Drawing.Color]::FromArgb(115, 202, 188)
$bmp = New-Object System.Drawing.Bitmap $width, $height
$graphics = [System.Drawing.Graphics]::FromImage($bmp)
$graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$graphics.Clear($bgColor)
$circleBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Black)
$circleRect = New-Object System.Drawing.RectangleF(5, 5, 25, 25)
$graphics.FillEllipse($circleBrush, $circleRect)
$trianglePoints = [System.Drawing.PointF[]]@(
    [System.Drawing.PointF]::new(12, 15),  # левый верхний угол
    [System.Drawing.PointF]::new(23, 15),  # правый верхний угол
    [System.Drawing.PointF]::new(17.5, 22) # нижний центральный угол
)
$graphics.FillPolygon([System.Drawing.Brushes]::White, $trianglePoints)
$pen = New-Object System.Drawing.Pen([System.Drawing.Color]::White, 5)
$graphics.DrawRectangle($pen, 0, 0, $width - 1, $height - 1)
$bmp.Save("$PSScriptRoot\ICON.ico", [System.Drawing.Imaging.ImageFormat]::Bmp)
$graphics.Dispose()
$bmp.Dispose()
ICONPS1END

PATHBEGIN
Windows Registry Editor Version 5.00

[HKEY_CLASSES_ROOT\Directory\Background\shell\VIDLYT]
@="Latropman's VIDLYT"
"SeparatorBefore"=""
"SeparatorAfter"=""

[HKEY_CLASSES_ROOT\Directory\Background\shell\VIDLYT\command]
@="cmd.exe /k \"\"C:\\Scripts\\VIDLYT\\DOWNLOAD.cmd\"\""
PATHEND

UNINSTALLBEGIN
@echo off
chcp 65001 >nul
net session >nul 2>&1
if %errorlevel% neq 0 (
    powershell -Command "Start-Process -FilePath '%~f0' -Verb runAs"
    exit /b
)
title Удаление VIDLYT
reg delete "HKCR\*\shell\VIDLYT" /f
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\VIDLYT.SUBMP3" /f
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\VIDLYT.SUBMP4" /f
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\VIDLYT.SUBWAV" /f
rmdir /s /q "C:\Scripts\VIDLYT"
pause
exit
UNINSTALLEND