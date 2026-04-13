# Microsoft Visual C++ generated build script - Do not modify

PROJ = REFMAP
DEBUG = 1
PROGTYPE = 0
CALLER = 
ARGS = 
DLLS = 
D_RCDEFINES = /d_DEBUG 
R_RCDEFINES = /dNDEBUG 
ORIGIN = MSVC
ORIGIN_VER = 1.00
PROJPATH = C:\DEREK\REFMAP\
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
CFLAGS_D_WEXE = /nologo /G2 /W3 /Zi /AL /Od /D "_DEBUG" /FR /GA /Fd"REFMAP.PDB" 
CFLAGS_R_WEXE = /nologo /Gs /G2 /W3 /AM /O1 /D "NDEBUG" /FR /GA 
LFLAGS_D_WEXE = /NOLOGO /NOD /PACKC:61440 /STACK:10240 /ALIGN:16 /ONERROR:NOEXE /CO
LFLAGS_R_WEXE = /NOLOGO /NOD /PACKC:61440 /STACK:10240 /ALIGN:16 /ONERROR:NOEXE
LIBS_D_WEXE = lafxcwd oldnames libw llibcew commdlg olesvr olecli shell 
LIBS_R_WEXE = mafxcw oldnames libw mlibcew commdlg olesvr olecli shell 
RCFLAGS = /nologo /z 
RESFLAGS = /nologo /t 
RUNFLAGS = 
DEFFILE = REFMAP.DEF
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
		REFMAP.SBR \
		MAINFRM.SBR \
		REFMADOC.SBR \
		REFITEM.SBR \
		MAPVIEW.SBR \
		REFITEMD.SBR


REFMAP_RCDEP = c:\derek\refmap\res\refmap.ico \
	c:\derek\refmap\res\refmadoc.ico \
	c:\derek\refmap\res\refmap.rc2


STDAFX_DEP = c:\derek\refmap\stdafx.h


REFMAP_DEP = c:\derek\refmap\stdafx.h \
	c:\derek\refmap\refmap.h \
	c:\derek\refmap\mainfrm.h \
	c:\derek\refmap\refitem.h \
	c:\derek\refmap\refmadoc.h \
	c:\derek\refmap\rowview.h \
	c:\derek\refmap\refmavw.h \
	c:\derek\refmap\mapview.h


MAINFRM_DEP = c:\derek\refmap\stdafx.h \
	c:\derek\refmap\refmap.h \
	c:\derek\refmap\mainfrm.h


REFMADOC_DEP = c:\derek\refmap\stdafx.h \
	c:\derek\refmap\refmap.h \
	c:\derek\refmap\refitem.h \
	c:\derek\refmap\refmadoc.h \
	c:\derek\refmap\refitemd.h


REFITEM_DEP = c:\derek\refmap\stdafx.h \
	c:\derek\refmap\refmap.h \
	c:\derek\refmap\refitem.h


MAPVIEW_DEP = c:\derek\refmap\stdafx.h \
	c:\derek\refmap\refmap.h \
	c:\derek\refmap\refitem.h \
	c:\derek\refmap\refmadoc.h \
	c:\derek\refmap\refitemd.h \
	c:\derek\refmap\mapview.h


REFITEMD_DEP = c:\derek\refmap\stdafx.h \
	c:\derek\refmap\refmap.h \
	c:\derek\refmap\refitemd.h


all:	$(PROJ).EXE $(PROJ).BSC

REFMAP.RES:	REFMAP.RC $(REFMAP_RCDEP)
	$(RC) $(RCFLAGS) $(RCDEFINES) -r REFMAP.RC

STDAFX.OBJ:	STDAFX.CPP $(STDAFX_DEP)
	$(CPP) $(CFLAGS) $(CPPCREATEPCHFLAG) /c STDAFX.CPP

REFMAP.OBJ:	REFMAP.CPP $(REFMAP_DEP)
	$(CPP) $(CFLAGS) $(CPPUSEPCHFLAG) /c REFMAP.CPP

MAINFRM.OBJ:	MAINFRM.CPP $(MAINFRM_DEP)
	$(CPP) $(CFLAGS) $(CPPUSEPCHFLAG) /c MAINFRM.CPP

REFMADOC.OBJ:	REFMADOC.CPP $(REFMADOC_DEP)
	$(CPP) $(CFLAGS) $(CPPUSEPCHFLAG) /c REFMADOC.CPP

REFITEM.OBJ:	REFITEM.CPP $(REFITEM_DEP)
	$(CPP) $(CFLAGS) $(CPPUSEPCHFLAG) /c REFITEM.CPP

MAPVIEW.OBJ:	MAPVIEW.CPP $(MAPVIEW_DEP)
	$(CPP) $(CFLAGS) $(CPPUSEPCHFLAG) /c MAPVIEW.CPP

REFITEMD.OBJ:	REFITEMD.CPP $(REFITEMD_DEP)
	$(CPP) $(CFLAGS) $(CPPUSEPCHFLAG) /c REFITEMD.CPP


$(PROJ).EXE::	REFMAP.RES

$(PROJ).EXE::	STDAFX.OBJ REFMAP.OBJ MAINFRM.OBJ REFMADOC.OBJ REFITEM.OBJ MAPVIEW.OBJ \
	REFITEMD.OBJ $(OBJS_EXT) $(DEFFILE)
	echo >NUL @<<$(PROJ).CRF
STDAFX.OBJ +
REFMAP.OBJ +
MAINFRM.OBJ +
REFMADOC.OBJ +
REFITEM.OBJ +
MAPVIEW.OBJ +
REFITEMD.OBJ +
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
	$(RC) $(RESFLAGS) REFMAP.RES $@
	@copy $(PROJ).CRF MSVC.BND

$(PROJ).EXE::	REFMAP.RES
	if not exist MSVC.BND 	$(RC) $(RESFLAGS) REFMAP.RES $@

run: $(PROJ).EXE
	$(PROJ) $(RUNFLAGS)


$(PROJ).BSC: $(SBRS)
	bscmake @<<
/o$@ $(SBRS)
<<
