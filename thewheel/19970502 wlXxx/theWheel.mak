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
PROJPATH = C:\PROJECTS\THEWHEEL\SRC\
USEMFC = 1
CC = cl
CPP = cl
CXX = cl
CCREATEPCHFLAG = 
CPPCREATEPCHFLAG = /YcSTDAFX.H
CUSEPCHFLAG = 
CPPUSEPCHFLAG = /YuSTDAFX.H
FIRSTC =             
FIRSTCPP = STDAFX.CPP  
RC = rc
CFLAGS_D_WEXE = /nologo /G2 /FPi87 /W3 /Zi /AL /D "_DEBUG" /FR /GA /Fd"THEWHEEL.PDB" /Fp"THEWHEEL.PCH" 
CFLAGS_R_WEXE = /nologo /Gs /G2 /FPi87 /Zp4 /W3 /AL /O2 /Ox /Ob2 /OV8 /D "NDEBUG" /FR /GA 
LFLAGS_D_WEXE = /NOLOGO /NOD /PACKC:61440 /STACK:20000 /ALIGN:16 /ONERROR:NOEXE /CO  
LFLAGS_R_WEXE = /NOLOGO /NOD /PACKC:61440 /STACK:10240 /ALIGN:16 /ONERROR:NOEXE  
LIBS_D_WEXE = lafxcwd oldnames libw llibcew commdlg.lib olecli.lib shell.lib 
LIBS_R_WEXE = lafxcw oldnames libw llibcew commdlg.lib olecli.lib olesvr.lib shell.lib 
RCFLAGS = /nologo /z 
RESFLAGS = /nologo /t /k
RUNFLAGS = 
DEFFILE = THEWHEEL.DEF
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
SBRS = STDAFX.SBR \
		THEWHEEL.SBR \
		WLOBJECT.SBR \
		WLCHILDV.SBR \
		WLFRAMEV.SBR \
		WLEEVORG.SBR


STDAFX_DEP = c:\projects\thewheel\src\stdafx.h


THEWHEEL_DEP = c:\projects\thewheel\src\stdafx.h \
	c:\projects\thewheel\src\thewheel.h \
	c:\projects\thewheel\src\wlframev.h \
	c:\projects\thewheel\src\wlchildv.h \
	c:\projects\thewheel\src\wlobject.h \
	c:\projects\thewheel\src\wleevorg.h


THEWHEEL_RCDEP = c:\projects\thewheel\src\thewheel.ico \
	c:\projects\thewheel\src\thewheel.rc2


WLOBJECT_DEP = c:\projects\thewheel\src\stdafx.h \
	c:\projects\thewheel\src\thewheel.h \
	c:\projects\thewheel\src\wlobject.h


WLCHILDV_DEP = c:\projects\thewheel\src\stdafx.h \
	c:\projects\thewheel\src\wlframev.h \
	c:\projects\thewheel\src\wlchildv.h \
	c:\projects\thewheel\src\wlobject.h


WLFRAMEV_DEP = c:\projects\thewheel\src\stdafx.h \
	c:\projects\thewheel\src\thewheel.h \
	c:\projects\thewheel\src\wlframev.h \
	c:\projects\thewheel\src\wlchildv.h \
	c:\projects\thewheel\src\wlobject.h


WLEEVORG_DEP = c:\projects\thewheel\src\stdafx.h \
	c:\projects\thewheel\src\wleevorg.h \
	c:\projects\thewheel\src\wlobject.h


all:	$(PROJ).EXE $(PROJ).BSC

STDAFX.OBJ:	STDAFX.CPP $(STDAFX_DEP)
	$(CPP) $(CFLAGS) $(CPPCREATEPCHFLAG) /c STDAFX.CPP

THEWHEEL.OBJ:	THEWHEEL.CPP $(THEWHEEL_DEP)
	$(CPP) $(CFLAGS) $(CPPUSEPCHFLAG) /c THEWHEEL.CPP

THEWHEEL.RES:	THEWHEEL.RC $(THEWHEEL_RCDEP)
	$(RC) $(RCFLAGS) $(RCDEFINES) -r THEWHEEL.RC

WLOBJECT.OBJ:	WLOBJECT.CPP $(WLOBJECT_DEP)
	$(CPP) $(CFLAGS) $(CPPUSEPCHFLAG) /c WLOBJECT.CPP

WLCHILDV.OBJ:	WLCHILDV.CPP $(WLCHILDV_DEP)
	$(CPP) $(CFLAGS) $(CPPUSEPCHFLAG) /c WLCHILDV.CPP

WLFRAMEV.OBJ:	WLFRAMEV.CPP $(WLFRAMEV_DEP)
	$(CPP) $(CFLAGS) $(CPPUSEPCHFLAG) /c WLFRAMEV.CPP

WLEEVORG.OBJ:	WLEEVORG.CPP $(WLEEVORG_DEP)
	$(CPP) $(CFLAGS) $(CPPUSEPCHFLAG) /c WLEEVORG.CPP


$(PROJ).EXE::	THEWHEEL.RES

$(PROJ).EXE::	STDAFX.OBJ THEWHEEL.OBJ WLOBJECT.OBJ WLCHILDV.OBJ WLFRAMEV.OBJ WLEEVORG.OBJ $(OBJS_EXT) $(DEFFILE)
	echo >NUL @<<$(PROJ).CRF
STDAFX.OBJ +
THEWHEEL.OBJ +
WLOBJECT.OBJ +
WLCHILDV.OBJ +
WLFRAMEV.OBJ +
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
