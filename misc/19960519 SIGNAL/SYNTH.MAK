# Microsoft Visual C++ generated build script - Do not modify

PROJ = SYNTH
DEBUG = 1
PROGTYPE = 3
CALLER = 
ARGS = 
DLLS = 
D_RCDEFINES = -d_DEBUG
R_RCDEFINES = -dNDEBUG
ORIGIN = MSVC
ORIGIN_VER = 1.00
PROJPATH = C:\MAP\WINSIG\SIGNAL\
USEMFC = 0
CC = cl
CPP = cl
CXX = cl
CCREATEPCHFLAG = 
CPPCREATEPCHFLAG = 
CUSEPCHFLAG = 
CPPUSEPCHFLAG = 
FIRSTC =             
FIRSTCPP = SIGNAL.CPP  
RC = rc
CFLAGS_D_WTTY = /nologo /G2 /FPi87 /Mq /W3 /Zi /AM /Od /D "_DEBUG" /FR /Fd"SYNTH.PDB"
CFLAGS_R_WTTY = /nologo /Gs /G2 /Mq /W3 /AM /Ox /D "NDEBUG" /FR 
LFLAGS_D_WTTY = /NOLOGO /NOD /PACKC:57344 /ALIGN:16 /ONERROR:NOEXE /CO 
LFLAGS_R_WTTY = /NOLOGO /NOD /PACKC:57344 /ALIGN:16 /ONERROR:NOEXE 
LIBS_D_WTTY = oldnames libw mlibcewq 
LIBS_R_WTTY = oldnames libw mlibcewq 
RCFLAGS = /nologo
RESFLAGS = /nologo
RUNFLAGS = 
OBJS_EXT = 
LIBS_EXT = 
!if "$(DEBUG)" == "1"
CFLAGS = $(CFLAGS_D_WTTY)
LFLAGS = $(LFLAGS_D_WTTY)
LIBS = $(LIBS_D_WTTY)
MAPFILE = nul
RCDEFINES = $(D_RCDEFINES)
DEFFILE=C:\MSVC\BIN\CL.DEF
!else
CFLAGS = $(CFLAGS_R_WTTY)
LFLAGS = $(LFLAGS_R_WTTY)
LIBS = $(LIBS_R_WTTY)
MAPFILE = nul
RCDEFINES = $(R_RCDEFINES)
DEFFILE=C:\MSVC\BIN\CL.DEF
!endif
!if [if exist MSVC.BND del MSVC.BND]
!endif
SBRS = SIGNAL.SBR \
		FILTNODE.SBR \
		SYNTH.SBR


SIGNAL_DEP = c:\map\winsig\signal\stdafx.h


FILTNODE_DEP = c:\map\winsig\signal\misc.h \
	c:\map\winsig\signal\filtnode.h


SYNTH_DEP = c:\map\winsig\signal\filtnode.h


all:	$(PROJ).EXE $(PROJ).BSC

SIGNAL.OBJ:	SIGNAL.CPP $(SIGNAL_DEP)
	$(CPP) $(CFLAGS) $(CPPCREATEPCHFLAG) /c SIGNAL.CPP

FILTNODE.OBJ:	FILTNODE.CPP $(FILTNODE_DEP)
	$(CPP) $(CFLAGS) $(CPPUSEPCHFLAG) /c FILTNODE.CPP

SYNTH.OBJ:	SYNTH.CPP $(SYNTH_DEP)
	$(CPP) $(CFLAGS) $(CPPUSEPCHFLAG) /c SYNTH.CPP


$(PROJ).EXE::	SIGNAL.OBJ FILTNODE.OBJ SYNTH.OBJ $(OBJS_EXT) $(DEFFILE)
	echo >NUL @<<$(PROJ).CRF
SIGNAL.OBJ +
FILTNODE.OBJ +
SYNTH.OBJ +
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
	$(RC) $(RESFLAGS) $@


run: $(PROJ).EXE
	$(PROJ) $(RUNFLAGS)


$(PROJ).BSC: $(SBRS)
	bscmake @<<
/o$@ $(SBRS)
<<
