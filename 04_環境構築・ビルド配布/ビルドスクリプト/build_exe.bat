@echo off
chcp 65001 > nul
echo ========================================================
echo  WITMOTIONバイナリ変換ツール EXE自動ビルドスクリプト
echo ========================================================

cd /d "%~dp0"
set SCRIPT_PATH=..\..\02_実装・コーディング\センサーデータ変換ツール\witmotion_converter.py
set DIST_DIR=..\配布パッケージ
set BUILD_DIR=..\..\build_temp

echo [1/3] PyInstallerの存在確認...
python -m pip show pyinstaller > nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [情報] PyInstallerをインストールします...
    python -m pip install pyinstaller
)

echo [2/3] スタンドアローンEXEをビルド中 (pyinstaller --onefile)...
python -m PyInstaller ^
    --onefile ^
    --name="witmotion_converter" ^
    --distpath="%DIST_DIR%" ^
    --workpath="%BUILD_DIR%" ^
    --specpath="%BUILD_DIR%" ^
    "%SCRIPT_PATH%"

if %ERRORLEVEL% EQU 0 (
    echo [3/3] ビルド成功！ 出力先: %DIST_DIR%\witmotion_converter.exe
    if exist "%BUILD_DIR%" rd /s /q "%BUILD_DIR%"
) else (
    echo [エラー] ビルドに失敗しました。
)

echo ========================================================
pause
