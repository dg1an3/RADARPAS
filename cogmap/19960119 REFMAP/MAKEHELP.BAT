@echo off
REM -- First make map file from App Studio generated resource.h
echo // MAKEHELP.BAT generated Help Map file.  Used by REFMAP.HPJ. >hlp\refmap.hm
echo. >>hlp\refmap.hm
echo // Commands (ID_* and IDM_*) >>hlp\refmap.hm
makehm ID_,HID_,0x10000 IDM_,HIDM_,0x10000 resource.h >>hlp\refmap.hm
echo. >>hlp\refmap.hm
echo // Prompts (IDP_*) >>hlp\refmap.hm
makehm IDP_,HIDP_,0x30000 resource.h >>hlp\refmap.hm
echo. >>hlp\refmap.hm
echo // Resources (IDR_*) >>hlp\refmap.hm
makehm IDR_,HIDR_,0x20000 resource.h >>hlp\refmap.hm
echo. >>hlp\refmap.hm
echo // Dialogs (IDD_*) >>hlp\refmap.hm
makehm IDD_,HIDD_,0x20000 resource.h >>hlp\refmap.hm
echo. >>hlp\refmap.hm
echo // Frame Controls (IDW_*) >>hlp\refmap.hm
makehm IDW_,HIDW_,0x50000 resource.h >>hlp\refmap.hm
REM -- Make help for Project REFMAP
call hc31 refmap.hpj
echo.
