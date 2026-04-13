// refmap.h : main header file for the REFMAP application
//

#ifndef __AFXWIN_H__
	#error include 'stdafx.h' before including this file for PCH
#endif

#include "resource.h"		// main symbols

/////////////////////////////////////////////////////////////////////////////
// CRefmapApp:
// See refmap.cpp for the implementation of this class
//

class CRefmapApp : public CWinApp
{
public:
	CRefmapApp();

// Overrides
	virtual BOOL InitInstance();
    virtual BOOL OnIdle(LONG lCount);
    
// Implementation

	//{{AFX_MSG(CRefmapApp)
	afx_msg void OnAppAbout();
		// NOTE - the ClassWizard will add and remove member functions here.
		//    DO NOT EDIT what you see in these blocks of generated code !
	//}}AFX_MSG
	DECLARE_MESSAGE_MAP()
};


/////////////////////////////////////////////////////////////////////////////
