	/////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////
// theWheel.cpp
//
// Contains the implementation of the CtheWheelApp class.
//
// Copyright (C) 2000, DG Lane
/////////////////////////////////////////////////////////////////////////////

	/////////////////////////////////////////////////////////////////////



/////////////////////////////////////////////////////////////////////////////
// Common pre-compiled header include file
//
/////////////////////////////////////////////////////////////////////////////
#include "stdafx.h"

/////////////////////////////////////////////////////////////////////////////
// Application includes
//
/////////////////////////////////////////////////////////////////////////////
#include "theWheel.h"
#include "MainFrm.h"


/////////////////////////////////////////////////////////////////////////////
// Windows Debug declarations
//
/////////////////////////////////////////////////////////////////////////////
#ifdef _DEBUG
#define new DEBUG_NEW
#undef THIS_FILE
static char THIS_FILE[] = __FILE__;
#endif



/////////////////////////////////////////////////////////////////////////////
// Class CtheWheelApp Implementation
//
// Application object for theWheel.  Contains a CSpace and the CMainFrame.
//
/////////////////////////////////////////////////////////////////////////////


/////////////////////////////////////////////////////////////////////////////
// CtheWheelApp::CtheWheelApp
//
// Constructs a new CtheWheelApp application object.
// Place all significant initialization in InitInstance.
//
/////////////////////////////////////////////////////////////////////////////
//##ModelId=39A59F3A0344
CtheWheelApp::CtheWheelApp()
{
}


/////////////////////////////////////////////////////////////////////////////
// The one and only CWheelApp object
/////////////////////////////////////////////////////////////////////////////
CtheWheelApp theApp;


/////////////////////////////////////////////////////////////////////////////
// CtheWheelApp::InitInstance
//
// Siginificant Windows initialization of the application object.
//
/////////////////////////////////////////////////////////////////////////////
//##ModelId=39A59F3A0342
BOOL CtheWheelApp::InitInstance()
{
	AfxEnableControlContainer();

	// Standard initialization
	// If you are not using these features and wish to reduce the size
	//  of your final executable, you should remove from the following
	//  the specific initialization routines you do not need.

#ifdef _AFXDLL
	Enable3dControls();			// Call this when using MFC in a shared DLL
#else
	Enable3dControlsStatic();	// Call this when linking to MFC statically
#endif

	// Change the registry key under which our settings are stored.
	// TODO: You should modify this string to be something appropriate
	// such as the name of your company or organization.
	SetRegistryKey(_T("Local AppWizard-Generated Applications"));

	// To create the main window, this code creates a new frame window
	// object and then sets it as the application's main window object.
	CMainFrame* pFrame = new CMainFrame;
	m_pMainWnd = pFrame;

	// create and load the frame with its resources
	pFrame->LoadFrame(IDR_MAINFRAME,
		WS_OVERLAPPEDWINDOW | FWS_ADDTOTITLE, NULL,
		NULL);

	// The one and only window has been initialized, so show and update it.
	pFrame->ShowWindow(SW_SHOW);
	pFrame->UpdateWindow();

	return TRUE;
}

/////////////////////////////////////////////////////////////////////////////
// CtheWheelApp Message Map
//
/////////////////////////////////////////////////////////////////////////////
BEGIN_MESSAGE_MAP(CtheWheelApp, CWinApp)
	//{{AFX_MSG_MAP(CtheWheelApp)
	ON_COMMAND(ID_APP_ABOUT, OnAppAbout)
	ON_COMMAND(ID_FILE_OPEN, OnFileOpen)
	ON_COMMAND(ID_FILE_SAVE, OnFileSave)
	//}}AFX_MSG_MAP
END_MESSAGE_MAP()


