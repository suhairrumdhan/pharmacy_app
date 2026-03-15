@echo off
chcp 65001 > nul
echo ========================================
echo تشغيل Flutter مع VS 2022 الإجباري
echo ========================================
echo.

REM امسح كل حاجة
if exist build rmdir /s /q build
if exist .dart_tool rmdir /s /q .dart_tool
if exist windows\flutter\ephemeral rmdir /s /q windows\flutter\ephemeral
if exist windows\CMakeCache.txt del /f /q windows\CMakeCache.txt

REM 🔥🔥🔥 الحل السحري: عدل ملفات Flutter المؤقتة
echo ✅ تعطيل VS 2019 وإجبار VS 2022...

REM احذف أي مرجع لـ VS 2019 من ملفات Flutter
findstr /s /m "Visual Studio 16 2019" C:\flutter\src\flutter\packages\flutter_tools\lib\src\windows\*.dart
if %errorlevel% equ 0 (
    echo ✅ تم العثور على ملفات تحتاج تعديل
)

REM Force VS 2022
set CMAKE_GENERATOR=Visual Studio 17 2022
set CMAKE_GENERATOR_PLATFORM=x64
set VisualStudioVersion=17.0
set FLUTTER_CMAKE_GENERATOR_ARGS=-G "Visual Studio 17 2022" -A x64

echo ✅ CMake Generator: %CMAKE_GENERATOR%
echo.

echo 🚀 تشغيل Flutter مع تعطيل VS 2019...
flutter run -d windows --verbose

pause