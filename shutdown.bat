@echo off
REM First Pipeline Shutdown Script for Windows
REM Cleanup script for Docker Compose and Kubernetes deployments
REM Kills port forwards, removes pods, and performs factory reset

setlocal enabledelayedexpansion
cd /d "%~dp0"

:menu
cls
echo.
echo ╔════════════════════════════════════════╗
echo ║  FIRST PIPELINE SHUTDOWN               ║
echo ║  Factory Reset & Cleanup                ║
echo ╚════════════════════════════════════════╝
echo.
echo  1) Full Cleanup (all of the below)
echo  2) Docker Compose Only
echo  3) Kubernetes Only (pods, port-forwards)
echo  4) Advanced (choose each option)
echo  5) Exit
echo.
set /p choice="Enter your choice (1-5): "

if "%choice%"=="1" goto full
if "%choice%"=="2" goto docker
if "%choice%"=="3" goto kubernetes
if "%choice%"=="4" goto advanced
if "%choice%"=="5" goto end
goto invalid

:full
echo.
call :docker_cleanup
call :kubernetes_cleanup
call :minikube_cleanup
goto success

:docker
echo.
call :docker_cleanup
goto success

:kubernetes
echo.
call :kubernetes_cleanup
goto success

:advanced
echo.
set /p dc="Stop Docker Compose? (y/n): "
if /i "%dc%"=="y" call :docker_cleanup

echo.
set /p k8s="Clean up Kubernetes (pods, port-forwards)? (y/n): "
if /i "%k8s%"=="y" call :kubernetes_cleanup

echo.
set /p mk="Configure Minikube? (y/n): "
if /i "%mk%"=="y" call :minikube_cleanup

goto success

:docker_cleanup
echo.
echo Stopping Docker Compose...
docker-compose ps >nul 2>&1
if !errorlevel! equ 0 (
    docker-compose down
    echo ✓ Docker Compose stopped
) else (
    echo ℹ Docker Compose not running
)
exit /b

:kubernetes_cleanup
echo.
echo ► Killing port-forward processes...
taskkill /F /IM kubectl.exe /T >nul 2>&1
if !errorlevel! equ 0 (
    echo ✓ Killed port-forward processes
) else (
    echo ℹ No port-forward processes running
)

echo.
echo ► Checking Kubernetes cluster connection...
kubectl cluster-info >nul 2>&1
if !errorlevel! neq 0 (
    echo ℹ Not connected to Kubernetes cluster
    exit /b
)
echo ✓ Connected to Kubernetes cluster

echo.
echo ► Deleting first-pipeline namespace...
kubectl get namespace first-pipeline >nul 2>&1
if !errorlevel! equ 0 (
    echo ℹ Deleting namespace 'first-pipeline'...
    kubectl delete namespace first-pipeline --ignore-not-found=true
    echo ℹ Waiting for namespace deletion...
    kubectl wait --for=delete namespace/first-pipeline --timeout=30s 2>nul
    echo ✓ Namespace deleted
) else (
    echo ℹ Namespace 'first-pipeline' not found
)

exit /b

:minikube_cleanup
echo.
echo ► Checking Minikube status...
minikube status -p first-pipeline >nul 2>&1
if !errorlevel! neq 0 (
    echo ℹ Minikube cluster 'first-pipeline' not running
    exit /b
)

echo.
echo Minikube cluster is running. Choose an option:
echo.
echo  1) Keep cluster running (resources already cleaned)
echo  2) Stop cluster (saves resources)
echo  3) Delete cluster (factory reset)
echo.
set /p mk_choice="Enter your choice (1-3): "

if "%mk_choice%"=="1" (
    echo ℹ Keeping Minikube cluster running
) else if "%mk_choice%"=="2" (
    echo.
    echo ► Stopping Minikube cluster...
    minikube stop -p first-pipeline
    echo ✓ Minikube cluster stopped
) else if "%mk_choice%"=="3" (
    echo.
    set /p confirm="Are you sure you want to DELETE the cluster? (yes/no): "
    if /i "!confirm!"=="yes" (
        echo.
        echo ► Deleting Minikube cluster...
        minikube delete -p first-pipeline
        echo ✓ Minikube cluster deleted
    ) else (
        echo ℹ Cluster deletion cancelled
    )
)
exit /b

:success
cls
echo.
echo ╔════════════════════════════════════════╗
echo ║  CLEANUP COMPLETE                      ║
echo ╚════════════════════════════════════════╝
echo.
echo Next steps:
echo   • To restart: ./start.sh
echo   • Check status: kubectl get all -n first-pipeline
echo   • View Minikube status: minikube status
echo.
pause
goto menu

:invalid
echo.
echo ✗ Invalid choice. Please choose 1-5.
timeout /t 2 /nobreak
goto menu

:end
echo.
echo Goodbye!
exit /b 0
