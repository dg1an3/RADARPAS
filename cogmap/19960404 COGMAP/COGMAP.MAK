# Microsoft Visual C++ generated build script - Do not modify

PROJ = COGMAP
DEBUG = 1
PROGTYPE = 0
CALLER = 
ARGS = 
DLLS = 
D_RCDEFINES = /d_DEBUG 
R_RCDEFINES = /dNDEBUG 
ORIGIN = MSVC
ORIGIN_VER = 1.00
PROJPATH = C:\MAP\COGMAP\
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
CFLAGS_D_WEXE = /nologo /G2 /W3 /Zi /AL /Od /D "_DEBUG" /FR /GA /Fd"COGMAP.PDB" 
CFLAGS_R_WEXE = /nologo /Gs /G2 /W3 /AM /O1 /D "NDEBUG" /FR /GA 
LFLAGS_D_WEXE = /NOLOGO /NOD /PACKC:61440 /STACK:10240 /ALIGN:16 /ONERROR:NOEXE /CO
LFLAGS_R_WEXE = /NOLOGO /NOD /PACKC:61440 /STACK:10240 /ALIGN:16 /ONERROR:NOEXE
LIBS_D_WEXE = lafxcwd oldnames libw llibcew commdlg olesvr olecli shell 
LIBS_R_WEXE = mafxcw oldnames libw mlibcew commdlg olesvr olecli shell 
RCFLAGS = /nologo /z 
RESFLAGS = /nologo /t /k
RUNFLAGS = 
DEFFILE = COGMAP.DEF
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
		COGMAP.SBR \
		MAINFRM.SBR \
		MAPVIEW.SBR \
		MAPDOC.SBR \
		TXTRITEM.SBR \
		EEVORG.SBR \
		CA1DITEM.SBR \
		INFODLG.SBR


COGMAP_RCDEP = c:\map\cogmap\res\cogmap.ico \
	c:\map\cogmap\res\cogmadoc.ico \
	c:\map\cogmap\res\cogmap.rc2


STDAFX_DEP = c:\map\cogmap\stdafx.h


COGMAP_DEP = c:\map\cogmap\stdafx.h \
	c:\map\cogmap\cogmap.h \
	c:\map\cogmap\mainfrm.h \
	c:\map\cogmap\mapdoc.h \
	c:\map\cogmap\eevorg.h \
	c:\map\cogmap\eevorg2d.h \
	c:\map\cogmap\mapview.h


MAINFRM_DEP = c:\map\cogmap\stdafx.h \
	c:\map\cogmap\cogmap.h \
	c:\map\cogmap\mainfrm.h


MAPVIEW_DEP = c:\map\cogmap\stdafx.h \
	c:\map\cogmap\cogmap.h \
	c:\map\cogmap\mapdoc.h \
	c:\map\cogmap\eevorg.h \
	c:\map\cogmap\eevorg2d.h \
	c:\map\cogmap\mapview.h


MAPDOC_DEP = c:\map\cogmap\stdafx.h \
	c:\map\cogmap\cogmap.h \
	c:\map\cogmap\mapdoc.h \
	c:\map\cogmap\eevorg.h \
	c:\map\cogmap\eevorg2d.h \
	c:\map\cogmap\infodlg.h


TXTRITEM_DEP = c:\map\cogmap\stdafx.h \
	c:\map\cogmap\mapdoc.h \
	c:\map\cogmap\eevorg.h \
	c:\map\cogmap\eevorg2d.h


EEVORG_DEP = c:\map\cogmap\stdafx.h \
	c:\map\cogmap\eevorg.h


CA1DITEM_DEP = c:\map\cogmap\stdafx.h \
	c:\map\cogmap\mapdoc.h \
	c:\map\cogmap\eevorg.h \
	c:\map\cogmap\eevorg2d.h


INFODLG_DEP = c:\map\cogmap\stdafx.h \
	c:\map\cogmap\cogmap.h \
	c:\map\cogmap\mapdoc.h \
	c:\map\cogmap\eevorg.h \
	c:\map\cogmap\eevorg2d.h \
	c:\map\cogmap\infodlg.h


all:	$(PROJ).EXE $(PROJ).BSC

COGMAP.RES:	COGMAP.RC $(COGMAP_RCDEP)
	$(RC) $(RCFLAGS) $(RCDEFINES) -r COGMAP.RC

STDAFX.OBJ:	STDAFX.CPP $(STDAFX_DEP)
	$(CPP) $(CFLAGS) $(CPPCREATEPCHFLAG) /c STDAFX.CPP

COGMAP.OBJ:	COGMAP.CPP $(COGMAP_DEP)
	$(CPP) $(CFLAGS) $(CPPUSEPCHFLAG) /c COGMAP.CPP

MAINFRM.OBJ:	MAINFRM.CPP $(MAINFRM_DEP)
	$(CPP) $(CFLAGS) $(CPPUSEPCHFLAG) /c MAINFRM.CPP

MAPVIEW.OBJ:	MAPVIEW.CPP $(MAPVIEW_DEP)
	$(CPP) $(CFLAGS) $(CPPUSEPCHFLAG) /c MAPVIEW.CPP

MAPDOC.OBJ:	MAPDOC.CPP $(MAPDOC_DEP)
	$(CPP) $(CFLAGS) $(CPPUSEPCHFLAG) /c MAPDOC.CPP

TXTRITEM.OBJ:	TXTRITEM.CPP $(TXTRITEM_DEP)
	$(CPP) $(CFLAGS) $(CPPUSEPCHFLAG) /c TXTRITEM.CPP

EEVORG.OBJ:	EEVORG.CPP $(EEVORG_DEP)
	$(CPP) $(CFLAGS) $(CPPUSEPCHFLAG) /c EEVORG.CPP

CA1DITEM.OBJ:	CA1DITEM.CPP $(CA1DITEM_DEP)
	$(CPP) $(CFLAGS) $(CPPUSEPCHFLAG) /c CA1DITEM.CPP

INFODLG.OBJ:	INFODLG.CPP $(INFODLG_DEP)
	$(CPP) $(CFLAGS) $(CPPUSEPCHFLAG) /c INFODLG.CPP


$(PROJ).EXE::	COGMAP.RES

$(PROJ).EXE::	STDAFX.OBJ COGMAP.OBJ MAINFRM.OBJ MAPVIEW.OBJ MAPDOC.OBJ TXTRITEM.OBJ \
	EEVORG.OBJ CA1DITEM.OBJ INFODLG.OBJ $(OBJS_EXT) $(DEFFILE)
	echo >NUL @<<$(PROJ).CRF
STDAFX.OBJ +
COGMAP.OBJ +
MAINFRM.OBJ +
MAPVIEW.OBJ +
MAPDOC.OBJ +
TXTRITEM.OBJ +
EEVORG.OBJ +
CA1DITEM.OBJ +
INFODLG.OBJ +
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
	$(RC) $(RESFLAGS) COGMAP.RES $@
	@copy $(PROJ).CRF MSVC.BND

$(PROJ).EXE::	COGMAP.RES
	if not exist MSVC.BND 	$(RC) $(RESFLAGS) COGMAP.RES $@

run: $(PROJ).EXE
	$(PROJ) $(RUNFLAGS)


$(PROJ).BSC: $(SBRS)
	bscmake @<<
/o$@ $(SBRS)
<<
