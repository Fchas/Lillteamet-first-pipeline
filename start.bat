@echo off
REM First Pipeline Startup Script for Windows
REM Simple menu-driven startup for Docker and Kubernetes

setlocal enabledelayedexpansion
cd /d "%~dp0"

REM Colors (using ANSI escape codes)
for /F %%A in ('copy /Z "%~f0" nul') do set "BS=%%A"

:menu
cls
echo.
echo ╔════════════════════════════════════════╗
echo ║  FIRST PIPELINE STARTUP                ║
echo ║  Choose your deployment method         ║
echo ╚════════════════════════════════════════╝
echo.
echo  1) Docker Compose (Local Development)
echo  2) Minikube (Local Kubernetes)
echo  3) Kubernetes (Production)
echo  4) Helm (Production Recommended)
echo  5) Documentation
echo  6) Exit
echo.
set /p choice="Enter your choice (1-6): "

if "%choice%"=="1" goto docker
if "%choice%"=="2" goto minikube
if "%choice%"=="3" goto kubernetes
if "%choice%"=="4" goto helm
if "%choice%"=="5" goto docs
if "%choice%"=="6" goto end
goto invalid

:docker
echo.
echo Starting Docker Compose...
docker-compose up -d
if !errorlevel! equ 0 (
    echo.
    echo ✓ Docker Compose is running!
    echo.
    echo URL: http://localhost:3000
    echo Status: http://localhost:3000/status
    echo.
    echo Useful Commands:
    echo   View logs:     docker-compose logs -f
    echo   Stop:          docker-compose down
    echo   Rebuild:       docker-compose up --build
    echo.
    start http://localhost:3000
) else (
    echo.
    echo ✗ Failed to start Docker Compose
    echo Check that Docker is running and installed
)
pause
goto menu

:minikube
echo.
echo Starting Minikube...
if not exist "scripts\minikube-setup.sh" (
    echo ✗ Minikube setup script not found
    pause
    goto menu
)
powershell -Command "& 'scripts\minikube-setup.sh' full-setup"
if !errorlevel! equ 0 (
    echo.
    echo ✓ Minikube deployment complete!
    echo.
    echo Access the application:
    echo   kubectl port-forward -n first-pipeline svc/first-pipeline 8080:80
    echo   Then open http://localhost:8080
) else (
    echo.
    echo ✗ Minikube setup failed
)
pause
goto menu

:kubernetes
echo.
echo Starting Kubernetes deployment...
if not exist "scripts\k8s-deploy.sh" (
    echo ✗ k8s deployment script not found
    pause
    goto menu
)
powershell -Command "& 'scripts\k8s-deploy.sh' deploy"
if !errorlevel! equ 0 (
    echo.
    echo ✓ Kubernetes deployment complete!
    echo.
    echo Access the application:
    echo   kubectl port-forward -n first-pipeline svc/first-pipeline 8080:80
    echo   Then open http://localhost:8080
) else (
    echo.
    echo ✗ Kubernetes deployment failed
)
pause
goto menu

:helm
echo.
echo Starting Helm deployment...
echo This requires a Kubernetes cluster and Helm installed
helm install first-pipeline ./helm/first-pipeline -n first-pipeline --create-namespace
if !errorlevel! equ 0 (
    echo.
    echo ✓ Helm deployment complete!
    echo.
    echo Access the application:
    echo   kubectl port-forward -n first-pipeline svc/first-pipeline 8080:80
    echo   Then open http://localhost:8080
) else (
    echo.
    echo ✗ Helm deployment failed
)
pause
goto menu

:docs
cls
echo.
echo ╔════════════════════════════════════════╗
echo ║  DOCUMENTATION                         ║
echo ╚════════════════════════════════════════╝
echo.
echo Available Guides:
echo   • README.md - Project overview
echo   • START_HERE.md - Getting started
echo   • MINIKUBE_QUICK_REFERENCE.md - Minikube quick ref
echo   • MINIKUBE_SETUP.md - Minikube full guide
echo   • DEPLOY_K8S.md - Kubernetes deployment
echo   • INDEX.md - Master documentation
echo   • K8S_QUICK_START.md - k8s quick ref
echo.
pause
goto menu

:invalid
echo.
echo ✗ Invalid choice. Please choose 1-6.
timeout /t 2 /nobreak
goto menu

:end
echo.
echo Goodbye!
exit /b 0
