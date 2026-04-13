// theWheel.h : main header file for the THEWHEEL application
//

#if !defined(AFX_THEWHEEL_H__8FF714A4_CD09_11D2_AB06_CCE30BC10000__INCLUDED_)
#define AFX_THEWHEEL_H__8FF714A4_CD09_11D2_AB06_CCE30BC10000__INCLUDED_

#if _MSC_VER > 1000
#pragma once
#endif // _MSC_VER > 1000

#ifndef __AFXWIN_H__
	#error include 'stdafx.h' before including this file for PCH
#endif

#include "resource.h"       // main symbols

/////////////////////////////////////////////////////////////////////////////
// CTheWheelApp:
// See theWheel.cpp for the implementation of this class
//

class CTheWheelApp : public CWinApp
{
public:
	CTheWheelApp();

// Overrides
	// ClassWizard generated virtual function overrides
	//{{AFX_VIRTUAL(CTheWheelApp)
	public:
	virtual BOOL InitInstance();
	//}}AFX_VIRTUAL

// Implementation
	//{{AFX_MSG(CTheWheelApp)
	afx_msg void OnAppAbout();
		// NOTE - the ClassWizard will add and remove member functions here.
		//    DO NOT EDIT what you see in these blocks of generated code !
	//}}AFX_MSG
	DECLARE_MESSAGE_MAP()
};


/////////////////////////////////////////////////////////////////////////////

//{{AFX_INSERT_LOCATION}}
// Microsoft Visual C++ will insert additional declarations immediately before the previous line.

#endif // !defined(AFX_THEWHEEL_H__8FF714A4_CD09_11D2_AB06_CCE30BC10000__INCLUDED_)
