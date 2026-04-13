// theWheel.cpp  Copyright (C) 1996  DG Lane

#include "stdafx.h"
#include "theWheel.h"
#include "wlFrameV.h"
#include "wlEevorg.h"

#ifdef _DEBUG
#undef THIS_FILE
static char BASED_CODE THIS_FILE[] = __FILE__;
#endif

theWheelApp NEAR theApp;

BEGIN_MESSAGE_MAP(theWheelApp, CWinApp)
	//{{AFX_MSG_MAP(theWheelApp)
	ON_COMMAND(ID_FILE_NEW, OnFileNew)
	//}}AFX_MSG_MAP
	ON_COMMAND(ID_FILE_NEW, CWinApp::OnFileNew)
	ON_COMMAND(ID_FILE_OPEN, CWinApp::OnFileOpen)
	ON_COMMAND(ID_FILE_PRINT_SETUP, CWinApp::OnFilePrintSetup)
END_MESSAGE_MAP()

BOOL theWheelApp::InitInstance() {
#ifdef _DEBUG
	afxTraceEnabled = 1;
#endif      
	srand((unsigned)time(NULL));
	SetDialogBkColor();    
	LoadStdProfileSettings();
	wlFrameView* theFrame = new wlFrameView;
	if (!theFrame->LoadFrame(IDR_MAINFRAME, 
			WS_OVERLAPPEDWINDOW | FWS_ADDTOTITLE))
	 	return FALSE;
	m_nCmdShow = SW_SHOWMAXIMIZED;
	theFrame->ShowWindow(m_nCmdShow);
	theFrame->UpdateWindow();
	m_pMainWnd = theFrame;
	if (m_lpCmdLine[0] == '\0') {
		OnFileNew();
	} else {
		OpenDocumentFile(m_lpCmdLine);
	}
	return TRUE;
}

int theWheelApp::Run() {

		LONG sheepCount;
		
		do {
				sheepCount = 0;
				while (!::PeekMessage(&m_msgCur, NULL, NULL, NULL, PM_NOREMOVE) &&
								OnIdle(sheepCount++));

				if (m_msgCur.message == WM_MOUSEMOVE) { 
						sheepCount = 0; 
						while (OnIdle(sheepCount++));
				}
		} while (PumpMessage());
		
		return ExitInstance();
}

BOOL theWheelApp::OnIdle(LONG count) {
		POINT cursorPos;
		::GetCursorPos(&cursorPos);
	
		wlFrameView *theFrame = (wlFrameView *)m_pMainWnd;
		int childCount = (int)(count % (LONG)numChildren);	
		theFrame->getChild(childCount)->updatePos();
		theFrame->getChild(childCount)->updateSize(CPoint(cursorPos));
		// theFrame->getChild(childCount)->myDoc->grow();
	
		return CWinApp::OnIdle(count) || (count < numChildren);
}

int theWheelApp::ExitInstance() {
		return CWinApp::ExitInstance();
}

void theWheelApp::OnFileNew() {
		wlFrameView *theFrame = (wlFrameView *)m_pMainWnd;
		wlEevorg *rootObj = new wlEevorg(); 
		theFrame->setChild(new wlChildView(rootObj));
		for (int count = 1; count < numChildren; count++) {
				wlEevorg *newObj = new wlEevorg(rootObj, TRUE);
				wlChildView *newObjView = new wlChildView(newObj);
				theFrame->setChild(newObjView);
		}
}
