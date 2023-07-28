@ECHO off
setlocal EnableDelayedExpansion

:: MANUALLY Open Accounts on:
  :: GitHub: https://github.com 
  :: Google: https://cloud.google.com (FOR access to GCP - Google Cloud Platform)

:: Check IF the script is running as an administrator
net session >nul 2>&1
IF %errorLevel% == 1 (
    ECHO ERROR: This script requires administrator privileges. Please run it as an administrator and try again.
    PAUSE
    EXIT /b 1
) ELSE ( 
    ECHO CHECK: Running with administrator privileges 
)

:: Check internet connection
ping 8.8.8.8 -n 1 -w 1000 >nul
IF %errorLevel% == 1 (
    ECHO ERROR: This script requires an active internet connection. Please check your internet connection and try again.
    PAUSE
    EXIT /b 1
) ELSE ( 
    ECHO CHECK: Internet connection OK 
)

:: Setup Winget
winget -v >nul 2>&1
IF %errorlevel% == 1 (
    curl.exe -o winget.msixbundle -L https://github.com/microsoft/winget-cli/releases/latest/download/winget.msixbundle
    start /wait AppInstaller.exe /install winget.msixbundle
    del winget.msixbundle
    winget upgrade --all
    ECHO ENDED:
) ELSE (
    ECHO CHECK: Winget is already installed
)

:: Setup Git
WHERE git > nul
IF %errorlevel% equ 0 (
    ECHO CHECK: Git is already installed.
) ELSE (
    winget install Git.Git
    SETX /M PATH "%PATH%;C:\Program Files\Git\bin"
    ECHO BEGIN: GitHub login

    :: Prompt the user FOR name and save the input to NAME variable
    SET /p "NAME=Enter your name: "
    SET /p "EMAIL=Enter your email: "
    :: Remove leading and trailing spaces from EMAIL
    FOR /f "tokens=* delims= " %%a IN ("!EMAIL!") DO SET "EMAIL=%%a"
    FOR /f "tokens=* delims= " %%a IN ("!NAME!") DO SET "NAME=%%a"

    :: SET Git configuration IF confirmed
    git config --global user.name "!NAME!" 
    git config --global user.email "!EMAIL!" 
    git config --global core.editor "code --wait" 
    git config --global --list

    ECHO ENDED: GitHub login
)

:: Setup VSCode
WHERE code > nul
IF %errorlevel% equ 0 (
    ECHO CHECK: Visual Studio Code is already installed.
) ELSE (
    REM Install Visual Studio Code using winget
    winget install Microsoft.VisualStudioCode

    REM Add Visual Studio Code bIN directory to the system PATH
    SETX /M PATH "%PATH%;%LOCALAPPDATA%\Programs\Microsoft VS Code\bin"

    REM Register "Open with VSCode" context menu command FOR folders
    reg add "HKEY_CLASSES_ROOT\Directory\Background\shell\Open with VSCode\command" /ve /d "\"%LOCALAPPDATA%\\Programs\\Microsoft VS Code\\Code.exe\" \"%V%\"" /f
)
REM Install Visual Studio Code extensions
call code --force --install-extension dbaeumer.vscode-eslint
call code --force --install-extension ms-azuretools.vscode-docker
call code --force --install-extension ms-ossdata.vscode-postgresql
call code --force --install-extension esbenp.prettier-vscode

:: Setup Docker
WHERE docker > nul
IF %errorlevel% equ 0 (
    ECHO CHECK: Docker Desktop is already installed.
) ELSE (
    winget install Docker.DockerDesktop
    SETX /M PATH "%PATH%;C:\Program Files\Docker\Docker\resources\bin;C:\ProgramData\DockerDesktop\version-bin"
)

:: Setup dBeaver
WHERE dbeaver > nul
IF %errorlevel% equ 0 (
    ECHO CHECK: DBeaver is already installed.
) ELSE (
    REM Install DBeaver using winget
    winget install dbeaver.dbeaver
)

:: Setup Google Cloud SDK
WHERE gcloud > nul
IF %errorlevel% equ 0 (
    ECHO CHECK: Google Cloud SDK is already installed.
) ELSE (
    REM Install Google Cloud SDK using winget
    winget install Google.CloudSDK
)
SETX /M PATH "%PATH%;C:\Program Files\Google\Cloud SDK\google-cloud-sdk\bin"

:: Setup Node.js
WHERE node > nul
IF %errorlevel% equ 0 (
    ECHO CHECK: Node.js is already installed.
) ELSE (
    winget install OpenJS.NodeJS
)
SETX /M PATH "%PATH%;C:\Program Files\nodejs"

:: Setup Nest.js
npm list -g @nestjs/cli > nul 2>&1
IF %errorlevel% equ 0 (
    ECHO CHECK: @nestjs/cli is already installed.
) ELSE (
    npm install -g @nestjs/cli
)

:: Setup Postgres
WHERE psql > nul
IF %errorlevel% equ 0 (
    ECHO CHECK: PostgreSQL is already installed.
) ELSE (
    REM Install PostgreSQL using winget
    winget install -e --id PostgreSQL.PostgreSQL
)

:: Update PATH 
FOR /F "usebackq tokens=*" %%G IN (`psql --version 2^>^&1`) DO SET "pgversion=%%G"
REM Extract the substring after (PostgreSQL), trim spaces, eliminate decimals
SET "pgversion=%pgversion:* (PostgreSQL)=%"
SET "pgversion=%pgversion: =%"
FOR /F "delims=." %%A IN ("%pgversion%") DO SET "pgversion=%%A"
ECHO CHECK: PostgreSQL version: %pgversion%
ECHO CHECK: Current PGDATA: %PGDATA%
ECHO CHECK: %PATH% | MORE

REM Set Postgres PGDATA environment variable
IF  NOT "%pgversion%" == "" (
    setx PGDATA "C:\Program Files\PostgreSQL\%pgversion%\data" /M
)

REM Check if the pathToAdd is already part of the PATH
SET "pathToAdd=C:\Program Files\PostgreSQL\%pgversion%\bin"
SET "currentPATH="
for %%I in ("%PATH:;=" "%") do (
    if /I "%%~I"=="%pathToAdd%" (
        SET "currentPATH=1"
        ECHO CHECK: %currentPATH%
        ECHO CHECK: Already part of PATH
        goto :PATH_CHECK_DONE
    )
)

:PATH_CHECK_DONE
IF NOT "%pgversion%" == "" (
    IF NOT DEFINED currentPATH (
        ECHO %currentPATH%
        setx PATH "%PATH%;%pathToAdd%" /M
        ECHO ENDED: Added to PATH
    )
)

endlocal