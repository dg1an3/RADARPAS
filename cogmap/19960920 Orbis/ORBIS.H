// Orbis.h  Copyright (C) 1996  DG Lane

#ifndef __AFXWIN_H__
	#error include 'stdafx.h' before including this file for PCH
#endif

#include "resource.h"		// main symbols
#include "ItemView.h"

class OrbisApp : public CWinApp {
public:
	OrbisApp();
	
	// Overrides
	virtual BOOL InitInstance();
	virtual int ExitInstance();

	//{{AFX_MSG(OrbisApp)
	afx_msg void OnAppAbout();
	afx_msg void OnFileNew();
	//}}AFX_MSG
	DECLARE_MESSAGE_MAP()
};	// class OrbisApp
