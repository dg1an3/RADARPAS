	/////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////
// MainFrm.cpp
//
// Contains the implementation of the CMainFrame class.
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
// indicators - holds the state of the indicators
/////////////////////////////////////////////////////////////////////////////
static UINT indicators[] =
{
	ID_SEPARATOR,           // status line indicator
	ID_INDICATOR_CAPS,
	ID_INDICATOR_NUM,
	ID_INDICATOR_SCRL,
};



/////////////////////////////////////////////////////////////////////////////
// Class CMainFrame Implementation
//
//
/////////////////////////////////////////////////////////////////////////////


/////////////////////////////////////////////////////////////////////////////
// CMainFrame::CMainFrame
//
// Constructs an empty CMainFrame object.  The Windows WM_CREATE
// and various over-rides perform the real initialization of the object.
//
/////////////////////////////////////////////////////////////////////////////
//##ModelId=3985A51702F0
CMainFrame::CMainFrame()
{
	// TODO: add member initialization code here
	
}


/////////////////////////////////////////////////////////////////////////////
// CMainFrame::~CMainFrame
//
// Destroys the CMainFrame object.
//
/////////////////////////////////////////////////////////////////////////////
//##ModelId=3985A51702DE
CMainFrame::~CMainFrame()
{
}


/////////////////////////////////////////////////////////////////////////////
// CMainFrame::GetSpaceView
//
// Returns the main frame's CSpaceView object
//
/////////////////////////////////////////////////////////////////////////////
//##ModelId=398F326903E6
CSpaceView* CMainFrame::GetSpaceView()
{
	return (CSpaceView*)m_wndSplitter.GetPane(0, 1);
}


/////////////////////////////////////////////////////////////////////////////
// CMainFrame::PreCreateWindow
//
// customizes the window style
//
/////////////////////////////////////////////////////////////////////////////
//##ModelId=3985A51702E9
BOOL CMainFrame::PreCreateWindow(CREATESTRUCT& cs)
{
	if( !CFrameWnd::PreCreateWindow(cs) )
		return FALSE;

	// TODO: Modify the Window class or styles here by modifying
	//  the CREATESTRUCT cs

	cs.dwExStyle &= ~WS_EX_CLIENTEDGE;
	cs.lpszClass = AfxRegisterWndClass(0);
	return TRUE;
}


/////////////////////////////////////////////////////////////////////////////
// CMainFrame::OnCreateClient
//
// Creates the CSpaceView, the splitter window, and the CTreeView.
//
/////////////////////////////////////////////////////////////////////////////
//##ModelId=39A6BB8E01D3
BOOL CMainFrame::OnCreateClient(LPCREATESTRUCT lpcs, CCreateContext* pContext) 
{
	// create the splitter window
	if (!m_wndSplitter.CreateStatic(this, 1, 2))
	{
		TRACE0("Failed to create splitter window\n");
		return FALSE;
	}

	// set the default size for the splitter panes
	SIZE defaultSize;
	defaultSize.cx = 1;
	defaultSize.cy = 1;

	// create the tree view
	if (!m_wndSplitter.CreateView(0, 0, RUNTIME_CLASS(CTreeView), 
			defaultSize, pContext))
	{
		TRACE0("Failed to create tree view\n");
		return FALSE;
	}

	// create the space view
	if (!m_wndSplitter.CreateView(0, 1, RUNTIME_CLASS(CSpaceView), 
			defaultSize, pContext))
	{
		TRACE0("Failed to create space view\n");
		return FALSE;
	}

	return CFrameWnd::OnCreateClient(lpcs, pContext);
}


/////////////////////////////////////////////////////////////////////////////
// CMainFrame::OnCmdMsg
//
// Gives the view a chance to respond to command messages.
//
/////////////////////////////////////////////////////////////////////////////
//##ModelId=3985A51702E0
BOOL CMainFrame::OnCmdMsg(UINT nID, int nCode, void* pExtra, AFX_CMDHANDLERINFO* pHandlerInfo)
{
	// let the view have first crack at the command
	if (GetSpaceView()->OnCmdMsg(nID, nCode, pExtra, pHandlerInfo))
		return TRUE;

	// otherwise, do default handling
	return CFrameWnd::OnCmdMsg(nID, nCode, pExtra, pHandlerInfo);
}


