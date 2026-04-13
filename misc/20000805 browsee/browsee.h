// browsee.h : main header file for the BROWSEE application
//

#if !defined(AFX_BROWSEE_H__9ADEF124_6AD4_11D4_AF85_00C0F05A20CE__INCLUDED_)
#define AFX_BROWSEE_H__9ADEF124_6AD4_11D4_AF85_00C0F05A20CE__INCLUDED_

#if _MSC_VER > 1000
#pragma once
#endif // _MSC_VER > 1000

#ifndef __AFXWIN_H__
	#error include 'stdafx.h' before including this file for PCH
#endif

#include "resource.h"       // main symbols

/////////////////////////////////////////////////////////////////////////////
// CBrowseeApp:
// See browsee.cpp for the implementation of this class
//

class CBrowseeApp : public CWinApp
{
public:
	CBrowseeApp();

// Overrides
	// ClassWizard generated virtual function overrides
	//{{AFX_VIRTUAL(CBrowseeApp)
	public:
	virtual BOOL InitInstance();
	//}}AFX_VIRTUAL

// Implementation
	//{{AFX_MSG(CBrowseeApp)
	afx_msg void OnAppAbout();
		// NOTE - the ClassWizard will add and remove member functions here.
		//    DO NOT EDIT what you see in these blocks of generated code !
	//}}AFX_MSG
	DECLARE_MESSAGE_MAP()
};


/////////////////////////////////////////////////////////////////////////////

//{{AFX_INSERT_LOCATION}}
// Microsoft Visual C++ will insert additional declarations immediately before the previous line.

#endif // !defined(AFX_BROWSEE_H__9ADEF124_6AD4_11D4_AF85_00C0F05A20CE__INCLUDED_)
