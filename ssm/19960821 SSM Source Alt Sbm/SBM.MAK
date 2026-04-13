# Microsoft Visual C++ generated build script - Do not modify

PROJ = SBM
DEBUG = 1
PROGTYPE = 0
CALLER = 
ARGS = 
DLLS = 
D_RCDEFINES = /d_DEBUG
R_RCDEFINES = /dNDEBUG
ORIGIN = MSVC
ORIGIN_VER = 1.00
PROJPATH = C:\LCC\SSM\SBM\
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
CFLAGS_D_WEXE = /nologo /G2 /W3 /Zi /AM /Od /D "_DEBUG" /FR /GA /Fd"SBM.PDB"
CFLAGS_R_WEXE = /nologo /Gs /G2 /W3 /AM /O1 /D "NDEBUG" /FR /GA
LFLAGS_D_WEXE = /NOLOGO /NOD /PACKC:61440 /STACK:10240 /ALIGN:16 /ONERROR:NOEXE /CO
LFLAGS_R_WEXE = /NOLOGO /NOD /PACKC:61440 /STACK:10240 /ALIGN:16 /ONERROR:NOEXE
LIBS_D_WEXE = mafxcwd oldnames libw mlibcew commdlg olesvr olecli shell 
LIBS_R_WEXE = mafxcw oldnames libw mlibcew commdlg olesvr olecli shell 
RCFLAGS = /nologo /z
RESFLAGS = /nologo /t
RUNFLAGS = 
DEFFILE = SBM.DEF
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
		SBM.SBR \
		MAINFRM.SBR \
		SBMDOC.SBR \
		SBMVIEW.SBR \
		AXACCT.SBR \
		AXACCTVW.SBR \
		AXTRANS.SBR \
		TRFORM.SBR


SBM_RCDEP = c:\lcc\ssm\sbm\res\sbm.ico \
	c:\lcc\ssm\sbm\res\sbmdoc.ico \
	c:\lcc\ssm\sbm\res\sbm.rc2


STDAFX_DEP = c:\lcc\ssm\sbm\stdafx.h


SBM_DEP = c:\lcc\ssm\sbm\stdafx.h \
	c:\lcc\ssm\sbm\sbm.h \
	c:\lcc\ssm\sbm\mainfrm.h \
	c:\lcc\ssm\sbm\sbmdoc.h \
	c:\lcc\ssm\sbm\axtrans.h \
	c:\lcc\ssm\sbm\axacct.h \
	c:\lcc\ssm\sbm\sbmview.h \
	c:\lcc\ssm\sbm\axacctvw.h


MAINFRM_DEP = c:\lcc\ssm\sbm\stdafx.h \
	c:\lcc\ssm\sbm\sbm.h \
	c:\lcc\ssm\sbm\mainfrm.h


SBMDOC_DEP = c:\lcc\ssm\sbm\stdafx.h \
	c:\lcc\ssm\sbm\sbm.h \
	c:\lcc\ssm\sbm\sbmdoc.h \
	c:\lcc\ssm\sbm\axtrans.h \
	c:\lcc\ssm\sbm\axacct.h


SBMVIEW_DEP = c:\lcc\ssm\sbm\stdafx.h \
	c:\lcc\ssm\sbm\sbm.h \
	c:\lcc\ssm\sbm\sbmdoc.h \
	c:\lcc\ssm\sbm\axtrans.h \
	c:\lcc\ssm\sbm\axacct.h \
	c:\lcc\ssm\sbm\sbmview.h \
	c:\lcc\ssm\sbm\axacctvw.h


AXACCT_DEP = c:\lcc\ssm\sbm\stdafx.h \
	c:\lcc\ssm\sbm\axacct.h \
	c:\lcc\ssm\sbm\axtrans.h


