# Microsoft Visual C++ generated build script - Do not modify

PROJ = ORBIS
DEBUG = 1
PROGTYPE = 0
CALLER = 
ARGS = 
DLLS = 
D_RCDEFINES = /d_DEBUG 
R_RCDEFINES = /dNDEBUG 
ORIGIN = MSVC
ORIGIN_VER = 1.00
PROJPATH = C:\LCC\THEWHEEL\SRC\
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
CFLAGS_D_WEXE = /nologo /G2 /FPi87 /W3 /Zi /AL /Od /D "_DEBUG" /FR /GA /Fd"COGMAP.PDB" 
CFLAGS_R_WEXE = /nologo /Gs /G2 /FPi87 /Zp4 /W3 /AL /O2 /Ox /Ob2 /OV8 /D "NDEBUG" /FR /GA 
LFLAGS_D_WEXE = /NOLOGO /NOD /PACKC:61440 /STACK:20000 /ALIGN:16 /ONERROR:NOEXE /CO  
LFLAGS_R_WEXE = /NOLOGO /NOD /PACKC:61440 /STACK:10240 /ALIGN:16 /ONERROR:NOEXE  
LIBS_D_WEXE = lafxcwd winsock winsock oldnames libw llibcew commdlg.lib olecli.lib shell.lib 
LIBS_R_WEXE = lafxcw winsock oldnames libw llibcew commdlg.lib olecli.lib olesvr.lib shell.lib 
RCFLAGS = /nologo /z 
RESFLAGS = /nologo /t /k
RUNFLAGS = 
DEFFILE = ORBIS.DEF
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
		ORBIS.SBR \
		ORBDOC.SBR \
		ORBITEM.SBR \
		ORBFRAME.SBR \
		ITEMVIEW.SBR \
		HTMLDOC.SBR


STDAFX_DEP = c:\lcc\thewheel\src\stdafx.h


ORBIS_DEP = c:\lcc\thewheel\src\stdafx.h \
	c:\lcc\thewheel\src\orbis.h \
	c:\lcc\thewheel\src\itemview.h \
	c:\lcc\thewheel\src\orbitem.h \
	c:\lcc\thewheel\src\misc.h \
	c:\msvc\include\winsock.h \
	c:\lcc\thewheel\src\orbdoc.h \
	c:\lcc\thewheel\src\orbframe.h \
	c:\lcc\thewheel\src\htmlview.h \
	c:\lcc\thewheel\src\textview.h


ORBDOC_DEP = c:\lcc\thewheel\src\stdafx.h \
	c:\lcc\thewheel\src\misc.h \
	c:\lcc\thewheel\src\orbis.h \
	c:\lcc\thewheel\src\itemview.h \
	c:\lcc\thewheel\src\orbitem.h \
	c:\msvc\include\winsock.h \
	c:\lcc\thewheel\src\orbdoc.h \
	c:\lcc\thewheel\src\htmldoc.h


ORBITEM_DEP = c:\lcc\thewheel\src\stdafx.h \
	c:\lcc\thewheel\src\misc.h \
	c:\lcc\thewheel\src\orbis.h \
	c:\lcc\thewheel\src\itemview.h \
	c:\lcc\thewheel\src\orbitem.h \
	c:\msvc\include\winsock.h \
	c:\lcc\thewheel\src\orbdoc.h


ORBIS_RCDEP = c:\lcc\thewheel\src\res\cogmap.ico \
	c:\lcc\thewheel\src\res\cogmadoc.ico \
	c:\lcc\thewheel\src\res\cogmap.rc2


ORBFRAME_DEP = c:\lcc\thewheel\src\stdafx.h \
	c:\lcc\thewheel\src\orbis.h \
	c:\lcc\thewheel\src\itemview.h \
	c:\lcc\thewheel\src\orbitem.h \
	c:\lcc\thewheel\src\misc.h \
	c:\msvc\include\winsock.h \
	c:\lcc\thewheel\src\orbdoc.h \
	c:\lcc\thewheel\src\orbframe.h


ITEMVIEW_DEP = c:\lcc\thewheel\src\stdafx.h \
	c:\lcc\thewheel\src\orbframe.h \
	c:\lcc\thewheel\src\orbdoc.h \
	c:\lcc\thewheel\src\itemview.h \
	c:\lcc\thewheel\src\orbitem.h \
	c:\lcc\thewheel\src\misc.h \
	c:\msvc\include\winsock.h


HTMLDOC_DEP = c:\lcc\thewheel\src\stdafx.h \
	c:\lcc\thewheel\src\orbis.h \
	c:\lcc\thewheel\src\itemview.h \
	c:\lcc\thewheel\src\orbitem.h \
	c:\lcc\thewheel\src\misc.h \
	c:\msvc\include\winsock.h \
	c:\lcc\thewheel\src\htmldoc.h \
	c:\lcc\thewheel\src\textview.h


all:	$(PROJ).EXE $(PROJ).BSC

STDAFX.OBJ:	STDAFX.CPP $(STDAFX_DEP)
	$(CPP) $(CFLAGS) $(CPPCREATEPCHFLAG) /c STDAFX.CPP

ORBIS.OBJ:	ORBIS.CPP $(ORBIS_DEP)
	$(CPP) $(CFLAGS) $(CPPUSEPCHFLAG) /c ORBIS.CPP

ORBDOC.OBJ:	ORBDOC.CPP $(ORBDOC_DEP)
	$(CPP) $(CFLAGS) $(CPPUSEPCHFLAG) /c ORBDOC.CPP

ORBITEM.OBJ:	ORBITEM.CPP $(ORBITEM_DEP)
	$(CPP) $(CFLAGS) $(CPPUSEPCHFLAG) /c ORBITEM.CPP

ORBIS.RES:	ORBIS.RC $(ORBIS_RCDEP)
	$(RC) $(RCFLAGS) $(RCDEFINES) -r ORBIS.RC

ORBFRAME.OBJ:	ORBFRAME.CPP $(ORBFRAME_DEP)
	$(CPP) $(CFLAGS) $(CPPUSEPCHFLAG) /c ORBFRAME.CPP

ITEMVIEW.OBJ:	ITEMVIEW.CPP $(ITEMVIEW_DEP)
	$(CPP) $(CFLAGS) $(CPPUSEPCHFLAG) /c ITEMVIEW.CPP

HTMLDOC.OBJ:	HTMLDOC.CPP $(HTMLDOC_DEP)
	$(CPP) $(CFLAGS) $(CPPUSEPCHFLAG) /c HTMLDOC.CPP


$(PROJ).EXE::	ORBIS.RES

$(PROJ).EXE::	STDAFX.OBJ ORBIS.OBJ ORBDOC.OBJ ORBITEM.OBJ ORBFRAME.OBJ ITEMVIEW.OBJ \
	HTMLDOC.OBJ $(OBJS_EXT) $(DEFFILE)
	echo >NUL @<<$(PROJ).CRF
STDAFX.OBJ +
ORBIS.OBJ +
ORBDOC.OBJ +
ORBITEM.OBJ +
ORBFRAME.OBJ +
ITEMVIEW.OBJ +
HTMLDOC.OBJ +
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
	$(RC) $(RESFLAGS) ORBIS.RES $@
	@copy $(PROJ).CRF MSVC.BND

$(PROJ).EXE::	ORBIS.RES
	if not exist MSVC.BND 	$(RC) $(RESFLAGS) ORBIS.RES $@

run: $(PROJ).EXE
	$(PROJ) $(RUNFLAGS)


$(PROJ).BSC: $(SBRS)
	bscmake @<<
/o$@ $(SBRS)
<<
