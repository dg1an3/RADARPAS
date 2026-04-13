# Microsoft Visual C++ generated build script - Do not modify

PROJ = THEWHEEL
DEBUG = 1
PROGTYPE = 0
CALLER = 
ARGS = 
DLLS = 
D_RCDEFINES = /d_DEBUG 
R_RCDEFINES = /dNDEBUG 
ORIGIN = MSVC
ORIGIN_VER = 1.00
PROJPATH = C:\THEWHEEL\SRC\
USEMFC = 1
CC = cl
CPP = cl
CXX = cl
CCREATEPCHFLAG = 
CPPCREATEPCHFLAG = 
CUSEPCHFLAG = 
CPPUSEPCHFLAG = 
FIRSTC =             
FIRSTCPP = STDAFX.CPP  
RC = rc
CFLAGS_D_WEXE = /nologo /G2 /FPi87 /W3 /Zi /AL /YX /D "_DEBUG" /FR /GA /Fd"THEWHEEL.PDB" /Fp"THEWHEEL.PCH"
CFLAGS_R_WEXE = /nologo /Gs /G2 /FPi87 /Zp4 /W3 /AL /YX /O2 /Ox /Ob2 /OV8 /D "NDEBUG" /FR /GA 
LFLAGS_D_WEXE = /NOLOGO /NOD /PACKC:61440 /STACK:20000 /ALIGN:16 /ONERROR:NOEXE /CO  
LFLAGS_R_WEXE = /NOLOGO /NOD /PACKC:61440 /STACK:10240 /ALIGN:16 /ONERROR:NOEXE  
LIBS_D_WEXE = lafxcwd oldnames libw llibcew commdlg.lib olecli.lib shell.lib 
LIBS_R_WEXE = lafxcw oldnames libw llibcew commdlg.lib olecli.lib olesvr.lib shell.lib 
RCFLAGS = /nologo /z 
RESFLAGS = /nologo /t /k
RUNFLAGS = 
DEFFILE = RES\THEWHEEL.DEF
OBJS_EXT = 
LIBS_EXT = 
!if "$(DEBUG)" == "1"
CFLAGS = $(CFLAGS_D_WEXE)
LFLAGS = $(LFLAGS_D_WEXE)
LIBS = $(LIBS_D_WEXE)
MAPFILE = nul
RCDEFINES = $(D_RCDEFINES)
!else
CFLAGS = $(CFLAGS_R_WEXE)
LFLAGS = $(LFLAGS_R_WEXE)
LIBS = $(LIBS_R_WEXE)
MAPFILE = nul
RCDEFINES = $(R_RCDEFINES)
!endif
!if [if exist MSVC.BND del MSVC.BND]
!endif
SBRS = THEWHEEL.SBR \
		STDAFX.SBR \
		WLOBJECT.SBR \
		WLVIEW.SBR \
		WLCHILDW.SBR \
		WLFRAMEW.SBR \
		WLEEVORG.SBR


THEWHEEL_DEP = c:\thewheel\src\stdafx.h \
	c:\thewheel\src\class/eevorg/wleevorg.h \
	c:\thewheel\src\class/object/wlobject.h \
	c:\thewheel\src\class/wnd/wlframew.h \
	c:\thewheel\src\class\view\wlview.h \
	c:\thewheel\src\class\object\wlobject.h \
	c:\thewheel\src\class/wnd/wlchildw.h \
	c:\thewheel\src\app\thewheel.h


THEWHEEL_RCDEP = c:\thewheel\src\res\bitmaps\thewheel.ico \
	c:\thewheel\src\res\thewheel.rc2


STDAFX_DEP = c:\thewheel\src\stdafx.h


WLOBJECT_DEP = c:\thewheel\src\stdafx.h \
	c:\thewheel\src\class\object\wlobject.h


WLVIEW_DEP = c:\thewheel\src\stdafx.h \
	c:\thewheel\src\class\view\wlview.h \
	c:\thewheel\src\class\object\wlobject.h


WLCHILDW_DEP = c:\thewheel\src\stdafx.h \
	c:\thewheel\src\class\wnd\wlframew.h \
	c:\thewheel\src\class\view\wlview.h \
	c:\thewheel\src\class\object\wlobject.h \
	c:\thewheel\src\class\wnd\wlchildw.h


