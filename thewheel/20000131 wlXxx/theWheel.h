// theWheel.h  Copyright (C) 1996, 97  DG Lane

#ifndef _theWheel_h_
#define _theWheel_h_

class theWheelApp : public CWinApp  {

		POSITION atChild;

public:
		theWheelApp()  { }
		virtual ~theWheelApp()  { }

		virtual BOOL InitInstance();
		virtual BOOL Run();
		BOOL IsIdleMessage( MSG * );
		virtual int ExitInstance();

		//{{AFX_MSG(theWheelApp)
		afx_msg void OnFileNew();
		//}}AFX_MSG

		DECLARE_MESSAGE_MAP()
};

#endif
