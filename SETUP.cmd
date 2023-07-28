@ECHO off
setlocal EnableDelayedExpansion

:: Get PG version 
FOR /F "usebackq tokens=*" %%G IN (`psql --version 2^>^&1`) DO SET "pgversion=%%G"
REM Extract the substring after (PostgreSQL), trim spaces, eliminate decimals
SET "pgversion=%pgversion:* (PostgreSQL)=%"
SET "pgversion=%pgversion: =%"
FOR /F "delims=." %%A IN ("%pgversion%") DO SET "pgversion=%%A"

:: Choose project config details
ECHO Enter your configuration details press enter for defaults
SET /p MY_MICROSERVICE_NAME=Enter your microservice name: 
SET /p MY_DATABASE_NAME=Enter your database name (defauls: same as microservice name): 
IF "%MY_DATABASE_NAME%"=="" SET "MY_DATABASE_NAME=%MY_MICROSERVICE_NAME%"
SET /p MY_SUPERUSER_NAME=Enter your superuser name (default: postgres): 
IF "%MY_SUPERUSER_NAME%"=="" SET "MY_SUPERUSER_NAME=postgres"
SET /p MY_POSTGRES_PASS=Enter your Postgres password, which you have SET when you installed postgres (default: 0000): 
IF "%MY_POSTGRES_PASS%"=="" SET "MY_POSTGRES_PASS=0000"
SET /p MY_DATA_FOLDER_PATH=Enter your data folder path (default: C:\Program Files\PostgreSQL\%pgversion%\data): 
IF "%MY_DATA_FOLDER_PATH%"=="" SET "MY_DATA_FOLDER_PATH=C:\Program Files\PostgreSQL\%pgversion%\data"
mkdir %MY_MICROSERVICE_NAME%

:: create .env file
ECHO BEGUN: creating the .env file
(
ECHO.DB_HOST=localhost
ECHO.DB_PORT=5432
ECHO.DB_USER=%MY_SUPERUSER_NAME%
ECHO.DB_PASS=%MY_POSTGRES_PASS%
ECHO.DB_NAME=%MY_MICROSERVICE_NAME%
) > "%MY_MICROSERVICE_NAME%\.env"
ECHO ENDED: creating the .env file


:: create .dockerfile
ECHO BEGUN: creating the .docker file
(
ECHO.# Use the official Node.js 20 image as a base image
ECHO.FROM node:20
ECHO.
ECHO.# SET the working directory inside the container
ECHO.WORKDIR /usr/src/app
ECHO.
ECHO.# Copy package.json and package-lock.json to the container
ECHO.COPY package*.json ./
ECHO.
ECHO.# Install dependencies
ECHO.RUN npm install
ECHO.
ECHO.# Copy the rest of the application code to the container
ECHO.COPY . .
ECHO.
ECHO.# Expose the port the application will run on
ECHO.EXPOSE 3000
ECHO.
ECHO.# Command to start the application
ECHO.CMD [ "npm", "run", "start:prod" ]
) > "%MY_MICROSERVICE_NAME%\.dockerfile"
ECHO ENDED: creating the .docker file


:: create docke-compose.yml
ECHO BEGUN: creating the docker-compose.yml file
(
ECHO.version: '3'
ECHO.services:
ECHO.  my-microservice:
ECHO.    build: .
ECHO.    ports:
ECHO.      - '3000:3000'
ECHO.    environment:
ECHO.      - POSTGRES_HOST=${DB_HOST}
ECHO.      - POSTGRES_PORT=${DB_PORT}
ECHO.      - POSTGRES_USER=${DB_USER}
ECHO.      - POSTGRES_PASSWORD=${DB_PASS}
ECHO.      - POSTGRES_DB=${DB_NAME}
ECHO.    depends_on:
ECHO.      - db
ECHO.  db:
ECHO.    image: postgres
ECHO.    environment:
ECHO.      - POSTGRES_USER=${DB_USER}
ECHO.      - POSTGRES_PASSWORD=${DB_PASS}
ECHO.      - POSTGRES_DB=${DB_NAME}
) > "%MY_MICROSERVICE_NAME%\docker-compose.yml"
ECHO ENDED: creating the docker-compose.yml file


:: Create the project
ECHO BEGUN: initialising Git
cd %MY_MICROSERVICE_NAME%
call git init
ECHO ENDED: initialising Git

:: Create the database
ECHO BEGUN: initialising the database
call pg_ctl status 2>&1 | FIND /I "server is running" > nul
IF %errorlevel% equ 0 (
    ECHO CHECK: PostgreSQL server is running. Stopping the server...
    call pg_ctl stop --pgdata="%MY_DATA_FOLDER_PATH%"
    timeout /t 5
) ELSE (
    ECHO CHECK: PostgreSQL server is not running.
)
ECHO CHECK: launching pg server
call pg_ctl start --pgdata="%MY_DATA_FOLDER_PATH%"
timeout /t 5
ECHO CHECK: creating new database
call createdb --username=%MY_SUPERUSER_NAME% %MY_DATABASE_NAME%
ECHO ENDED: initialising the database

:: Create the nest project
ECHO BEGUN: creating the nest microservice
call nest new %MY_MICROSERVICE_NAME%
ECHO ENDED: creating the nest microservice

:: Install Nest TypeORM and Nest Config
ECHO BEGUN: installing node packages
call npm install pg --save
call npm install @nestjs/typeorm @nestjs/config
call npm install dotenv
ECHO ENDED: installing node packages

endlocal