// wlFrame.cpp  Copyright (C) 1996 DG Lane
// Main frame window class -- source code

#include "stdafx.h"
#include "theWheel.h"
#include "wlFrame.h"

#ifdef _DEBUG
#undef THIS_FILE
static char BASED_CODE THIS_FILE[] = __FILE__;
#endif

IMPLEMENT_DYNAMIC(wlFrame, CMDIFrameWnd)

BEGIN_MESSAGE_MAP(wlFrame, CMDIFrameWnd)
	//{{AFX_MSG_MAP(wlFrame)
	ON_WM_CREATE()
	//}}AFX_MSG_MAP
END_MESSAGE_MAP()

wlFrame::wlFrame() {
	// map = (WlDocDB *)NULL;
}

wlFrame::~wlFrame() {
	delete onlySon;
}

int wlFrame::OnCreate(LPCREATESTRUCT lpCreateStruct) {
	if (CMDIFrameWnd::OnCreate(lpCreateStruct) == -1)
		return -1;
	return 0;
}

// Disable menu commands while waiting for OLE server
BOOL wlFrame::OnCommand(UINT wParam, LONG lParam) {
	if (COleClientItem::InWaitForRelease()) {
		AfxMessageBox(IDP_BUSY);
		return TRUE;        // handled
	}
	return CMDIFrameWnd::OnCommand(wParam, lParam);
}

#ifdef _DEBUG
void wlFrame::AssertValid() const {
	CMDIFrameWnd::AssertValid();
}

void wlFrame::Dump(CDumpContext& dc) const{
	CMDIFrameWnd::Dump(dc);
}
#endif //_DEBUG
