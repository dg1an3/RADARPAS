// OrbFrame.cpp  Copyright (C) 1996 DG Lane

#include "stdafx.h"
#include "Orbis.h"
#include "OrbDoc.h"
#include "OrbFrame.h"

#ifdef _DEBUG
#undef THIS_FILE
static char BASED_CODE THIS_FILE[] = __FILE__;
#endif

IMPLEMENT_DYNAMIC(OrbFrame, CMDIFrameWnd)

BEGIN_MESSAGE_MAP(OrbFrame, CMDIFrameWnd)
	//{{AFX_MSG_MAP(OrbFrame)
		// NOTE - the ClassWizard will add and remove mapping macros here.
		//    DO NOT EDIT what you see in these blocks of generated code !
	ON_WM_CREATE()
	//}}AFX_MSG_MAP
END_MESSAGE_MAP()

OrbFrame::OrbFrame() {
	map = (OrbDoc *)NULL;
}	// OrbFrame::OrbFrame

OrbFrame::~OrbFrame() {
}	// OrbFrame::~OrbFrame

int OrbFrame::OnCreate(LPCREATESTRUCT lpCreateStruct) {
	if (CMDIFrameWnd::OnCreate(lpCreateStruct) == -1)
		return -1;
	return 0;
}	// OrbFrame::OnCreate

// Disable menu commands while waiting for OLE server
BOOL OrbFrame::OnCommand(UINT wParam, LONG lParam) {
	if (COleClientItem::InWaitForRelease()) {
		AfxMessageBox(IDP_BUSY);
		return TRUE;        // handled
	}	// if
	return CMDIFrameWnd::OnCommand(wParam, lParam);
}	// OrbFrame::OnCommand

#ifdef _DEBUG
void OrbFrame::AssertValid() const {
	CMDIFrameWnd::AssertValid();
}	// OrbFrame::AssertValid

void OrbFrame::Dump(CDumpContext& dc) const {
	CMDIFrameWnd::Dump(dc);
}	// OrbFrame::Dump
#endif //_DEBUG