/////////////////////////////////////////////////////////////////////////////
// CMainFrame Diagnostics
//
// Only compile in DEBUG mode
//
/////////////////////////////////////////////////////////////////////////////
#ifdef _DEBUG


/////////////////////////////////////////////////////////////////////////////
// CMainFrame::AssertValid
//
// Tests this object for validity
//
/////////////////////////////////////////////////////////////////////////////
//##ModelId=3985A51702DC
void CMainFrame::AssertValid() const
{
	CFrameWnd::AssertValid();
}


/////////////////////////////////////////////////////////////////////////////
// CMainFrame::Dump
//
// Dumps an output of this object
//
/////////////////////////////////////////////////////////////////////////////
//##ModelId=3985A51702D6
void CMainFrame::Dump(CDumpContext& dc) const
{
	CFrameWnd::Dump(dc);
}

#endif //_DEBUG


/////////////////////////////////////////////////////////////////////////////
// IMPLEMENT_DYNAMIC Macro
//
// Allows run-time construction of CMainFrame objects
//
/////////////////////////////////////////////////////////////////////////////
IMPLEMENT_DYNAMIC(CMainFrame, CFrameWnd)


/////////////////////////////////////////////////////////////////////////////
// CMainFrame Message Map
//
/////////////////////////////////////////////////////////////////////////////
BEGIN_MESSAGE_MAP(CMainFrame, CFrameWnd)
	//{{AFX_MSG_MAP(CMainFrame)
	ON_WM_CREATE()
	ON_WM_SETFOCUS()
	ON_WM_DESTROY()
	ON_WM_CLOSE()
	//}}AFX_MSG_MAP
END_MESSAGE_MAP()


/////////////////////////////////////////////////////////////////////////////
// CMainFrame message handlers
//
/////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////
// CMainFrame::OnCreate
//
// Creates the toolbar and status bar for the application main frame.
//
/////////////////////////////////////////////////////////////////////////////
//##ModelId=3985A51702D3
int CMainFrame::OnCreate(LPCREATESTRUCT lpCreateStruct)
{
	if (CFrameWnd::OnCreate(lpCreateStruct) == -1)
		return -1;

	if (!m_wndToolBar.CreateEx(this, TBSTYLE_FLAT, WS_CHILD | WS_VISIBLE | CBRS_TOP
		| CBRS_GRIPPER | CBRS_TOOLTIPS | CBRS_FLYBY | CBRS_SIZE_DYNAMIC) ||
		!m_wndToolBar.LoadToolBar(IDR_MAINFRAME))
	{
		TRACE0("Failed to create toolbar\n");
		return -1;      // fail to create
	}

	if (!m_wndStatusBar.Create(this) ||
		!m_wndStatusBar.SetIndicators(indicators,
		  sizeof(indicators)/sizeof(UINT)))
	{
		TRACE0("Failed to create status bar\n");
		return -1;      // fail to create
	}

	// make the toolbar dockable
	m_wndToolBar.EnableDocking(CBRS_ALIGN_ANY);
	EnableDocking(CBRS_ALIGN_ANY);
	DockControlBar(&m_wndToolBar);

	return 0;
}


/////////////////////////////////////////////////////////////////////////////
// CSpaceView::OnSetFocus
//
// Defers the focus to the CSpaceView
//
/////////////////////////////////////////////////////////////////////////////
//##ModelId=3985A51702CD
void CMainFrame::OnSetFocus(CWnd* pOldWnd)
{
	// forward focus to the view window
	GetSpaceView()->SetFocus();
}


//##ModelId=39BEA899024B
void CMainFrame::OnDestroy() 
{
	CFrameWnd::OnDestroy();
	delete GetSpaceView();	
}

//##ModelId=39BEA89901FB
void CMainFrame::OnClose() 
{
	CFrameWnd::OnClose();
}
