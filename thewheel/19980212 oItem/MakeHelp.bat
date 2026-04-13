@echo off
REM -- First make map file from Microsoft Visual C++ generated resource.h
echo // MAKEHELP.BAT generated Help Map file.  Used by THEWHEEL.HPJ. >"hlp\theWheel.hm"
echo. >>"hlp\theWheel.hm"
echo // Commands (ID_* and IDM_*) >>"hlp\theWheel.hm"
makehm ID_,HID_,0x10000 IDM_,HIDM_,0x10000 resource.h >>"hlp\theWheel.hm"
echo. >>"hlp\theWheel.hm"
echo // Prompts (IDP_*) >>"hlp\theWheel.hm"
makehm IDP_,HIDP_,0x30000 resource.h >>"hlp\theWheel.hm"
echo. >>"hlp\theWheel.hm"
echo // Resources (IDR_*) >>"hlp\theWheel.hm"
makehm IDR_,HIDR_,0x20000 resource.h >>"hlp\theWheel.hm"
echo. >>"hlp\theWheel.hm"
echo // Dialogs (IDD_*) >>"hlp\theWheel.hm"
makehm IDD_,HIDD_,0x20000 resource.h >>"hlp\theWheel.hm"
echo. >>"hlp\theWheel.hm"
echo // Frame Controls (IDW_*) >>"hlp\theWheel.hm"
makehm IDW_,HIDW_,0x50000 resource.h >>"hlp\theWheel.hm"
REM -- Make help for Project THEWHEEL


echo Building Win32 Help files
start /wait hcw /C /E /M "hlp\theWheel.hpj"
if errorlevel 1 goto :Error
if not exist "hlp\theWheel.hlp" goto :Error
if not exist "hlp\theWheel.cnt" goto :Error
echo.
if exist Debug\nul copy "hlp\theWheel.hlp" Debug
if exist Debug\nul copy "hlp\theWheel.cnt" Debug
if exist Release\nul copy "hlp\theWheel.hlp" Release
if exist Release\nul copy "hlp\theWheel.cnt" Release
echo.
goto :done

:Error
echo hlp\theWheel.hpj(1) : error: Problem encountered creating help file

:done
echo.