/////////////////////////////////////////////////////////////////////////////
// CtheWheelApp message handlers
//
/////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////
// CtheWheelApp::OnFileOpen
//
// Handles the File->Open menu command
//
/////////////////////////////////////////////////////////////////////////////
//##ModelId=39A59F3A0339
void CtheWheelApp::OnFileOpen() 
{
	CMainFrame *pFrame = static_cast<CMainFrame *>(m_pMainWnd);

	CSpaceView *pSpaceView = pFrame->GetSpaceView();

	// CFileDialog dlg("*.net");
	// dlg.m_ofn.lpstrFilter = "*.net";
	// if (dlg.DoModal() == ID_OK)
	// {
	//	AfxMessageBox("Opening file...", 0, 0);
	//  // now read the net
	//  // trigger an update of the CNetView
	// }

	// fake load
	m_space.AddNode(new CNode("base"));
	m_space.AddNode(new CNode("person"));
	m_space.AddNode(new CNode("place"));
	m_space.AddNode(new CNode("thing"));
	m_space.AddNode(new CNode("base"));
	m_space.AddNode(new CNode("person"));
	m_space.AddNode(new CNode("place"));
	m_space.AddNode(new CNode("thing"));
	m_space.AddNode(new CNode("thing"));
	m_space.AddNode(new CNode("base"));
	m_space.AddNode(new CNode("person"));
	m_space.AddNode(new CNode("place"));
	m_space.AddNode(new CNode("thing"));
	m_space.AddNode(new CNode("thing"));
	m_space.AddNode(new CNode("base"));
	m_space.AddNode(new CNode("person"));

	pSpaceView->SetSpace(&m_space);
}


/////////////////////////////////////////////////////////////////////////////
// CtheWheelApp::OnFileSave
//
// Handles the File->Save menu command
//
/////////////////////////////////////////////////////////////////////////////
//##ModelId=39A59F3A0337
void CtheWheelApp::OnFileSave() 
{	
}


/////////////////////////////////////////////////////////////////////////////
// Class CAboutDlg
//
// Dialog box to give the user information about theWheel application.
//
/////////////////////////////////////////////////////////////////////////////
//##ModelId=3985A51703AE
class CAboutDlg : public CDialog
{
public:
	// Constructs a new dialog box
	//##ModelId=3985A51703B3
	CAboutDlg();

	// Data for the dialog box
	//{{AFX_DATA(CAboutDlg)
	enum { IDD = IDD_ABOUTBOX };
	//}}AFX_DATA

	//{{AFX_VIRTUAL(CAboutDlg)
	protected:
	//##ModelId=3985A51703B0
	virtual void DoDataExchange(CDataExchange* pDX);    // DDX/DDV support
	//}}AFX_VIRTUAL

protected:
	//{{AFX_MSG(CAboutDlg)
	//}}AFX_MSG
	DECLARE_MESSAGE_MAP()
};


/////////////////////////////////////////////////////////////////////////////
// CAboutDlg::CAboutDlg
//
// Constructs a new About dialog
//
/////////////////////////////////////////////////////////////////////////////
//##ModelId=3985A51703B3
CAboutDlg::CAboutDlg() : CDialog(CAboutDlg::IDD)
{
	//{{AFX_DATA_INIT(CAboutDlg)
	//}}AFX_DATA_INIT
}


/////////////////////////////////////////////////////////////////////////////
// CAboutDlg::DoDataExchange
//
// Handles data exchange for the dialog box
//
/////////////////////////////////////////////////////////////////////////////
//##ModelId=3985A51703B0
void CAboutDlg::DoDataExchange(CDataExchange* pDX)
{
	CDialog::DoDataExchange(pDX);
	//{{AFX_DATA_MAP(CAboutDlg)
	//}}AFX_DATA_MAP
}


/////////////////////////////////////////////////////////////////////////////
// CAboutDlg Message Map
//
/////////////////////////////////////////////////////////////////////////////
BEGIN_MESSAGE_MAP(CAboutDlg, CDialog)
	//{{AFX_MSG_MAP(CAboutDlg)
	//}}AFX_MSG_MAP
END_MESSAGE_MAP()


/////////////////////////////////////////////////////////////////////////////
// CtheWheelApp::OnAppAbout
//
// Displays an About box for the application
//
/////////////////////////////////////////////////////////////////////////////
// App command to run the dialog
//##ModelId=39A59F3A033B
void CtheWheelApp::OnAppAbout()
{
	CAboutDlg aboutDlg;
	aboutDlg.DoModal();
}

