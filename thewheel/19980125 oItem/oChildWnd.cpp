// oChildWnd.cpp : implementation file
//

#include "stdafx.h"
#include "theWheel.h"
#include "oItem.h"
#include "oChildWnd.h"

#ifdef _DEBUG
#define new DEBUG_NEW
#undef THIS_FILE
static char THIS_FILE[] = __FILE__;
#endif

/////////////////////////////////////////////////////////////////////////////
// oChildWnd

oChildWnd::oChildWnd() {

	myItem = NULL;
}

oChildWnd::oChildWnd(oItem *forItem) {

	myItem = forItem;
}

oChildWnd::~oChildWnd() {
}


BEGIN_MESSAGE_MAP(oChildWnd, CWnd)
	//{{AFX_MSG_MAP(oChildWnd)
	ON_WM_PAINT()
	//}}AFX_MSG_MAP
END_MESSAGE_MAP()


/////////////////////////////////////////////////////////////////////////////
// oChildWnd message handlers

void 
oChildWnd::OnPaint() {

	CPaintDC dc(this); // device context for painting
	CRect inRect(myItem->myRect);
	inRect.OffsetRect( -inRect.TopLeft().x, 
					   -inRect.TopLeft().y );
	myItem->Draw(&dc, inRect);
	
	// Do not call CWnd::OnPaint() for painting messages
}
