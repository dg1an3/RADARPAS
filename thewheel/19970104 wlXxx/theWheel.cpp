// theWheel.cpp  Copyright (C) 1996  DG Lane
// Main application object class source file

#include "stdafx.h"
#include "theWheel.h"
#include "wlFrame.h"
#include "wlSpring.h"

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

theWheelApp::theWheelApp() 
{ 
}

BOOL 
theWheelApp::InitInstance() 
{
#ifdef _DEBUG
      afxTraceEnabled = 1;
#endif      
	srand((unsigned)time(NULL));
	SetDialogBkColor();    
	LoadStdProfileSettings();
	wlFrame* theFrame = new wlFrame;
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

int 
theWheelApp::ExitInstance() 
{
	return CWinApp::ExitInstance();
}

void 
theWheelApp::OnFileNew() 
{
	wlFrame *theFrame = (wlFrame *)m_pMainWnd;
	theFrame->onlySon = new wlChild();
}
