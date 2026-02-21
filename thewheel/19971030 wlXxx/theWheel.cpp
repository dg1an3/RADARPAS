// theWheel.cpp  Copyright (C) 1996, 97  DG Lane

#include "stdafx.h"
#include "wlEevorg.h"
#include "wlFrameW.h"
#include "wlChildW.h"

#include "theWheel.h"

#include "res/resource.h"

#ifdef _DEBUG
#undef THIS_FILE
static char BASED_CODE THIS_FILE[] = __FILE__;
#endif

// theWheelApp application object for this instance
/////////////////////////////////////////////////////////////////////

theWheelApp NEAR theApp;


// theWheelApp::InitInstance
///////////////////////////////////////

BOOL theWheelApp::InitInstance()  {

	srand((unsigned)time(NULL));
		
	SetDialogBkColor();    
	LoadStdProfileSettings();
	
#ifdef _DEBUG
	afxTraceEnabled = 1;
#endif      

	wlFrameWnd* theFrame = new wlFrameWnd();
	if (!theFrame->LoadFrame(IDR_MAINFRAME, WS_OVERLAPPEDWINDOW | FWS_ADDTOTITLE))
		return FALSE;
	m_nCmdShow = SW_SHOWMAXIMIZED;
	theFrame->ShowWindow(m_nCmdShow);
	theFrame->UpdateWindow();
	m_pMainWnd = theFrame;
		
	if (m_lpCmdLine[0] == '\0') 
		OnFileNew();
	else
		OpenDocumentFile(m_lpCmdLine);

	atChild = (POSITION)NULL;
		
	return TRUE;
}

BOOL theWheelApp::IsIdleMessage( MSG* pMsg ) {

    if (!CWinApp::IsIdleMessage( pMsg ) || 
        pMsg->message == WM_TIMER) 
        return FALSE;
    else
        return TRUE;
}

int theWheelApp::Run() {

	ASSERT_VALID(this);

	BOOL bIdle = TRUE;
	LONG lIdleCount = 0;

	// get messages
	//     until a WM_QUIT message is received.
	for (;;) {

		// any work to be done?
		while (bIdle &&
			!::PeekMessage(&m_msgCur, 
						NULL, NULL, NULL, PM_NOREMOVE))
		{
			((wlFrameWnd *)m_pMainWnd)->
				updateChildren(m_msgCur.time, m_msgCur.pt);
			((wlFrameWnd *)m_pMainWnd)->
    			updateViews(m_msgCur.time);

			// call OnIdle while in bIdle state
			if (!OnIdle(lIdleCount++))
				bIdle = FALSE; // assume "no idle" state
		}

		// pump messages while available
		do {
			// pump message, but quit on WM_QUIT
			if (!PumpMessage())
				return ExitInstance();

			((wlFrameWnd *)m_pMainWnd)->
				updateChildren(m_msgCur.time, m_msgCur.pt);
			((wlFrameWnd *)m_pMainWnd)->
    			updateViews(m_msgCur.time);

			// reset "no idle" state after 
			//	  pumping "normal" message
			if (IsIdleMessage(&m_msgCur))
			{
				bIdle = TRUE;
				lIdleCount = 0;
			}

		} while (::PeekMessage(&m_msgCur, 
				NULL, NULL, NULL, PM_NOREMOVE));
	}

	ASSERT(FALSE);  // not reachable
}

// theWheelApp::ExitInstance
///////////////////////////////////////
	
int 
theWheelApp::ExitInstance()  {

	return CWinApp::ExitInstance();
}

// theWheelApp message map
/////////////////////////////////////////
	
BEGIN_MESSAGE_MAP(theWheelApp, CWinApp)
	//{{AFX_MSG_MAP(theWheelApp)
	ON_COMMAND(ID_FILE_NEW, OnFileNew)
	//}}AFX_MSG_MAP
	ON_COMMAND(ID_FILE_NEW, CWinApp::OnFileNew)
	ON_COMMAND(ID_FILE_OPEN, CWinApp::OnFileOpen)
	ON_COMMAND(ID_FILE_PRINT_SETUP, CWinApp::OnFilePrintSetup)
END_MESSAGE_MAP()


// theWheelApp::OnFileNew
///////////////////////////////////////

void 
theWheelApp::OnFileNew()  {
		
	GET_PARENT( theFrame );
		
	wlEevorg *rootEevorg = new wlEevorg();
	wlView *rootView = theFrame->createView(rootEevorg, 400, 300);
	DWORD time = ::GetTickCount();
	rootView->setWidth( time, 41.0 );
	theFrame->promoteView( rootView, time );
	
	// const HWND handle = theFrame->GetSafeHwnd();	
	// UINT timerID = theFrame->SetTimer((UINT)handle, 20, NULL);
	// ASSERT( timerID > 0 );
}
