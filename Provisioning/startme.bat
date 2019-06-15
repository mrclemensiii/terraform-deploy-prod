@echo off
SET scriptpath=%~dp0
SETLOCAL ENABLEEXTENSIONS
SETLOCAL ENABLEDELAYEDEXPANSION
SET AWS_PROFILE=prod

CD scriptpath
title WideOrbit AWS Provisioning Script
:home
cls
echo.
echo Select a task:
echo ==============
echo.
echo 1) Deploy WO Traffic/WO Network
echo 2) Deploy WO Program
echo 3) Exit
echo.
set product=
set /p product=Select option :
if "%product%"=="1" set product=WOTraffic& goto Customer
if "%product%"=="2" set product=WOProgram& goto Customer
if "%product%"=="3" goto Exit
goto home

:Customer
title WideOrbit AWS Provisioning Script - "%product%"
cls
echo.
echo Enter the Customer Name:
echo ========================
echo.
set /p cname=Customer Name :
if not defined cname echo Please enter the Customer Name & pause & goto Customer
goto Environment

:Environment
title WideOrbit AWS Provisioning Script - "%product%" - "%cname%"
cls
echo.
echo Enter Environment:
echo ==================
echo.
echo 1) Production
echo 2) UAT
echo 3) Staging
echo 4) Test
echo 5) DEV
echo 6) DR
echo.
echo 7) Go Back to previous menu
echo.
set /p env=Select Environment :
if "%env%"=="1" set env=PRD& goto Deploy
if "%env%"=="2" set env=UAT& goto Deploy
if "%env%"=="3" set env=STG& goto Deploy
if "%env%"=="4" set env=TST& goto Deploy
if "%env%"=="5" set env=DEV& goto Deploy
if "%env%"=="6" set env=DR& goto Deploy
if "%env%"=="7" goto Customer
goto Environment

:Deploy
title WideOrbit AWS Provisioning Script - "%product%" - "%cname%" - "%env%"
cls
echo.
if exist "Customers\%cname%-%product%-%env%" goto FolderError
cd Customers
mkdir "%cname%-%product%-%env%"
copy ..\%product%\*.* "%cname%-%product%-%env%"\*.*
cd "%cname%-%product%-%env%"
cls
echo.
echo The following folder structure has been created:
echo.
echo      %cd%
echo.
echo A new command window will open in this directory with Terraform initiated
echo Your next steps are as follows:
echo.
echo 1) Copy the terraform.tfvars file into this directory.  You can find it
echo in the \Provisioning\%product%\template folder.  Make sure it is updated
echo with all the appropriate variables from the deployment spreadsheet.
echo.
echo 2) Run "Terraform plan" to validate that there are no issues with the
echo terraform.tfvars file and what needs to be deployed.
echo.
echo 3) Run "Terraform apply" to kick off the actual deployment.
echo.
echo.
pause
start cmd.exe /k "terraform init"
REM start code ..\..\%product%\template\terraform.tfvars
goto End 

:FolderError
cls
echo.
echo The folder structure %CD%\%cname%-%product%-%env% already exist
echo Please check and make sure you have entered everything correctly.
echo.
echo If you have then there has already been a previous deployment
echo for this environment.  Please make sure you are not trying to 
echo re-deploy something that already exists.
echo.
echo If you are just trying to re-run a deployment that didn't complete
echo previously, make sure you clean up the folder structure that was
echo created here: %CD%\%cname%-%product%-%env%
echo.
pause
exit

End:
exit
