@echo off
NET SESSION >nul 2>&1
if %errorlevel% neq 0 (
    powershell -Command "Start-Process cmd -ArgumentList '/c \"%~f0\"' -Verb runAs"
    exit /b
)
setlocal enabledelayedexpansion
chcp 65001 >nul
title Installing Latropman's VIDLYT V003 / 2026-03-24

for /f %%a in ('echo prompt $E ^| cmd') do set "ESC=%%a"

:: Windows checking
ver | find "10." > nul || (
    echo %ESC%[38;2;198;108;108m^> Requires Windows 10/11%ESC%[0m
    pause
    exit /b
)

:: Powershell checking
where powershell >nul 2>&1
if errorlevel 1 (
    echo %ESC%[38;2;198;108;108m^> PowerShell is not available. Installation cannot continue.%ESC%[0m
    pause
    exit /b
)

echo %ESC%[38;2;198;198;108m^> Deleting old version of Latropman^'s VIDLYT%ESC%[0m
reg delete "HKCR\*\shell\VIDLYT" /f
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\VIDLYT.SUBMP3" /f
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\VIDLYT.SUBMP4" /f
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\VIDLYT.SUBWAV" /f
if exist "C:\Scripts\VIDLYT" (
    rmdir /s /q "C:\Scripts\VIDLYT"
)
<nul set /p=%ESC%[6A
<nul set /p=%ESC%[2K
<nul set /p=%ESC%[0J
echo %ESC%[38;2;108;198;183m^> The old version has been deleted.%ESC%[0m
echo %ESC%[38;2;198;198;108m^> Installing new version of Latropman's VIDLYT...%ESC%[0m
mkdir "C:\Scripts\VIDLYT"

set "TARGET=C:\Scripts\VIDLYT"
set "DL_CMD=%TARGET%\DOWNLOAD.cmd"
set "CV_CMD=%TARGET%\CONVERT.cmd"
set "UNINSTALL_CMD=%TARGET%\UNINSTALL.cmd"
set "DONEMESSAGE=%TARGET%\DONEMESSAGE.bat"
set "YTDLP=%TARGET%\yt-dlp.exe"
set "YTDLP_URL=https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe"
set "ICO_PS1=%TARGET%\VIDLYT_ICON.ps1"
set "ICO_FILE=%TARGET%\ICON.ico"
set "REG_PATH_FILE=%TARGET%\VIDLYT PATH.reg"
set "FFMPEG_URL=https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip"


:: Internet connection
powershell -Command "(Invoke-WebRequest -Uri 'https://github.com' -UseBasicParsing -DisableKeepAlive).StatusDescription" >nul 2>&1 || (
    echo %ESC%[38;2;198;108;108m^> No internet connection%ESC%[0m
    pause
    exit /b
)

:: yt-dlp.exe
echo %ESC%[38;2;198;198;108m^> Checking yt-dlp for downloading...%ESC%[0m
if not exist "%YTDLP%" (
    powershell -Command "Invoke-WebRequest -Uri '%YTDLP_URL%' -OutFile '%YTDLP%'"
    if errorlevel 1 (
        echo %ESC%[38;2;198;108;108m^> Failed to download yt-dlp.exe%ESC%[0m
    )
) else (
    echo %ESC%[38;2;108;198;183m^> yt-dlp.exe already exists%ESC%[0m
)
<nul set /p=%ESC%[1A
<nul set /p=%ESC%[2K
echo.


:: "Install FFmpeg Converter?"
set "PS_CMD=Add-Type -AssemblyName PresentationFramework; $xaml='<Window xmlns=\"http://schemas.microsoft.com/winfx/2006/xaml/presentation\" Title=\"VIDLYT\" Height=\"180\" Width=\"360\" Background=\"Transparent\" WindowStartupLocation=\"CenterScreen\" ResizeMode=\"NoResize\" WindowStyle=\"None\" AllowsTransparency=\"True\"><Border Background=\"#0f0f0f\" CornerRadius=\"12\" Padding=\"20\" BorderBrush=\"#6cc7b8\" BorderThickness=\"2\"><Border.Resources><Style TargetType=\"Button\"><Setter Property=\"Width\" Value=\"90\"/><Setter Property=\"Height\" Value=\"35\"/><Setter Property=\"Background\" Value=\"#6cc7b8\"/><Setter Property=\"Foreground\" Value=\"#0f0f0f\"/><Setter Property=\"FontWeight\" Value=\"Bold\"/><Setter Property=\"BorderThickness\" Value=\"0\"/><Setter Property=\"Margin\" Value=\"5\"/><Setter Property=\"Cursor\" Value=\"Hand\"/><Setter Property=\"FontSize\" Value=\"12\"/><Setter Property=\"Template\"><Setter.Value><ControlTemplate TargetType=\"Button\"><Border Background=\"{TemplateBinding Background}\" CornerRadius=\"8\"><ContentPresenter HorizontalAlignment=\"Center\" VerticalAlignment=\"Center\"/></Border></ControlTemplate></Setter.Value></Setter><Style.Triggers><Trigger Property=\"IsMouseOver\" Value=\"True\"><Setter Property=\"Background\" Value=\"#5ab8a8\"/></Trigger></Style.Triggers></Style></Border.Resources><Grid><Grid.RowDefinitions><RowDefinition Height=\"*\"/><RowDefinition Height=\"Auto\"/></Grid.RowDefinitions><TextBlock Text=\"Install FFmpeg Converter?\" FontWeight=\"Bold\" FontSize=\"14\" Foreground=\"#6cc7b8\" HorizontalAlignment=\"Center\" VerticalAlignment=\"Center\" Margin=\"0,0,0,10\" TextAlignment=\"Center\"/><StackPanel Grid.Row=\"1\" Orientation=\"Horizontal\" HorizontalAlignment=\"Center\" Margin=\"0,20,0,0\"><Button Name=\"YesButton\" Content=\"Yes\"/><Button Name=\"NoButton\" Content=\"No\"/></StackPanel></Grid></Border></Window>'; $reader = New-Object System.Xml.XmlNodeReader ([xml]$xaml); $window = [Windows.Markup.XamlReader]::Load($reader); $window.FindName('YesButton').Add_Click({ $window.DialogResult = $true }); $window.FindName('NoButton').Add_Click({ $window.DialogResult = $false }); if ($window.ShowDialog() -eq $true) { Write-Output 'Yes' } else { Write-Output 'No' }"

for /f "delims=" %%a in ('powershell -STA -Command "!PS_CMD!"') do set "choice=%%a"
if "!choice!"=="Yes" (
    echo %ESC%[38;2;198;198;108m^> Installing FFmpeg...%ESC%[0m
    goto ffmpeg_install
)
if "!choice!"=="No" (
    echo %ESC%[38;2;198;108;108m^> Skipping FFmpeg installation...%ESC%[0m
    goto files
)

:ffmpeg_install
echo %ESC%[38;2;198;198;108m^> Checking ffmpeg for conversion...%ESC%[0m
:: Check if ffmpeg is in system path
where ffmpeg >nul 2>nul
if not errorlevel 1 (
    echo %ESC%[38;2;198;198;108m^> ffmpeg found in system path, continuing...%ESC%[0m
    goto ffmpeg_check_end
)

:: If ffmpeg not in path, check local copy
if exist "%TARGET%\ffmpeg.exe" (
    echo %ESC%[38;2;198;198;108m^> ffmpeg.exe found locally, continuing...%ESC%[0m
    goto ffmpeg_check_end
)

echo %ESC%[38;2;198;198;108m^> ffmpeg not found in path or locally, starting download...%ESC%[0m
powershell -Command "try { Invoke-WebRequest -Uri '%FFMPEG_URL%' -OutFile '%TARGET%\ffmpeg.zip' -UseBasicParsing } catch { exit 1 }"

if errorlevel 1 (
    echo %ESC%[38;2;198;108;108m^> Error downloading ffmpeg%ESC%[0m
    pause
    exit /b
)

echo %ESC%[38;2;198;198;108m^> Extracting ffmpeg.zip...%ESC%[0m
if exist "%TARGET%\ffmpeg.zip" (
    powershell -Command "Expand-Archive -LiteralPath '%TARGET%\ffmpeg.zip' -DestinationPath '%TARGET%' -Force"
    if errorlevel 1 (
        echo %ESC%[38;2;198;108;108m^> Error extracting ffmpeg.zip%ESC%[0m
        pause
        exit /b
    )
    del "%TARGET%\ffmpeg.zip"
    echo %ESC%[38;2;108;198;183m^> ffmpeg successfully installed.%ESC%[0m
) else (
    echo %ESC%[38;2;198;108;108m^> ffmpeg.zip archive not found.%ESC%[0m
    pause
    exit /b
)

:ffmpeg_check_end

reg add "HKCR\*\shell\VIDLYT" /v "Icon" /d "C:\\Scripts\\VIDLYT\\ICON.ico" /f
reg add "HKCR\*\shell\VIDLYT" /v "SubCommands" /d "VIDLYT.SUBMP4;VIDLYT.SUBMP3;VIDLYT.SUBWAV" /f
reg add "HKCR\*\shell\VIDLYT" /v "MUIVerb" /d "Convert to" /f

:: CONVERT.cmd - loader
set "BEGIN=CONVERTCMDBEGIN"
set "END=CONVERTCMDEND"
for /f "tokens=1 delims=:" %%a in ('findstr /n /c:"%BEGIN%" "%~f0"') do set "start=%%a"
for /f "tokens=1 delims=:" %%a in ('findstr /n /c:"%END%" "%~f0"') do set "end=%%a"
powershell -WindowStyle Hidden -Command "(Get-Content '%~f0' -Encoding Default | Select-Object -Skip (%start%) -First (%end% - %start% - 1)) | Set-Content '%CV_CMD%' -Encoding Default"

:: MP4 command
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\VIDLYT.SUBMP4" /ve /d "MP4" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\VIDLYT.SUBMP4\command" /ve /d "\"C:\\Scripts\\VIDLYT\\CONVERT.cmd\" \"%%1\" mp4" /f

:: MP3 command
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\VIDLYT.SUBMP3" /ve /d "MP3" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\VIDLYT.SUBMP3\command" /ve /d "\"C:\\Scripts\\VIDLYT\\CONVERT.cmd\" \"%%1\" mp3" /f

:: WAV command
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\VIDLYT.SUBWAV" /ve /d "WAV" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\VIDLYT.SUBWAV\command" /ve /d "\"C:\\Scripts\\VIDLYT\\CONVERT.cmd\" \"%%1\" wav" /f

:files

:: VIDLYT ICON.ps1 - icon generation script
set "BEGIN=ICONPS1BEGIN"
set "END=ICONPS1END"
for /f "tokens=1 delims=:" %%a in ('findstr /n /c:"%BEGIN%" "%~f0"') do set "start=%%a"
for /f "tokens=1 delims=:" %%a in ('findstr /n /c:"%END%" "%~f0"') do set "end=%%a"
powershell -WindowStyle Hidden -Command "(Get-Content '%~f0' -Encoding Default | Select-Object -Skip (%start%) -First (%end% - %start% - 1)) | Set-Content '%ICO_PS1%' -Encoding Default"

:: DOWNLOAD.cmd - loader
set "BEGIN=DOWNLOADCMDBEGIN"
set "END=DOWNLOADCMDEND"
for /f "tokens=1 delims=:" %%a in ('findstr /n /c:"%BEGIN%" "%~f0"') do set "start=%%a"
for /f "tokens=1 delims=:" %%a in ('findstr /n /c:"%END%" "%~f0"') do set "end=%%a"
powershell -WindowStyle Hidden -Command "(Get-Content '%~f0' -Encoding Default | Select-Object -Skip (%start%) -First (%end% - %start% - 1)) | Set-Content '%DL_CMD%' -Encoding Default"

:: VIDLYT PATH.reg - registry file for context menu
set "BEGIN=PATHBEGIN"
set "END=PATHEND"
for /f "tokens=1 delims=:" %%a in ('findstr /n /c:"%BEGIN%" "%~f0"') do set "start=%%a"
for /f "tokens=1 delims=:" %%a in ('findstr /n /c:"%END%" "%~f0"') do set "end=%%a"
powershell -WindowStyle Hidden -Command "(Get-Content '%~f0' -Encoding Default | Select-Object -Skip (%start%) -First (%end% - %start% - 1)) | Set-Content '%REG_PATH_FILE%' -Encoding Default"

:: UNINSTALL.cmd - uninstaller
set "BEGIN=UNINSTALLBEGIN"
set "END=UNINSTALLEND"
for /f "tokens=1 delims=:" %%a in ('findstr /n /c:"%BEGIN%" "%~f0"') do set "start=%%a"
for /f "tokens=1 delims=:" %%a in ('findstr /n /c:"%END%" "%~f0"') do set "end=%%a"
powershell -WindowStyle Hidden -Command "(Get-Content '%~f0' -Encoding Default | Select-Object -Skip (%start%) -First (%end% - %start% - 1)) | Set-Content '%UNINSTALL_CMD%' -Encoding Default"

::DONEMESSAGE.bat
set "BEGIN=DONEMESSAGEBEGIN"
set "END=DONEMESSAGEEND"
for /f "tokens=1 delims=:" %%a in ('findstr /n /c:"%BEGIN%" "%~f0"') do set "start=%%a"
for /f "tokens=1 delims=:" %%a in ('findstr /n /c:"%END%" "%~f0"') do set "end=%%a"
powershell -WindowStyle Hidden -Command "(Get-Content '%~f0' -Encoding Default | Select-Object -Skip (%start%) -First (%end% - %start% - 1)) | Set-Content '%DONEMESSAGE%' -Encoding Default"

:: Sequence of actions with created files
cd /d %TARGET%
powershell -WindowStyle Hidden -ExecutionPolicy Bypass -Command "Start-Process powershell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File \"%ICO_PS1%\"' -Verb RunAs -Wait"
start regedit /s "%REG_PATH_FILE%"
timeout /t 2 /nobreak >nul
reg add "HKEY_CLASSES_ROOT\Directory\Background\shell\VIDLYT" /v "Icon" /d "C:\\Scripts\\VIDLYT\\ICON.ico" /f
del /f /q "%ICO_PS1%"
del /f /q "%REG_PATH_FILE%"
start cmd /c "%DONEMESSAGE%"
timeout /t 5 /nobreak >nul
del /f /q "%DONEMESSAGE%"
exit

:: :: :: :: ::

DOWNLOADCMDBEGIN
@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
title Latropman's VIDLYT V003 / 2026-03-24

for /f %%a in ('echo prompt $E ^| cmd') do set "ESC=%%a"

set "TARGET=C:\Scripts\VIDLYT"
set "YTDLP=%TARGET%\yt-dlp.exe"
set "YTDLP_URL=https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe"
set "TEMP_YTDLP=%TARGET%\yt-dlp_new.exe"

echo %ESC%[38;2;198;198;108m^> Checking yt-dlp.exe version%ESC%[0m

set "CUR_VER="
if exist "%YTDLP%" (
    for /f "tokens=1 delims=" %%v in ('"%YTDLP%" --version 2^>nul') do set "CUR_VER=%%v" & goto :ver_got
)
:ver_got

if not defined CUR_VER (

    echo %ESC%[38;2;198;108;108m^> yt-dlp.exe not found, the latest version will be downloaded.%ESC%[0m
) else (
    <nul set /p=%ESC%[1A
    <nul set /p=%ESC%[2K
    echo %ESC%[38;2;108;198;183m^> Current version: %CUR_VER%%ESC%[0m
)

for /f "usebackq tokens=*" %%v in (`powershell -Command "(Invoke-WebRequest -UseBasicParsing -Uri 'https://api.github.com/repos/yt-dlp/yt-dlp/releases/latest').content | ConvertFrom-Json | Select-Object -ExpandProperty tag_name"`) do set "LATEST_VER=%%v"

if /i not "%CUR_VER%"=="%LATEST_VER%" (
    echo %ESC%[38;2;198;198;108m^> Updating yt-dlp.exe...%ESC%[0m
    powershell -Command "Invoke-WebRequest -Uri '%YTDLP_URL%' -OutFile '%TEMP_YTDLP%'"
    if errorlevel 1 (
	<nul set /p=%ESC%[1A
	<nul set /p=%ESC%[2K
        echo %ESC%[38;2;198;108;108m^> Error downloading yt-dlp.exe%ESC%[0m
        if not exist "%YTDLP%" (
	    <nul set /p=%ESC%[1A
	    <nul set /p=%ESC%[2K
            echo %ESC%[38;2;198;108;108m^> yt-dlp.exe missing, exiting...%ESC%[0m
            pause
            exit /b
        )
    ) else (
        move /Y "%TEMP_YTDLP%" "%YTDLP%" >nul
	<nul set /p=%ESC%[3A
	<nul set /p=%ESC%[2K
	<nul set /p=%ESC%[0J
        echo %ESC%[38;2;108;198;183m^> yt-dlp.exe updated to version %LATEST_VER%%ESC%[0m
    )
) else (
    <nul set /p=%ESC%[1A
    <nul set /p=%ESC%[2K
    echo %ESC%[38;2;108;198;183m^> yt-dlp.exe is up to date%ESC%[0m
    if exist "%TEMP_YTDLP%" del /f /q "%TEMP_YTDLP%"
)

:start
set "URL="
for /f "usebackq tokens=* delims=" %%i in (`powershell -command "Get-Clipboard"`) do set "URL=%%i"

if "%URL%"=="" (
    <nul set /p=%ESC%[1A
    <nul set /p=%ESC%[2K
    echo %ESC%[38;2;198;108;108m^> Clipboard is empty or does not contain a link%ESC%[0m
    set /p URL=%ESC%[38;2;198;198;108m^> Please paste the link manually and press Enter: %ESC%[0m
    if "%URL%"=="" (
        echo ^> No link entered, terminating the program.
        goto :end
    )
)

for /f "delims=" %%a in ('call "%YTDLP%" --get-id "!URL!" 2^>nul') do set "VIDEO_ID=%%a"

if not defined VIDEO_ID (
    echo %ESC%[38;2;198;108;108m^> Failed to get VIDEO ID%ESC%[0m
    goto asknewurl
)

<nul set /p=%ESC%[1A
<nul set /p=%ESC%[2K
echo %ESC%[38;2;198;198;108m^> Select quality:%ESC%[0m
echo [1] BEST VIDEO
echo [2] BEST AUDIO
echo [3] 4K (2160p)
echo [4] 2K (1440p)
echo [5] 1080p
echo [6] 720p
echo [7] 480p
echo [8] 360p
echo [9] 240p
echo [0] 144p

choice /C 1234567890 /N /T 15 /D 1 /M "Select number (or Timeout 15 = BEST VIDEO): " 2>nul
set "QUAL_CHOICE=%errorlevel%"

<nul set /p=%ESC%[1A
<nul set /p=%ESC%[2K
if "%QUAL_CHOICE%"=="1" set "QUALITY=BEST VIDEO" & set "DISPLAY_QUALITY=BEST VIDEO"
if "%QUAL_CHOICE%"=="2" set "QUALITY=BEST AUDIO" & set "DISPLAY_QUALITY=BEST AUDIO"
if "%QUAL_CHOICE%"=="3" set "QUALITY=2160" & set "DISPLAY_QUALITY=2160p"
if "%QUAL_CHOICE%"=="4" set "QUALITY=1440" & set "DISPLAY_QUALITY=1440p"
if "%QUAL_CHOICE%"=="5" set "QUALITY=1080" & set "DISPLAY_QUALITY=1080p"
if "%QUAL_CHOICE%"=="6" set "QUALITY=720" & set "DISPLAY_QUALITY=720p"
if "%QUAL_CHOICE%"=="7" set "QUALITY=480" & set "DISPLAY_QUALITY=480p"
if "%QUAL_CHOICE%"=="8" set "QUALITY=360" & set "DISPLAY_QUALITY=360p"
if "%QUAL_CHOICE%"=="9" set "QUALITY=240" & set "DISPLAY_QUALITY=240p"
if "%QUAL_CHOICE%"=="0" set "QUALITY=144" & set "DISPLAY_QUALITY=144p"

if "%QUALITY%"=="" set "QUALITY=BEST VIDEO" & set "DISPLAY_QUALITY=BEST VIDEO"

set "QUALITY_SAFE=!QUALITY!"
set "QUALITY_SAFE=!QUALITY_SAFE: =_!"

set "FOUND_FILE="
for %%f in (*.mp4 *.mkv *.webm *.mp3 *.m4a *.aac *.opus) do (
    echo %%~nf | findstr /i "!VIDEO_ID!_!QUALITY_SAFE!" >nul && set "FOUND_FILE=%%f"
)

if defined FOUND_FILE (
    <nul set /p=%ESC%[11A
    <nul set /p=%ESC%[2K
    <nul set /p=%ESC%[0J
    echo %ESC%[38;2;108;198;183m^▼ Selected: %DISPLAY_QUALITY% ▼%ESC%[0m
    echo %ESC%[38;2;198;108;108m^> File already exists: "!FOUND_FILE!"%ESC%[0m
    set "LATEST_FILE=!FOUND_FILE!"
    goto asknewurl
)

<nul set /p=%ESC%[1A
<nul set /p=%ESC%[2K
echo %ESC%[38;2;198;198;108m^> Creating compilation folder...%ESC%[0m
set "VIDEO_FOLDER=VIDLYT_!VIDEO_ID!_!QUALITY_SAFE!"
if not exist "!VIDEO_FOLDER!" (
    mkdir "!VIDEO_FOLDER!" >nul 2>&1
    if errorlevel 1 (
        echo ^> Creating folder... ERROR
        goto asknewurl
    )
) else (
    echo ^> Folder already exists, resuming download...
)
<nul set /p=%ESC%[1A
<nul set /p=%ESC%[2K
echo %ESC%[38;2;108;198;183m^> Folder created%ESC%[0m

<nul set /p=%ESC%[11A
<nul set /p=%ESC%[2K
<nul set /p=%ESC%[0J
echo %ESC%[38;2;108;198;183m^▼ Selected: %DISPLAY_QUALITY% ▼%ESC%[0m
echo %ESC%[38;2;198;198;108m^> Please, wait...%ESC%[0m

set "AUDIO_OPTS="

if "!QUALITY!"=="BEST VIDEO" (
    set "FORMAT=bestvideo+bestaudio/best"
) else if "!QUALITY!"=="BEST AUDIO" (
    set "FORMAT=bestaudio[ext=m4a]/bestaudio"
    set "AUDIO_OPTS=--extract-audio --audio-format m4a"
) else if "!QUALITY!"=="2160" (
    set "FORMAT=bestvideo[height<=2160]+bestaudio/best"
) else if "!QUALITY!"=="1440" (
    set "FORMAT=bestvideo[height<=1440]+bestaudio/best"
) else if "!QUALITY!"=="1080" (
    set "FORMAT=bestvideo[height<=1080]+bestaudio/best"
) else if "!QUALITY!"=="720" (
    set "FORMAT=bestvideo[height<=720]+bestaudio/best"
) else if "!QUALITY!"=="480" (
    set "FORMAT=bestvideo[height<=480]+bestaudio/best"
) else if "!QUALITY!"=="360" (
    set "FORMAT=bestvideo[height<=360]+bestaudio/best"
) else if "!QUALITY!"=="240" (
    set "FORMAT=bestvideo[height<=240]+bestaudio/best"
) else if "!QUALITY!"=="144" (
    set "FORMAT=bestvideo[height<=144]+bestaudio/best"
)

set "CONCURRENT_FRAGMENTS=16"

"%YTDLP%" --quiet --no-warnings --progress --no-playlist --age-limit 99 --geo-bypass --no-check-certificate --ignore-errors --no-abort-on-error --continue --retries 10 --fragment-retries 10 --referer=https://www.youtube.com/ --user-agent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/125 Safari/537.36" --windows-filenames -f "!FORMAT!" !AUDIO_OPTS! --concurrent-fragments %CONCURRENT_FRAGMENTS% -o "!VIDEO_FOLDER!\%%(title)s_%%(id)s_!QUALITY_SAFE!.%%(ext)s" "!URL!"

set "HAS_FILES="

for %%f in ("!VIDEO_FOLDER!\*.*") do (
    set "HAS_FILES=1"
    goto files_found
)

:files_found

if not defined HAS_FILES (
    echo ^> Nothing was downloaded.
    rmdir /q /s "!VIDEO_FOLDER!" >nul 2>&1
    goto asknewurl
)

<nul set /p=%ESC%[1A
<nul set /p=%ESC%[2K
echo %ESC%[38;2;198;198;108m^> Processing file...%ESC%[0m

powershell -NoProfile -Command "Get-ChildItem -LiteralPath '%VIDEO_FOLDER%' | ForEach-Object { $n=[IO.Path]::GetFileNameWithoutExtension($_.Name); $e=$_.Extension; $s=$n -replace '[^0-9A-Za-zА-Яа-я-]','_'; $s=$s -replace '_+','_'; $s=$s.Trim('_'); Rename-Item -LiteralPath $_.FullName -NewName ($s+$e) }"

move "!VIDEO_FOLDER!\*" "." >nul 2>&1
rmdir /q /s "!VIDEO_FOLDER!" >nul 2>&1

set "LATEST_FILE="
for /f "delims=" %%f in ('dir /b /o-d *.mp4 *.mkv *.webm *.mp3 *.m4a *.aac *.opus 2^>nul') do (
    set "LATEST_FILE=%%f"
    goto file_found
)
:file_found

:show_info
set "META_FILE=%TEMP%\vidlyt_probe.txt"
set "VIDEO_RES=Unknown"
set "VIDEO_CODEC=Unknown"
set "AUDIO_CODEC=Unknown"

if not defined LATEST_FILE goto skip_info
if not exist "!LATEST_FILE!" goto skip_info

echo !LATEST_FILE! | findstr /i "\.mp4 \.mkv \.webm" >nul
if not errorlevel 1 (
    ffprobe -v error -select_streams v:0 -show_entries stream=width,height,codec_name -of default=noprint_wrappers=1 "!LATEST_FILE!" > "%META_FILE%" 2>nul
    
    for /f "tokens=1,2,3 delims==" %%a in ('type "%META_FILE%" 2^>nul') do (
        if "%%a"=="width" set "VIDEO_WIDTH=%%b"
        if "%%a"=="height" set "VIDEO_HEIGHT=%%b"
        if "%%a"=="codec_name" set "VIDEO_CODEC=%%b"
    )
    
    if defined VIDEO_WIDTH if defined VIDEO_HEIGHT set "VIDEO_RES=!VIDEO_WIDTH!x!VIDEO_HEIGHT!"
    
    ffprobe -v error -select_streams a:0 -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 "!LATEST_FILE!" 2>nul > "%META_FILE%"
    set /p AUDIO_CODEC=<"%META_FILE%" 2>nul
    if "!AUDIO_CODEC!"=="" set "AUDIO_CODEC=None"
) else (
    ffprobe -v error -select_streams a:0 -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 "!LATEST_FILE!" > "%META_FILE%" 2>nul
    set /p AUDIO_CODEC=<"%META_FILE%" 2>nul
    set "VIDEO_RES=Audio only"
    set "VIDEO_CODEC=!AUDIO_CODEC!"
)

del "%META_FILE%" >nul 2>&1

:skip_info
for %%A in ("!LATEST_FILE!") do set "FILE_SIZE=%%~zA"

set /a SIZE_MB=FILE_SIZE/1024/1024
set /a SIZE_GB=SIZE_MB/1024

if !SIZE_GB! GTR 0 (
    set "SIZE_PRINT=!SIZE_GB! GB"
) else (
    set "SIZE_PRINT=!SIZE_MB! MB"
)

<nul set /p=%ESC%[2A
<nul set /p=%ESC%[2K
echo %ESC%[38;2;108;198;183m▼ DOWNLOAD COMPLETED ▼%ESC%[0m
echo ^> Link: !URL!
echo ^> File: !LATEST_FILE!
echo ^> Size: !SIZE_PRINT!

echo !LATEST_FILE! | findstr /i "\.mp4 \.mkv \.webm" >nul
if not errorlevel 1 (
    echo ^> Resolution: !VIDEO_RES!
    echo ^> Video Codec: !VIDEO_CODEC!
    if not "!AUDIO_CODEC!"=="None" echo ^> Audio Codec: !AUDIO_CODEC!
) else (
    echo ^> Audio Codec: !AUDIO_CODEC!
    echo ^> Format: Audio only
)

:asknewurl
echo.
set /p NEW_URL= %ESC%[38;2;198;198;108m^> Paste a new link (or press Enter to exit): %ESC%[0m

if "!NEW_URL!"=="" goto end

set "URL=%NEW_URL%"
goto start

:end
exit /b
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

:: Check for FFmpeg
set "target=ffmpeg.exe"
set "search_root=C:\Scripts\VIDLYT"
set "FFMPEG_PATH="

:: Search in specified folder
for /r "%search_root%" %%f in (*) do (
    if /i "%%~nxf"=="%target%" (
        set "FFMPEG_PATH=%%f"
        goto :ffmpeg_found
    )
)

:: If not found locally - check PATH
where ffmpeg >nul 2>&1
if %errorlevel% equ 0 (
    for /f "delims=" %%f in ('where ffmpeg') do (
        set "FFMPEG_PATH=%%f"
        goto :ffmpeg_found
    )
)

:: If FFmpeg is not found anywhere
echo.
echo [ !!! ERROR: FFmpeg not found !!! ]
echo.
echo Place ffmpeg.exe in:
echo - "%search_root%"
echo - OR install it system-wide and add to PATH.
echo.
pause
exit /b

:ffmpeg_found
echo Using FFmpeg: !FFMPEG_PATH!

:: Rest of the code (parameter input and conversion)
if /i "%FORMAT%"=="mp4" (
    set "BITRATE="
    for /f "tokens=* delims=" %%B in ('mshta "javascript:var bitrate=prompt('Enter bitrate in Mbps (e.g., 20):','20');if(bitrate==null) close();new ActiveXObject('Scripting.FileSystemObject').GetStandardStream(1).Write(bitrate);close()"') do (
        set "BITRATE=%%B"
    )
    if not defined BITRATE (
        echo Cancelled by user.
        exit /b
    )
    echo !BITRATE! | findstr /i "M" >nul
    if errorlevel 1 (
        set "BITRATE=!BITRATE!M"
    )
) else if /i "%FORMAT%"=="mp3" (
    set "BITRATE="
    for /f "tokens=* delims=" %%B in ('mshta "javascript:var bitrate=prompt('Enter bitrate in kbps (e.g., 192):','192');if(bitrate==null) close();new ActiveXObject('Scripting.FileSystemObject').GetStandardStream(1).Write(bitrate);close()"') do (
        set "BITRATE=%%B"
    )
    if not defined BITRATE (
        echo Cancelled by user.
        exit /b
    )
    echo !BITRATE! | findstr /i "k" >nul
    if errorlevel 1 (
        set "BITRATE=!BITRATE!k"
    )
) else if /i "%FORMAT%"=="wav" (
    rem Parameter input
    set "RATE="
    for /f "tokens=* delims=" %%r in ('mshta "javascript:var rate=prompt('Sample rate (44100 or 48000):','44100');if(rate==null) close();new ActiveXObject('Scripting.FileSystemObject').GetStandardStream(1).Write(rate);close()"') do (
        set "RATE=%%r"
    )
    if not defined RATE (
        echo Cancelled by user.
        exit /b
    )

    set "CHANNELS="
    for /f "tokens=* delims=" %%c in ('mshta "javascript:var channels=prompt('Channels (1-mono, 2-stereo):','2');if(channels==null) close();new ActiveXObject('Scripting.FileSystemObject').GetStandardStream(1).Write(channels);close()"') do (
        set "CHANNELS=%%c"
    )
    if not defined CHANNELS (
        echo Cancelled by user.
        exit /b
    )

    set "BITDEPTH="
    for /f "tokens=* delims=" %%b in ('mshta "javascript:var bitdepth=prompt('Bit depth (16, 24, 32):','16');if(bitdepth==null) close();new ActiveXObject('Scripting.FileSystemObject').GetStandardStream(1).Write(bitdepth);close()"') do (
        set "BITDEPTH=%%b"
    )
    if not defined BITDEPTH (
        echo Cancelled by user.
        exit /b
    )

    rem Validation
    if not "!RATE!"=="44100" if not "!RATE!"=="48000" set "RATE=44100"
    if not "!CHANNELS!"=="1" if not "!CHANNELS!"=="2" set "CHANNELS=2"
    if not "!BITDEPTH!"=="16" if not "!BITDEPTH!"=="24" if not "!BITDEPTH!"=="32" set "BITDEPTH=16"

    if "!BITDEPTH!"=="16" (
        set "CODEC=pcm_s16le"
    ) else if "!BITDEPTH!"=="24" (
        set "CODEC=pcm_s24le"
    ) else if "!BITDEPTH!"=="32" (
        set "CODEC=pcm_s32le"
    )
)

:: Conversion
if /i "%FORMAT%"=="mp4" (
    "!FFMPEG_PATH!" -y -hwaccel cuda -i "%INPUT_FILE%" -c:v h264_nvenc -b:v %BITRATE% -maxrate %BITRATE% -bufsize 50M -preset p3 -c:a aac -b:a 192k "%OUTPUT_FILE%"
) else if /i "%FORMAT%"=="mp3" (
    "!FFMPEG_PATH!" -y -i "%INPUT_FILE%" -vn -c:a libmp3lame -b:a %BITRATE% "%OUTPUT_FILE%"
) else if /i "%FORMAT%"=="wav" (
    "!FFMPEG_PATH!" -y -i "%INPUT_FILE%" -vn -acodec %CODEC% -ar %RATE% -ac %CHANNELS% "%OUTPUT_FILE%"
) else (
    echo Unsupported format: %FORMAT%
    pause
    exit /b
)

echo.
echo [ ====== CONVERSION TO %FORMAT:~0,3% SUCCESSFULLY COMPLETED ====== ]
echo Output file: %OUTPUT_FILE%
echo.
pause
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
    [System.Drawing.PointF]::new(12, 15),  # top left corner
    [System.Drawing.PointF]::new(23, 15),  # top right corner
    [System.Drawing.PointF]::new(17.5, 22) # bottom center corner
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
@="cmd.exe /c \"\"C:\\Scripts\\VIDLYT\\DOWNLOAD.cmd\"\""
PATHEND

UNINSTALLBEGIN
@echo off
chcp 65001 >nul
net session >nul 2>&1
if %errorlevel% neq 0 (
    powershell -Command "Start-Process -FilePath '%~f0' -Verb runAs"
    exit /b
)
title Uninstalling VIDLYT
reg delete "HKCR\*\shell\VIDLYT" /f
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\VIDLYT.SUBMP3" /f
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\VIDLYT.SUBMP4" /f
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\VIDLYT.SUBWAV" /f
rmdir /s /q "C:\Scripts\VIDLYT"
pause
exit
UNINSTALLEND

DONEMESSAGEBEGIN
@echo off
powershell -WindowStyle Hidden -Command "Add-Type -AssemblyName PresentationFramework; $xaml = '<Window xmlns=\"http://schemas.microsoft.com/winfx/2006/xaml/presentation\" Title=\"VIDLYT\" Height=\"280\" Width=\"420\" Background=\"Transparent\" WindowStartupLocation=\"CenterScreen\" ResizeMode=\"NoResize\" WindowStyle=\"None\" AllowsTransparency=\"True\"><Border Background=\"#0f0f0f\" CornerRadius=\"12\" Padding=\"20\" BorderBrush=\"#6cc7b8\" BorderThickness=\"2\"><Border.Resources><Style TargetType=\"Button\"><Setter Property=\"Width\" Value=\"90\"/><Setter Property=\"Height\" Value=\"35\"/><Setter Property=\"Background\" Value=\"#6cc7b8\"/><Setter Property=\"Foreground\" Value=\"#0f0f0f\"/><Setter Property=\"FontWeight\" Value=\"Bold\"/><Setter Property=\"BorderThickness\" Value=\"0\"/><Setter Property=\"Cursor\" Value=\"Hand\"/><Setter Property=\"FontSize\" Value=\"12\"/><Setter Property=\"Template\"><Setter.Value><ControlTemplate TargetType=\"Button\"><Border Background=\"{TemplateBinding Background}\" CornerRadius=\"8\"><ContentPresenter HorizontalAlignment=\"Center\" VerticalAlignment=\"Center\"/></Border></ControlTemplate></Setter.Value></Setter><Style.Triggers><Trigger Property=\"IsMouseOver\" Value=\"True\"><Setter Property=\"Background\" Value=\"#5ab8a8\"/></Trigger></Style.Triggers></Style></Border.Resources><Grid><Grid.RowDefinitions><RowDefinition Height=\"10\"/><RowDefinition Height=\"Auto\"/><RowDefinition Height=\"*\"/><RowDefinition Height=\"Auto\"/></Grid.RowDefinitions><TextBlock Grid.Row=\"1\" Text=\"Installation complete!\" FontWeight=\"Bold\" FontSize=\"14\" Foreground=\"#6cc7b8\" HorizontalAlignment=\"Center\" Margin=\"0,0,0,10\"/><StackPanel Grid.Row=\"2\" HorizontalAlignment=\"Center\" VerticalAlignment=\"Center\" Width=\"300\" Margin=\"0,10,0,0\"><TextBlock Text=\"1. Copy the link\" FontSize=\"13\" Foreground=\"#6cc7b8\" Margin=\"0,0,0,6\" TextAlignment=\"Left\"/><TextBlock Text=\"2. Right-click on your folder\" FontSize=\"13\" Foreground=\"#6cc7b8\" Margin=\"0,0,0,6\" TextAlignment=\"Left\"/><TextBlock FontSize=\"13\" Foreground=\"#6cc7b8\" TextAlignment=\"Left\"><Run Text=\"3. Select \"/><Run Text=\"Latropman''s VIDLYT\" FontWeight=\"Bold\"/></TextBlock></StackPanel><StackPanel Grid.Row=\"3\" Orientation=\"Horizontal\" HorizontalAlignment=\"Center\" Margin=\"0,30,0,0\"><Button Name=\"BlogButton\" Content=\"Go to blog\" Margin=\"0,0,10,0\"/><Button Name=\"CloseButton\" Content=\"Close\"/></StackPanel></Grid></Border></Window>'; $reader = New-Object System.Xml.XmlNodeReader ([xml]$xaml); $window = [Windows.Markup.XamlReader]::Load($reader); $window.FindName(\"BlogButton\").Add_Click({ Start-Process \"https://t.me/latropman\" }); $window.FindName(\"CloseButton\").Add_Click({ $window.Close() }); $window.ShowDialog() | Out-Null"
DONEMESSAGEEND