AXACCTVW_DEP = c:\lcc\ssm\sbm\stdafx.h \
	c:\lcc\ssm\sbm\sbm.h \
	c:\lcc\ssm\sbm\axacctvw.h \
	c:\lcc\ssm\sbm\axacct.h \
	c:\lcc\ssm\sbm\axtrans.h


AXTRANS_DEP = c:\lcc\ssm\sbm\stdafx.h \
	c:\lcc\ssm\sbm\axtrans.h


all:	$(PROJ).EXE $(PROJ).BSC

SBM.RES:	SBM.RC $(SBM_RCDEP)
	$(RC) $(RCFLAGS) $(RCDEFINES) -r SBM.RC

STDAFX.OBJ:	STDAFX.CPP $(STDAFX_DEP)
	$(CPP) $(CFLAGS) $(CPPCREATEPCHFLAG) /c STDAFX.CPP

SBM.OBJ:	SBM.CPP $(SBM_DEP)
	$(CPP) $(CFLAGS) $(CPPUSEPCHFLAG) /c SBM.CPP

MAINFRM.OBJ:	MAINFRM.CPP $(MAINFRM_DEP)
	$(CPP) $(CFLAGS) $(CPPUSEPCHFLAG) /c MAINFRM.CPP

SBMDOC.OBJ:	SBMDOC.CPP $(SBMDOC_DEP)
	$(CPP) $(CFLAGS) $(CPPUSEPCHFLAG) /c SBMDOC.CPP

SBMVIEW.OBJ:	SBMVIEW.CPP $(SBMVIEW_DEP)
	$(CPP) $(CFLAGS) $(CPPUSEPCHFLAG) /c SBMVIEW.CPP

AXACCT.OBJ:	AXACCT.CPP $(AXACCT_DEP)
	$(CPP) $(CFLAGS) $(CPPUSEPCHFLAG) /c AXACCT.CPP

AXACCTVW.OBJ:	AXACCTVW.CPP $(AXACCTVW_DEP)
	$(CPP) $(CFLAGS) $(CPPUSEPCHFLAG) /c AXACCTVW.CPP

AXTRANS.OBJ:	AXTRANS.CPP $(AXTRANS_DEP)
	$(CPP) $(CFLAGS) $(CPPUSEPCHFLAG) /c AXTRANS.CPP

TRFORM.OBJ:	TRFORM.CPP $(TRFORM_DEP)
	$(CPP) $(CFLAGS) $(CPPUSEPCHFLAG) /c TRFORM.CPP


$(PROJ).EXE::	SBM.RES

$(PROJ).EXE::	STDAFX.OBJ SBM.OBJ MAINFRM.OBJ SBMDOC.OBJ SBMVIEW.OBJ AXACCT.OBJ AXACCTVW.OBJ \
	AXTRANS.OBJ TRFORM.OBJ $(OBJS_EXT) $(DEFFILE)
	echo >NUL @<<$(PROJ).CRF
STDAFX.OBJ +
SBM.OBJ +
MAINFRM.OBJ +
SBMDOC.OBJ +
SBMVIEW.OBJ +
AXACCT.OBJ +
AXACCTVW.OBJ +
AXTRANS.OBJ +
TRFORM.OBJ +
$(OBJS_EXT)
$(PROJ).EXE
$(MAPFILE)
C:\PROGRA~1\MSVC\LIB\+
C:\PROGRA~1\MSVC\MFC\LIB\+
$(LIBS)
$(DEFFILE);
<<
	link $(LFLAGS) @$(PROJ).CRF
	$(RC) $(RESFLAGS) SBM.RES $@
	@copy $(PROJ).CRF MSVC.BND

$(PROJ).EXE::	SBM.RES
	if not exist MSVC.BND 	$(RC) $(RESFLAGS) SBM.RES $@

run: $(PROJ).EXE
	$(PROJ) $(RUNFLAGS)


$(PROJ).BSC: $(SBRS)
	bscmake @<<
/o$@ $(SBRS)
<<
