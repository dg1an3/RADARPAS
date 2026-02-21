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


wlFrame::wlFrame() : CMDIFrameWnd() {
	totSize = 0;
	// map = (WlDocDB *)NULL;
}

wlFrame::~wlFrame() {
	for (int count = 0; count < numChildren; count++)
		if (son[count])
			delete son[count];
}

int wlFrame::OnCreate( LPCREATESTRUCT lpCreateStruct ) {
    
    int result = 0;
    
	if (CMDIFrameWnd::OnCreate(lpCreateStruct) == -1)
		result = -1;
		
	return result;
}

void wlFrame::trackMouse( long t, int x, int y ) {
	mx.addSample(x);
	my.addSample(y);
	CClientDC thisDC(this);
	// plotMousex(&mx, &thisDC);
	// TRACE("t = %6ld  mx'' = %8.4f | my'' = %8.4f\n", t, mx.dd(), my.dd());
	// TRACE("n = %6ld  avgRate = %8.4lf min = %8.4lf max = %8.4lf\n", mx.numSamples,
	//	mx.avgRate, mx.minRate, mx.maxRate);
}

#ifdef _DEBUG

void wlFrame::AssertValid() const {
	CMDIFrameWnd::AssertValid();
}

void wlFrame::Dump(CDumpContext& dc) const{
	CMDIFrameWnd::Dump(dc);
}

#endif //_DEBUG