WLFRAMEW_DEP = c:\thewheel\src\stdafx.h \
	c:\thewheel\src\class\wnd\wlchildw.h \
	c:\thewheel\src\class\view\wlview.h \
	c:\thewheel\src\class\object\wlobject.h \
	c:\thewheel\src\class\wnd\wlframew.h


WLEEVORG_DEP = c:\thewheel\src\stdafx.h \
	c:\thewheel\src\class\eevorg\wleevorg.h \
	c:\thewheel\src\class/object/wlobject.h


all:	$(PROJ).EXE $(PROJ).BSC

THEWHEEL.OBJ:	APP\THEWHEEL.CPP $(THEWHEEL_DEP)
	$(CPP) $(CFLAGS) $(CPPUSEPCHFLAG) /c APP\THEWHEEL.CPP

THEWHEEL.RES:	RES\THEWHEEL.RC $(THEWHEEL_RCDEP)
	$(RC) $(RCFLAGS) $(RCDEFINES) -r -FoC:\THEWHEEL\SRC\THEWHEEL.RES RES\THEWHEEL.RC

STDAFX.OBJ:	STDAFX.CPP $(STDAFX_DEP)
	$(CPP) $(CFLAGS) $(CPPCREATEPCHFLAG) /c STDAFX.CPP

WLOBJECT.OBJ:	CLASS\OBJECT\WLOBJECT.CPP $(WLOBJECT_DEP)
	$(CPP) $(CFLAGS) $(CPPUSEPCHFLAG) /c CLASS\OBJECT\WLOBJECT.CPP

WLVIEW.OBJ:	CLASS\VIEW\WLVIEW.CPP $(WLVIEW_DEP)
	$(CPP) $(CFLAGS) $(CPPUSEPCHFLAG) /c CLASS\VIEW\WLVIEW.CPP

WLCHILDW.OBJ:	CLASS\WND\WLCHILDW.CPP $(WLCHILDW_DEP)
	$(CPP) $(CFLAGS) $(CPPUSEPCHFLAG) /c CLASS\WND\WLCHILDW.CPP

WLFRAMEW.OBJ:	CLASS\WND\WLFRAMEW.CPP $(WLFRAMEW_DEP)
	$(CPP) $(CFLAGS) $(CPPUSEPCHFLAG) /c CLASS\WND\WLFRAMEW.CPP

WLEEVORG.OBJ:	CLASS\EEVORG\WLEEVORG.CPP $(WLEEVORG_DEP)
	$(CPP) $(CFLAGS) $(CPPUSEPCHFLAG) /c CLASS\EEVORG\WLEEVORG.CPP


$(PROJ).EXE::	THEWHEEL.RES

$(PROJ).EXE::	THEWHEEL.OBJ STDAFX.OBJ WLOBJECT.OBJ WLVIEW.OBJ WLCHILDW.OBJ WLFRAMEW.OBJ \
	WLEEVORG.OBJ $(OBJS_EXT) $(DEFFILE)
	echo >NUL @<<$(PROJ).CRF
THEWHEEL.OBJ +
STDAFX.OBJ +
WLOBJECT.OBJ +
WLVIEW.OBJ +
WLCHILDW.OBJ +
WLFRAMEW.OBJ +
WLEEVORG.OBJ +
$(OBJS_EXT)
$(PROJ).EXE
$(MAPFILE)
c:\msvc\lib\+
c:\msvc\mfc\lib\+
$(LIBS)
$(DEFFILE);
<<
	link $(LFLAGS) @$(PROJ).CRF
	$(RC) $(RESFLAGS) THEWHEEL.RES $@
	@copy $(PROJ).CRF MSVC.BND

$(PROJ).EXE::	THEWHEEL.RES
	if not exist MSVC.BND 	$(RC) $(RESFLAGS) THEWHEEL.RES $@

run: $(PROJ).EXE
	$(PROJ) $(RUNFLAGS)


$(PROJ).BSC: $(SBRS)
	bscmake @<<
/o$@ $(SBRS)
<<
