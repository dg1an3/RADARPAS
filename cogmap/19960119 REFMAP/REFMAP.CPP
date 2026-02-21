// refmap.cpp : Defines the class behaviors for the application.
//

#include "stdafx.h"
#include "refmap.h"

#include "mainfrm.h"
#include "refitem.h"
#include "refmadoc.h"
#include "rowview.h"
#include "refmavw.h"
#include "mapview.h"

#ifdef _DEBUG
#undef THIS_FILE
static char BASED_CODE THIS_FILE[] = __FILE__;
#endif

/////////////////////////////////////////////////////////////////////////////
// CRefmapApp

BEGIN_MESSAGE_MAP(CRefmapApp, CWinApp)
	//{{AFX_MSG_MAP(CRefmapApp)
	ON_COMMAND(ID_APP_ABOUT, OnAppAbout)
		// NOTE - the ClassWizard will add and remove mapping macros here.
		//    DO NOT EDIT what you see in these blocks of generated code !
	//}}AFX_MSG_MAP
	// Standard file based document commands
	ON_COMMAND(ID_FILE_NEW, CWinApp::OnFileNew)
	ON_COMMAND(ID_FILE_OPEN, CWinApp::OnFileOpen)
	// Standard print setup command
	ON_COMMAND(ID_FILE_PRINT_SETUP, CWinApp::OnFilePrintSetup)
	// Global help commands
	ON_COMMAND(ID_HELP_INDEX, CWinApp::OnHelpIndex)
	ON_COMMAND(ID_HELP_USING, CWinApp::OnHelpUsing)
	ON_COMMAND(ID_HELP, CWinApp::OnHelp)
	ON_COMMAND(ID_CONTEXT_HELP, CWinApp::OnContextHelp)
	ON_COMMAND(ID_DEFAULT_HELP, CWinApp::OnHelpIndex)
END_MESSAGE_MAP()

/////////////////////////////////////////////////////////////////////////////
// CRefmapApp construction

CRefmapApp::CRefmapApp()
{
	// TODO: add construction code here,
	// Place all significant initialization in InitInstance
}

/////////////////////////////////////////////////////////////////////////////
// The one and only CRefmapApp object

CRefmapApp NEAR theApp;

/////////////////////////////////////////////////////////////////////////////
// CRefmapApp initialization

BOOL CRefmapApp::InitInstance()
{
	// Standard initialization
	// If you are not using these features and wish to reduce the size
	//  of your final executable, you should remove from the following
	//  the specific initialization routines you do not need.

	SetDialogBkColor();        // set dialog background color to gray
	LoadStdProfileSettings();  // Load standard INI file options (including MRU)

	// Register the application's document templates.  Document templates
	//  serve as the connection between documents, frame windows and views.

	AddDocTemplate(new CMultiDocTemplate(IDR_REFMAPTYPE,
			RUNTIME_CLASS(CRefmapDoc),
			RUNTIME_CLASS(CMDIChildWnd),        // standard MDI child frame
			RUNTIME_CLASS(CMapView)));

	// create main MDI Frame window
	CMainFrame* pMainFrame = new CMainFrame;
	if (!pMainFrame->LoadFrame(IDR_MAINFRAME))
		return FALSE;
	pMainFrame->ShowWindow(m_nCmdShow);
	pMainFrame->UpdateWindow();
	m_pMainWnd = pMainFrame;

	// enable file manager drag/drop and DDE Execute open
	m_pMainWnd->DragAcceptFiles();
	EnableShellOpen();
	RegisterShellFileTypes();

	// simple command line parsing
	if (m_lpCmdLine[0] == '\0')
	{
		// create a new (empty) document
		OnFileNew();
	}
	else if ((m_lpCmdLine[0] == '-' || m_lpCmdLine[0] == '/') &&
		(m_lpCmdLine[1] == 'e' || m_lpCmdLine[1] == 'E'))
	{
		// program launched embedded - wait for DDE or OLE open
	}
	else
	{
		// open an existing document
		OpenDocumentFile(m_lpCmdLine);
	}

	return TRUE;
}

BOOL CRefmapApp::OnIdle(LONG lCount)
{
	BOOL cont = CWinApp::OnIdle(lCount);
    return cont;
    
    if (lCount < 10) return TRUE;
    
	// m_pMainWnd->FlashWindow(FALSE);
	CMapView *mv = (CMapView *)m_pMainWnd->GetWindow(GW_CHILD);
	ASSERT(mv != NULL);
	if (!(mv->IsKindOf(RUNTIME_CLASS(CMapView))))
		mv = (CMapView *)mv->GetWindow(GW_CHILD);
	if (!(mv->IsKindOf(RUNTIME_CLASS(CMapView))))
		mv = (CMapView *)mv->GetWindow(GW_CHILD);
	if (!(mv->IsKindOf(RUNTIME_CLASS(CMapView))))
		mv = (CMapView *)mv->GetWindow(GW_CHILD);
	// mv->FlashWindow(FALSE);
	CRefmapDoc *pDoc = (CRefmapDoc *)(mv->GetDocument());
	ASSERT(pDoc != NULL);
	if (pDoc->ref.GetSize() > 0)
	{
		int at = rand()/(RAND_MAX/(pDoc->ref.GetSize()-1)); 
		ASSERT(at < pDoc->ref.GetSize());
		CRefItem *atRef = (CRefItem *)(pDoc->ref[at]);
		mv->InvalidateRect(atRef->rect - mv->GetScrollPosition());
		atRef->rect += CPoint(5-rand()/(RAND_MAX/10), 5-rand()/(RAND_MAX/10));
		mv->InvalidateRect(atRef->rect); 
		// pDoc->UpdateAllViews((CView *)NULL, (LPARAM)at+1);
	}	
	
	return TRUE;
}

/////////////////////////////////////////////////////////////////////////////
// CAboutDlg dialog used for App About

class CAboutDlg : public CDialog
{
public:
	CAboutDlg();

// Dialog Data
	//{{AFX_DATA(CAboutDlg)
	enum { IDD = IDD_ABOUTBOX };
	//}}AFX_DATA

// Implementation
protected:
	virtual void DoDataExchange(CDataExchange* pDX);	// DDX/DDV support
	//{{AFX_MSG(CAboutDlg)
		// No message handlers
	//}}AFX_MSG
	DECLARE_MESSAGE_MAP()
};

CAboutDlg::CAboutDlg() : CDialog(CAboutDlg::IDD)
{
	//{{AFX_DATA_INIT(CAboutDlg)
	//}}AFX_DATA_INIT
}

void CAboutDlg::DoDataExchange(CDataExchange* pDX)
{
	CDialog::DoDataExchange(pDX);
	//{{AFX_DATA_MAP(CAboutDlg)
	//}}AFX_DATA_MAP
}

BEGIN_MESSAGE_MAP(CAboutDlg, CDialog)
	//{{AFX_MSG_MAP(CAboutDlg)
		// No message handlers
	//}}AFX_MSG_MAP
END_MESSAGE_MAP()

// App command to run the dialog
void CRefmapApp::OnAppAbout()
{
	CAboutDlg aboutDlg;
	aboutDlg.DoModal();
}

/////////////////////////////////////////////////////////////////////////////
// CRefmapApp commands
