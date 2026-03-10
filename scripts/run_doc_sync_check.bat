@echo off
setlocal

REM Windows 快捷入口：默认检查 staged 改动
where py >nul 2>nul
if %errorlevel%==0 (
    py -3 scripts\check_doc_sync.py %*
    exit /b %errorlevel%
)

where python >nul 2>nul
if %errorlevel%==0 (
    python scripts\check_doc_sync.py %*
    exit /b %errorlevel%
)

echo 未找到 Python。请先安装 Python 3，再运行此脚本。
exit /b 1
