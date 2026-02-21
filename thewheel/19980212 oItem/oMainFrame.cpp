// oMainFrame.cpp : implementation of the oMainFrame class
//

#include "stdafx.h"
#include "theWheel.h"

#include "oMainFrame.h"

#ifdef _DEBUG
#define new DEBUG_NEW
#undef THIS_FILE
static char THIS_FILE[] = __FILE__;
#endif

/////////////////////////////////////////////////////////////////////////////
// oMainFrame

IMPLEMENT_DYNCREATE(oMainFrame, CFrameWnd)

BEGIN_MESSAGE_MAP(oMainFrame, CFrameWnd)
	//{{AFX_MSG_MAP(oMainFrame)
	ON_WM_CREATE()
	ON_WM_DROPFILES()
	//}}AFX_MSG_MAP
	// Global help commands
	ON_COMMAND(ID_HELP_FINDER, CFrameWnd::OnHelpFinder)
	ON_COMMAND(ID_HELP, CFrameWnd::OnHelp)
	ON_COMMAND(ID_CONTEXT_HELP, CFrameWnd::OnContextHelp)
	ON_COMMAND(ID_DEFAULT_HELP, CFrameWnd::OnHelpFinder)
END_MESSAGE_MAP()

/////////////////////////////////////////////////////////////////////////////
// oMainFrame construction/destruction

oMainFrame::oMainFrame() {
	// TODO: add member initialization code here
	
}

oMainFrame::~oMainFrame() {
}

int 
oMainFrame::OnCreate(LPCREATESTRUCT lpCreateStruct) {

	if (CFrameWnd::OnCreate(lpCreateStruct) == -1)
		return -1;
	
	if (!m_wndToolBar.Create(this) ||
		!m_wndToolBar.LoadToolBar(IDR_MAINFRAME))
	{
		TRACE0("Failed to create toolbar\n");
		return -1;      // fail to create
	}

	// TODO: Remove this if you don't want tool tips or a resizeable toolbar
	m_wndToolBar.SetBarStyle(m_wndToolBar.GetBarStyle() |
		CBRS_TOOLTIPS | CBRS_FLYBY | CBRS_SIZE_DYNAMIC);

	// TODO: Delete these three lines if you don't want the toolbar to
	//  be dockable
	m_wndToolBar.EnableDocking(CBRS_ALIGN_ANY);
	EnableDocking(CBRS_ALIGN_ANY);
	DockControlBar(&m_wndToolBar);

	return 0;
}

BOOL 
oMainFrame::PreCreateWindow(CREATESTRUCT& cs) {

	return CFrameWnd::PreCreateWindow(cs);
}

/////////////////////////////////////////////////////////////////////////////
// oMainFrame diagnostics

#ifdef _DEBUG

void 
oMainFrame::AssertValid() const {

	CFrameWnd::AssertValid();
}

void 
oMainFrame::Dump(CDumpContext& dc) const {

	CFrameWnd::Dump(dc);
}

#endif //_DEBUG

/////////////////////////////////////////////////////////////////////////////
// oMainFrame message handlers
