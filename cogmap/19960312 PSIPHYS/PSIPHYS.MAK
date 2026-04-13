# Microsoft Visual C++ generated build script - Do not modify

PROJ = PSIPHYS
DEBUG = 1
PROGTYPE = 0
CALLER = 
ARGS = 
DLLS = 
D_RCDEFINES = /d_DEBUG
R_RCDEFINES = /dNDEBUG
ORIGIN = MSVC
ORIGIN_VER = 1.00
PROJPATH = C:\DEREK\PSIPHYS\
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
CFLAGS_D_WEXE = /nologo /G2 /W3 /Zi /AL /Od /D "_DEBUG" /FR /GA /Fd"PSIPHYS.PDB" 
CFLAGS_R_WEXE = /nologo /Gs /G2 /FPi87 /W3 /AL /O2 /D "NDEBUG" /FR /GA 
LFLAGS_D_WEXE = /NOLOGO /NOD /PACKC:61440 /STACK:10240 /ALIGN:16 /ONERROR:NOEXE /CO
LFLAGS_R_WEXE = /NOLOGO /NOD /PACKC:61440 /STACK:10240 /ALIGN:16 /ONERROR:NOEXE
LIBS_D_WEXE = lafxcwd oldnames libw llibcew commdlg olesvr olecli shell 
LIBS_R_WEXE = lafxcw oldnames libw llibcew commdlg olesvr olecli shell 
RCFLAGS = /nologo /z
RESFLAGS = /nologo /t
RUNFLAGS = 
DEFFILE = PSIPHYS.DEF
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
		PSIPHYS.SBR \
		MAINFRM.SBR \
		PSIPHDOC.SBR \
		PSIPHVW.SBR


PSIPHYS_RCDEP = c:\derek\psiphys\res\psiphys.ico \
	c:\derek\psiphys\res\psiphys.rc2


STDAFX_DEP = c:\derek\psiphys\stdafx.h


PSIPHYS_DEP = c:\derek\psiphys\stdafx.h \
	c:\derek\psiphys\psiphys.h \
	c:\derek\psiphys\mainfrm.h \
	c:\derek\psiphys\psiphdoc.h \
	c:\derek\psiphys\psiphvw.h


MAINFRM_DEP = c:\derek\psiphys\stdafx.h \
	c:\derek\psiphys\psiphys.h \
	c:\derek\psiphys\mainfrm.h


PSIPHDOC_DEP = c:\derek\psiphys\stdafx.h \
	c:\derek\psiphys\psiphys.h \
	c:\derek\psiphys\psiphdoc.h


PSIPHVW_DEP = c:\derek\psiphys\stdafx.h \
	c:\derek\psiphys\psiphys.h \
	c:\derek\psiphys\psiphdoc.h \
	c:\derek\psiphys\psiphvw.h


all:	$(PROJ).EXE $(PROJ).BSC

PSIPHYS.RES:	PSIPHYS.RC $(PSIPHYS_RCDEP)
	$(RC) $(RCFLAGS) $(RCDEFINES) -r PSIPHYS.RC

STDAFX.OBJ:	STDAFX.CPP $(STDAFX_DEP)
	$(CPP) $(CFLAGS) $(CPPCREATEPCHFLAG) /c STDAFX.CPP

PSIPHYS.OBJ:	PSIPHYS.CPP $(PSIPHYS_DEP)
	$(CPP) $(CFLAGS) $(CPPUSEPCHFLAG) /c PSIPHYS.CPP

MAINFRM.OBJ:	MAINFRM.CPP $(MAINFRM_DEP)
	$(CPP) $(CFLAGS) $(CPPUSEPCHFLAG) /c MAINFRM.CPP

PSIPHDOC.OBJ:	PSIPHDOC.CPP $(PSIPHDOC_DEP)
	$(CPP) $(CFLAGS) $(CPPUSEPCHFLAG) /c PSIPHDOC.CPP

PSIPHVW.OBJ:	PSIPHVW.CPP $(PSIPHVW_DEP)
	$(CPP) $(CFLAGS) $(CPPUSEPCHFLAG) /c PSIPHVW.CPP


$(PROJ).EXE::	PSIPHYS.RES

$(PROJ).EXE::	STDAFX.OBJ PSIPHYS.OBJ MAINFRM.OBJ PSIPHDOC.OBJ PSIPHVW.OBJ $(OBJS_EXT) $(DEFFILE)
	echo >NUL @<<$(PROJ).CRF
STDAFX.OBJ +
PSIPHYS.OBJ +
MAINFRM.OBJ +
PSIPHDOC.OBJ +
PSIPHVW.OBJ +
$(OBJS_EXT)
$(PROJ).EXE
$(MAPFILE)
c:\msvc\lib\+
c:\msvc\mfc\lib\+
c:\msvc\lib\+
$(LIBS)
$(DEFFILE);
<<
	link $(LFLAGS) @$(PROJ).CRF
	$(RC) $(RESFLAGS) PSIPHYS.RES $@
	@copy $(PROJ).CRF MSVC.BND

$(PROJ).EXE::	PSIPHYS.RES
	if not exist MSVC.BND 	$(RC) $(RESFLAGS) PSIPHYS.RES $@

run: $(PROJ).EXE
	$(PROJ) $(RUNFLAGS)


$(PROJ).BSC: $(SBRS)
	bscmake @<<
/o$@ $(SBRS)
<<
