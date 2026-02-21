// Orbis.cpp  Copyright (C) 1996  DG Lane

#include "stdafx.h"
#include "Orbis.h"
#include "winsock.h"

#include "OrbDoc.h"
#include "OrbFrame.h"
#include "HtmlView.h"
#include "TextView.h"

#ifdef _DEBUG
#undef THIS_FILE
static char BASED_CODE THIS_FILE[] = __FILE__;
#endif

BEGIN_MESSAGE_MAP(OrbisApp, CWinApp)
	//{{AFX_MSG_MAP(OrbisApp)
	ON_COMMAND(ID_APP_ABOUT, OnAppAbout)
	ON_COMMAND(ID_FILE_NEW, OnFileNew)
	//}}AFX_MSG_MAP
	// Standard file based document commands
	ON_COMMAND(ID_FILE_NEW, CWinApp::OnFileNew)
	ON_COMMAND(ID_FILE_OPEN, CWinApp::OnFileOpen)
	// Standard print setup command
	ON_COMMAND(ID_FILE_PRINT_SETUP, CWinApp::OnFilePrintSetup)
END_MESSAGE_MAP()

OrbisApp::OrbisApp() { } // TODO: add construction code here,
	// Place all significant initialization in InitInstance

OrbisApp NEAR theApp;

BOOL OrbisApp::InitInstance() {
	srand( (unsigned)time( NULL ) );

	SetDialogBkColor();        // set dialog background color to gray
	LoadStdProfileSettings();  	// Load standard INI file options (including MRU)

	// AddDocTemplate(new CMultiDocTemplate(IDR_COGMAPTYPE,
	//		RUNTIME_CLASS(OrbDoc),
	//		RUNTIME_CLASS(CMDIChildWnd),        // standard MDI child frame
	//		RUNTIME_CLASS(OrbView)));

	OrbFrame* theFrame = new OrbFrame;	// create main MDI frame window
	if (!theFrame->LoadFrame(IDR_MAINFRAME, 
			WS_OVERLAPPEDWINDOW | FWS_ADDTOTITLE))
		return FALSE;
	m_nCmdShow = SW_SHOWMAXIMIZED;
	theFrame->ShowWindow(m_nCmdShow);
	theFrame->UpdateWindow();
	m_pMainWnd = theFrame;

	WORD version = (1 << 8) + 1;	// Winsock 1.1 or higher needed
	WSADATA winsockData;
	WSAStartup(version, &winsockData);	// initialize winsock stack

	// m_pMainWnd->DragAcceptFiles(); // enable file manager drag/drop and DDE Execute open
	// EnableShellOpen();
	// RegisterShellFileTypes();
	
	if (m_lpCmdLine[0] == '\0') {
		OnFileNew();
	//} else if ((m_lpCmdLine[0] == '-' || m_lpCmdLine[0] == '/') &&
	//	(m_lpCmdLine[1] == 'e' || m_lpCmdLine[1] == 'E')) {
	//	// program launched embedded - wait for DDE or OLE open
	//} else {
	// 	OpenDocumentFile(m_lpCmdLine);
	}	// if
	
	return TRUE;
}	// OrbisApp::InitInstance

int OrbisApp::ExitInstance() {
	WSACleanup();
	return CWinApp::ExitInstance();
}	// OrbisApp::ExitInstance

void OrbisApp::OnFileNew() {
	((OrbFrame *)m_pMainWnd)->map = new OrbDoc();	
	m_pMainWnd->UpdateWindow();
}	// OrbisApp::OnFileNew

// AboutOrbisDlg dialog used for App About

class AboutOrbisDlg : public CDialog {
public:
	AboutOrbisDlg();

// Dialog Data
	//{{AFX_DATA(AboutOrbisDlg)
	enum { IDD = IDD_ABOUTBOX };
	//}}AFX_DATA

// Implementation
protected:
	virtual void DoDataExchange(CDataExchange* pDX);	// DDX/DDV support
	//{{AFX_MSG(AboutOrbisDlg)
		// No message handlers
	//}}AFX_MSG
	DECLARE_MESSAGE_MAP()
};	// class AboutOrbisDlg

AboutOrbisDlg::AboutOrbisDlg() : CDialog(AboutOrbisDlg::IDD) {
	//{{AFX_DATA_INIT(AboutOrbisDlg)
	//}}AFX_DATA_INIT
}	// AboutOrbisDlg::AboutOrbisDlg

void AboutOrbisDlg::DoDataExchange(CDataExchange* pDX) {
	CDialog::DoDataExchange(pDX);
	//{{AFX_DATA_MAP(AboutOrbisDlg)
	//}}AFX_DATA_MAP
}	// AboutOrbisDlg::DoDataExchange

BEGIN_MESSAGE_MAP(AboutOrbisDlg, CDialog)
	//{{AFX_MSG_MAP(AboutOrbisDlg)
		// No message handlers
	//}}AFX_MSG_MAP
END_MESSAGE_MAP()

// App command to run the dialog
void OrbisApp::OnAppAbout() {
	AboutOrbisDlg aboutDlg;
	aboutDlg.DoModal();
}	// OrbisApp::OnAppAbout

