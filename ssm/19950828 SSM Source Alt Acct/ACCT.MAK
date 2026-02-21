# Microsoft Visual C++ generated build script - Do not modify

PROJ = ACCT
DEBUG = 1
PROGTYPE = 0
CALLER = 
ARGS = 
DLLS = 
D_RCDEFINES = /d_DEBUG
R_RCDEFINES = /dNDEBUG
ORIGIN = MSVC
ORIGIN_VER = 1.00
PROJPATH = C:\DEREK\SSM\WINSSM\ACCT\
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
CFLAGS_D_WEXE = /nologo /G2 /W3 /Zi /AM /Od /D "_DEBUG" /FR /GA /Fd"ACCT.PDB"
CFLAGS_R_WEXE = /nologo /Gs /G2 /W3 /AM /O1 /D "NDEBUG" /FR /GA
LFLAGS_D_WEXE = /NOLOGO /NOD /PACKC:61440 /STACK:10240 /ALIGN:16 /ONERROR:NOEXE /CO
LFLAGS_R_WEXE = /NOLOGO /NOD /PACKC:61440 /STACK:10240 /ALIGN:16 /ONERROR:NOEXE
LIBS_D_WEXE = mafxcwd oldnames libw mlibcew commdlg olesvr olecli shell 
LIBS_R_WEXE = mafxcw oldnames libw mlibcew commdlg olesvr olecli shell 
RCFLAGS = /nologo /z
RESFLAGS = /nologo /t
RUNFLAGS = 
DEFFILE = ACCT.DEF
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
		ACCT.SBR \
		MAINFRM.SBR \
		ACCTDOC.SBR \
		ACCTVIEW.SBR \
		ACCTTRAN.SBR


ACCT_RCDEP = c:\derek\ssm\winssm\acct\res\acct.ico \
	c:\derek\ssm\winssm\acct\res\acctdoc.ico \
	c:\derek\ssm\winssm\acct\res\acct.rc2


STDAFX_DEP = c:\derek\ssm\winssm\acct\stdafx.h


ACCT_DEP = c:\derek\ssm\winssm\acct\stdafx.h \
	c:\derek\ssm\winssm\acct\acct.h \
	c:\derek\ssm\winssm\acct\mainfrm.h \
	c:\derek\ssm\winssm\acct\acctdoc.h \
	c:\derek\ssm\winssm\acct\acctview.h


MAINFRM_DEP = c:\derek\ssm\winssm\acct\stdafx.h \
	c:\derek\ssm\winssm\acct\acct.h \
	c:\derek\ssm\winssm\acct\mainfrm.h


ACCTDOC_DEP = c:\derek\ssm\winssm\acct\stdafx.h \
	c:\derek\ssm\winssm\acct\acct.h \
	c:\derek\ssm\winssm\acct\accttran.h \
	c:\derek\ssm\winssm\acct\acctdoc.h


ACCTVIEW_DEP = c:\derek\ssm\winssm\acct\stdafx.h \
	c:\derek\ssm\winssm\acct\acct.h \
	c:\derek\ssm\winssm\acct\acctdoc.h \
	c:\derek\ssm\winssm\acct\acctview.h


ACCTTRAN_DEP = c:\derek\ssm\winssm\acct\stdafx.h \
	c:\derek\ssm\winssm\acct\acct.h \
	c:\derek\ssm\winssm\acct\accttran.h


all:	$(PROJ).EXE $(PROJ).BSC

ACCT.RES:	ACCT.RC $(ACCT_RCDEP)
	$(RC) $(RCFLAGS) $(RCDEFINES) -r ACCT.RC

STDAFX.OBJ:	STDAFX.CPP $(STDAFX_DEP)
	$(CPP) $(CFLAGS) $(CPPCREATEPCHFLAG) /c STDAFX.CPP

ACCT.OBJ:	ACCT.CPP $(ACCT_DEP)
	$(CPP) $(CFLAGS) $(CPPUSEPCHFLAG) /c ACCT.CPP

MAINFRM.OBJ:	MAINFRM.CPP $(MAINFRM_DEP)
	$(CPP) $(CFLAGS) $(CPPUSEPCHFLAG) /c MAINFRM.CPP

ACCTDOC.OBJ:	ACCTDOC.CPP $(ACCTDOC_DEP)
	$(CPP) $(CFLAGS) $(CPPUSEPCHFLAG) /c ACCTDOC.CPP

ACCTVIEW.OBJ:	ACCTVIEW.CPP $(ACCTVIEW_DEP)
	$(CPP) $(CFLAGS) $(CPPUSEPCHFLAG) /c ACCTVIEW.CPP

ACCTTRAN.OBJ:	ACCTTRAN.CPP $(ACCTTRAN_DEP)
	$(CPP) $(CFLAGS) $(CPPUSEPCHFLAG) /c ACCTTRAN.CPP


$(PROJ).EXE::	ACCT.RES

$(PROJ).EXE::	STDAFX.OBJ ACCT.OBJ MAINFRM.OBJ ACCTDOC.OBJ ACCTVIEW.OBJ ACCTTRAN.OBJ $(OBJS_EXT) $(DEFFILE)
	echo >NUL @<<$(PROJ).CRF
STDAFX.OBJ +
ACCT.OBJ +
MAINFRM.OBJ +
ACCTDOC.OBJ +
ACCTVIEW.OBJ +
ACCTTRAN.OBJ +
$(OBJS_EXT)
$(PROJ).EXE
$(MAPFILE)
c:\msvc\lib\+
c:\msvc\mfc\lib\+
c:\wx\lib\+
$(LIBS)
$(DEFFILE);
<<
	link $(LFLAGS) @$(PROJ).CRF
	$(RC) $(RESFLAGS) ACCT.RES $@
	@copy $(PROJ).CRF MSVC.BND

$(PROJ).EXE::	ACCT.RES
	if not exist MSVC.BND 	$(RC) $(RESFLAGS) ACCT.RES $@

run: $(PROJ).EXE
	$(PROJ) $(RUNFLAGS)


$(PROJ).BSC: $(SBRS)
	bscmake @<<
/o$@ $(SBRS)
<<
