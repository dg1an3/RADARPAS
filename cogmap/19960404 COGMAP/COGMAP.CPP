// cogmap.cpp : Defines the class behaviors for the application.
//

#include "stdafx.h"
#include "cogmap.h"

#include "mainfrm.h"
#include "mapdoc.h"
#include "mapview.h"

#ifdef _DEBUG
#undef THIS_FILE
static char BASED_CODE THIS_FILE[] = __FILE__;
#endif

/////////////////////////////////////////////////////////////////////////////
// MapApp

BEGIN_MESSAGE_MAP(MapApp, CWinApp)
	//{{AFX_MSG_MAP(MapApp)
	ON_COMMAND(ID_APP_ABOUT, OnAppAbout)
		// NOTE - the ClassWizard will add and remove mapping macros here.
		//    DO NOT EDIT what you see in these blocks of generated code !
	//}}AFX_MSG_MAP
	// Standard file based document commands
	ON_COMMAND(ID_FILE_NEW, CWinApp::OnFileNew)
	ON_COMMAND(ID_FILE_OPEN, CWinApp::OnFileOpen)
	// Standard print setup command
	ON_COMMAND(ID_FILE_PRINT_SETUP, CWinApp::OnFilePrintSetup)
END_MESSAGE_MAP()

/////////////////////////////////////////////////////////////////////////////
// MapApp construction

MapApp::MapApp() {
	// TODO: add construction code here,
	// Place all significant initialization in InitInstance
}

/////////////////////////////////////////////////////////////////////////////
// The one and only MapApp object

MapApp NEAR theApp;

/////////////////////////////////////////////////////////////////////////////
// MapApp initialization

BOOL MapApp::InitInstance() {
	// Standard initialization
	srand( (unsigned)time( NULL ) );

	SetDialogBkColor();        // set dialog background color to gray
	LoadStdProfileSettings();  // Load standard INI file options (including MRU)

	AddDocTemplate(new CMultiDocTemplate(IDR_COGMAPTYPE,
			RUNTIME_CLASS(MapDoc),
			RUNTIME_CLASS(CMDIChildWnd),        // standard MDI child frame
			RUNTIME_CLASS(MapView)));

	CMainFrame* pMainFrame = new CMainFrame;	// create main MDI frame window
	if (!pMainFrame->LoadFrame(IDR_MAINFRAME, WS_OVERLAPPEDWINDOW | FWS_ADDTOTITLE))
		return FALSE;
	pMainFrame->ShowWindow(m_nCmdShow);
	pMainFrame->UpdateWindow();
	m_pMainWnd = pMainFrame;

	m_pMainWnd->DragAcceptFiles(); // enable file manager drag/drop and DDE Execute open
	EnableShellOpen();
	RegisterShellFileTypes();

	if (m_lpCmdLine[0] == '\0') {		// simple command line parsing
		OnFileNew();
	} else if ((m_lpCmdLine[0] == '-' || m_lpCmdLine[0] == '/') &&
		(m_lpCmdLine[1] == 'e' || m_lpCmdLine[1] == 'E')) {
		// program launched embedded - wait for DDE or OLE open
	} else {
		OpenDocumentFile(m_lpCmdLine);
	}	// if
	return TRUE;
}	// MapApp::InitInstance

BOOL MapApp::OnIdle(LONG lCount) {
	return FALSE;
}	// MapApp::OnIdle

/////////////////////////////////////////////////////////////////////////////
// AboutMapDlg dialog used for App About

class AboutMapDlg : public CDialog {
public:
	AboutMapDlg();

// Dialog Data
	//{{AFX_DATA(AboutMapDlg)
	enum { IDD = IDD_ABOUTBOX };
	//}}AFX_DATA

// Implementation
protected:
	virtual void DoDataExchange(CDataExchange* pDX);	// DDX/DDV support
	//{{AFX_MSG(AboutMapDlg)
		// No message handlers
	//}}AFX_MSG
	DECLARE_MESSAGE_MAP()
};	// class AboutMapDlg

AboutMapDlg::AboutMapDlg() : CDialog(AboutMapDlg::IDD) {
	//{{AFX_DATA_INIT(AboutMapDlg)
	//}}AFX_DATA_INIT
}	// AboutMapDlg::AboutMapDlg

void AboutMapDlg::DoDataExchange(CDataExchange* pDX) {
	CDialog::DoDataExchange(pDX);
	//{{AFX_DATA_MAP(AboutMapDlg)
	//}}AFX_DATA_MAP
}	// AboutMapDlg::DoDataExchange

BEGIN_MESSAGE_MAP(AboutMapDlg, CDialog)
	//{{AFX_MSG_MAP(AboutMapDlg)
		// No message handlers
	//}}AFX_MSG_MAP
END_MESSAGE_MAP()

// App command to run the dialog
void MapApp::OnAppAbout() {
	AboutMapDlg aboutDlg;
	aboutDlg.DoModal();
}	// MapApp::OnAppAbout

/////////////////////////////////////////////////////////////////////////////
// MapApp commands
