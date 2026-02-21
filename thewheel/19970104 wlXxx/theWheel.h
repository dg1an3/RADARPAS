// theWheel.h  Copyright (C) 1996  DG Lane
// Class definition for theWheelApp main application object class

#include "resource.h"

class theWheelApp : public CWinApp {
public:
	theWheelApp();
	
	virtual BOOL InitInstance();
	virtual int ExitInstance();

	//{{AFX_MSG(OrbisApp)
	afx_msg void OnFileNew();
	//}}AFX_MSG
	DECLARE_MESSAGE_MAP()
};
