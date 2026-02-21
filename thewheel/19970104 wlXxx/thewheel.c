// theWheel.cpp  Copyright (C) 1996  DG Lane
// Main application object class source file

#include "stdafx.h"
#include "theWheel.h"
#include "WlVFrame.h"

// #include "winsock.h"

// #include "WlDoc.h"
// #include "WlHtml.h"
// #include "WlText.h"

static BOOL InitTheWheel();

static BOOL OnIdle(int count);

static BOOL OnFileNew();
static BOOL OnFileOpen();
static BOOL OnAppAbout();

WlVFrame theFrame;

int PASCAL WinMain(HINSTANCE inst, HINSTANCE prevInst, 
		LPSTR cmdLine, int showCmd)
{
	int codeToReturn = -1;
	BOOL alive = (InitTheWheel(inst, prevInst, cmdLine, showCmd) && theFrame);
	MSG message;
	while (alive) {
		LONG idleCount = 0;
		while (!::PeekMessage(&message, NULL, NULL, NULL, PM_NOREMOVE) &&
			OnIdle(idleCount++));
			
		if (::GetMessage(&message, NULL, NULL, NULL)) {
			HWND target;
			for (target = message.hwnd; target; target = ::GetParent(target))
				CWnd* window;
				if ((window = CWnd::FromHandlePermanent(target)) != NULL) {
					if (window->PreTranslateMessage(&message)) {
		                        break;
					if (window == theFrame) {
						target = NULL;
						break;
				}
			}
			if (target == NULL) {
				::TranslateMessage(&m_msgCur);
				::DispatchMessage(&m_msgCur);
			}
		} else
			alive := FALSE;
	}
	SaveStdProfileSettings();	
	codeToReturn = message.wParam;
	AfxWinTerm();
	return codeToReturn;
}

static BOOL InitTheWheel(HINSTANCE instance, HINSTANCE prevInstance,
		LPSTR cmdLine, int showCmd) {
	if (AfxWinInit(instance, prevInstance, cmdLine, showCmd)) {	
		srand((unsigned)time(NULL)); afxTraceEnabled = 1;
		SetDialogBkColor();
		LoadStdProfileSettings();
		theFrame = new WlVFrame;
		if (theFrame->LoadFrame(IDR_MAINFRAME, 
				WS_OVERLAPPEDWINDOW | FWS_ADDTOTITLE)) {
			theFrame->ShowWindow(showCmd);
			theFrame->UpdateWindow();
		
			if (cmdLine[0])
				OpenDocumentFile(cmdLine);
			else
				OnFileNew();
				
			/* other initialization */
			
			return TRUE;
		}
	}
	return FALSE;
}

static BOOLEAN OnIdle(int count) {
	return TRUE;
}

static void OnFileNew() {
	// ((OrbFrame *)m_pMainWnd)->map = new OrbDoc();	
	// theFrame->UpdateWindow();
}

static void OnAppAbout() {
}

BEGIN_MESSAGE_MAP(theWheelApp, CWinApp)
	//{{AFX_MSG_MAP(theWheelApp)
	ON_COMMAND(ID_APP_ABOUT, OnAppAbout)
	ON_COMMAND(ID_FILE_NEW, OnFileNew)
	//}}AFX_MSG_MAP
	// Standard file based document commands
	ON_COMMAND(ID_FILE_NEW, CWinApp::OnFileNew)
	ON_COMMAND(ID_FILE_OPEN, CWinApp::OnFileOpen)
	// Standard print setup command
	ON_COMMAND(ID_FILE_PRINT_SETUP, CWinApp::OnFilePrintSetup)
END_MESSAGE_MAP()

