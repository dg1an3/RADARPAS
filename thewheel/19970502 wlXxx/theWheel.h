// theWheel.h  Copyright (C) 1996, 97  DG Lane

#ifndef _theWheel_h_
#define _theWheel_h_

#include "resource.h"

class theWheelApp : public CWinApp {
	public:
		theWheelApp() { }
	
		virtual BOOL InitInstance();
		virtual int Run();
		virtual BOOL OnIdle(LONG count);
		virtual int ExitInstance();

		//{{AFX_MSG(theWheelApp)
		afx_msg void OnFileNew();
		//}}AFX_MSG
		DECLARE_MESSAGE_MAP()

	public:		
		virtual ~theWheelApp() { }
};

#endif
