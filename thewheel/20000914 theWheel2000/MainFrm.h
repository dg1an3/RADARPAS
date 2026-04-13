	/////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////
// MainFrm.h
//
// Contains the declaration of the CMainFrame class for the CtheWheelApp
// application.
//
// Copyright (C) 2000, DG Lane
/////////////////////////////////////////////////////////////////////////////

	/////////////////////////////////////////////////////////////////////



/////////////////////////////////////////////////////////////////////////////
// Multiple-inclusion macro
//
/////////////////////////////////////////////////////////////////////////////
#if !defined(_MainFrm_h_)
#define _MainFrm_h_


/////////////////////////////////////////////////////////////////////////////
// Application includes
//
/////////////////////////////////////////////////////////////////////////////
#include "SpaceView.h"



/////////////////////////////////////////////////////////////////////////////
// Class CMainFrame
//
// A class that represents main window of the CtheWheelApp application
//
/////////////////////////////////////////////////////////////////////////////
//##ModelId=3985A517029A
class CMainFrame : public CFrameWnd
{	
public:

	// constructors/destructors

	//##ModelId=3985A51702F0
	CMainFrame();

	//##ModelId=3985A51702DE
	virtual ~CMainFrame();

	// accessor for the child CSpaceView
	//##ModelId=398F326903E6
	CSpaceView* GetSpaceView();

	//{{AFX_VIRTUAL(CMainFrame)
	public:
	//##ModelId=3985A51702E9
	virtual BOOL PreCreateWindow(CREATESTRUCT& cs);
	protected:
	//##ModelId=39A6BB8E01D3
	virtual BOOL OnCreateClient(LPCREATESTRUCT lpcs, CCreateContext* pContext);
	//##ModelId=3985A51702E0
	virtual BOOL OnCmdMsg(UINT nID, int nCode, void* pExtra, AFX_CMDHANDLERINFO* pHandlerInfo);
	//}}AFX_VIRTUAL

#ifdef _DEBUG
	//##ModelId=3985A51702DC
	virtual void AssertValid() const;
	//##ModelId=3985A51702D6
	virtual void Dump(CDumpContext& dc) const;
#endif

	DECLARE_DYNAMIC(CMainFrame)

protected: 

	// 
	// Generated message map functions
	//

	//{{AFX_MSG(CMainFrame)
	//##ModelId=3985A51702D3
	afx_msg int OnCreate(LPCREATESTRUCT lpCreateStruct);
	//##ModelId=3985A51702CD
	afx_msg void OnSetFocus(CWnd *pOldWnd);
	//##ModelId=39BEA899024B
	afx_msg void OnDestroy();
	//##ModelId=39BEA89901FB
	afx_msg void OnClose();
	//}}AFX_MSG
	DECLARE_MESSAGE_MAP()

private:  // control bar embedded members
	//##ModelId=3985A51702CA
	CStatusBar  m_wndStatusBar;

	//##ModelId=3985A51702C0
	CToolBar    m_wndToolBar;

	//##ModelId=39A6BB8E01BF
	CSplitterWnd m_wndSplitter;

	//##ModelId=39A6BB8E01AB
	CTreeView	m_wndTreeView;
};

/////////////////////////////////////////////////////////////////////////////

//{{AFX_INSERT_LOCATION}}
// Microsoft Visual C++ will insert additional declarations immediately before the previous line.

#endif // !defined(_MainFrm_h_)
