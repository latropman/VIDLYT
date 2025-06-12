@echo off
NET SESSION >nul 2>&1
if %errorlevel% neq 0 (
    powershell -Command "Start-Process cmd -ArgumentList '/c, \"%~f0\"' -Verb runAs"
    exit /b
)
setlocal enabledelayedexpansion
chcp 65001 >nul
title Установка Latropman's VIDLYT

echo • • • • • • Latropman's VIDLYT • • • • • •
echo • • • • • • • • 2025-06-12 • • • • • • • •
echo • • • • • • • • •  V001  • • • • • • • • •
echo.
:: Папка с файлами программы
mkdir "C:\Scripts\VIDLYT"
start C:\Scripts\VIDLYT

set "TARGET=C:\Scripts\VIDLYT"
set "DL_CMD=%TARGET%\DOWNLOAD.cmd"
set "UNINSTALL_CMD=%TARGET%\UNINSTALL.cmd"
set "YTDLP=%TARGET%\yt-dlp.exe"
set "YTDLP_URL=https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe"
set "ICO_PS1=%TARGET%\VIDLYT_ICON.ps1"
set "ICO_FILE=%TARGET%\ICON.ico"
set "REG_PATH_FILE=%TARGET%\VIDLYT PATH.reg"

:: yt-dlp.exe
echo Скачиваю yt-dlp, если его нет...
if not exist "%YTDLP%" (
    echo Загружаем yt-dlp.exe...
    powershell -Command "Invoke-WebRequest -Uri '%YTDLP_URL%' -OutFile '%YTDLP%'"
    if errorlevel 1 (
        echo [!] Не удалось скачать yt-dlp.exe
        pause
        exit /b
    )
) else (
    echo yt-dlp.exe уже существует
)

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
reg add "HKEY_CLASSES_ROOT\Directory\Background\shell\VIDLYT" /v "Icon" /d "C:\\Scripts\\VIDLYT\\ICON.ico" /f
del /f /q "%ICO_PS1%"
del /f /q "%REG_PATH_FILE%"
timeout /t 2 /nobreak >nul

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

:: Получаем текущую версию (если есть)
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

:: Получаем последнюю версию с GitHub (парсим тег)
for /f "usebackq tokens=*" %%v in (`powershell -Command "(Invoke-WebRequest -UseBasicParsing -Uri 'https://api.github.com/repos/yt-dlp/yt-dlp/releases/latest').content | ConvertFrom-Json | Select-Object -ExpandProperty tag_name"`) do set "LATEST_VER=%%v"

echo Последняя версия: %LATEST_VER%

:: Если версия отсутствует или отличается — обновляем
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
        move /Y "%TEMP_YTDLP%" "%YTDLP%"
        echo yt-dlp.exe обновлен до версии %LATEST_VER%.
    )
) else (
    echo yt-dlp.exe актуален.
    if exist "%TEMP_YTDLP%" del /f /q "%TEMP_YTDLP%"
)

:start
:: Получаем URL из буфера обмена
for /f "usebackq tokens=* delims=" %%i in (`powershell -command "Get-Clipboard"`) do set "URL=%%i"

:: Получаем ID видео, не скачивая его
for /f "delims=" %%a in ('"%YTDLP%" --get-id "!URL!"') do set "VIDEO_ID=%%a"

:: Проверка, существует ли уже файл с этим ID
set "FOUND_FILE="
for %%f in (*.mp4 *.mkv *.webm) do (
    echo %%~nf | findstr /i "!VIDEO_ID!" >nul && set "FOUND_FILE=%%f"
)

if defined FOUND_FILE (
    echo Видео уже скачано: "!FOUND_FILE!"
    set "LATEST_FILE=!FOUND_FILE!"
    goto ask_convert
)

echo Downloading: !URL!
"%YTDLP%" --no-playlist --age-limit 99 --geo-bypass --no-check-certificate --referer=https://www.youtube.com/ --user-agent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/125 Safari/537.36" --windows-filenames -f "bv*[height<=2160]+ba/b[height<=2160]" --fragment-retries 10 --concurrent-fragments 4 --http-chunk-size 8388608 -o "%%(title)s-%%(id)s.%%(ext)s" "!URL!"

timeout /t 2 >nul

:: Поиск последнего файла
set "LATEST_FILE="

for %%f in (*.mp4 *.mkv *.webm) do (
    set "LATEST_FILE=%%f"
)

if not defined LATEST_FILE (
    echo Ошибка: файл не найден!
    pause
    goto :end
)

echo Последний скачанный файл: "!LATEST_FILE!"

:ask_convert
:: Окно с выбором "Конвертировать?"
set "PS_CMD=Add-Type -AssemblyName PresentationFramework; $res = [System.Windows.MessageBox]::Show('Конвертировать в MP4 (кодек H.264 с NVENC)?', 'VIDLYT', 'YesNo', 'Question'); if ($res -eq 'Yes') { Write-Output 'Yes' } else { Write-Output 'No' }"
for /f "delims=" %%a in ('powershell -Command "!PS_CMD!"') do set "choice=%%a"

if "!choice!"=="No" (
    echo Конвертация пропущена.
    goto asknewurl
)

:: Установка пути к новому файлу
for %%a in ("!LATEST_FILE!") do set "OUTPUT_FILE=%%~dpna-converted.mp4"

echo Конвертация в MP4 (H.264 NVENC с битрейтом 20M)...
ffmpeg.exe -y -hwaccel cuda -i "!LATEST_FILE!" -c:v h264_nvenc -b:v 20M -maxrate 20M -bufsize 50M -preset p3 -c:a aac -b:a 192k "!OUTPUT_FILE!"

echo Конвертация завершена: "!OUTPUT_FILE!"

:asknewurl
echo.
echo Вставьте новую ссылку для скачивания и нажмите Enter, или просто нажмите Enter для выхода:
set /p NEW_URL=Новая ссылка:

if "!NEW_URL!"=="" (
    echo Завершение работы...
    goto :end
) else (
    set "URL=!NEW_URL!"
    goto :start
)

:end
pause
exit
DOWNLOADCMDEND

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
    echo Запуск от имени администратора...
    powershell -Command "Start-Process -FilePath '%~f0' -Verb runAs"
    exit /b
)
title Удаление VIDLYT
echo Удаляем записи из реестра...
reg delete "HKCR\Directory\Background\shell\VIDLYT" /f
echo Удаляем папку: C:\Scripts\VIDLYT
rmdir /s /q "C:\Scripts\VIDLYT"
pause
exit
UNINSTALLEND