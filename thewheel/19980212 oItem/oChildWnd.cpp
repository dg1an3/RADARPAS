// oChildWnd.cpp : implementation file
//

#include "stdafx.h"
#include "theWheel.h"
#include "oItem.h"
#include "oChildWnd.h"
#include "oView.h"

#ifdef _DEBUG
#define new DEBUG_NEW
#undef THIS_FILE
static char THIS_FILE[] = __FILE__;
#endif

/////////////////////////////////////////////////////////////////////////////
// oChildWnd

oChildWnd::oChildWnd() {

	myItem = NULL;
	dragState = FALSE;
}

oChildWnd::oChildWnd(oItem *forItem) {

	myItem = forItem;
	dragState = FALSE;
}

oChildWnd::~oChildWnd() {
}


BEGIN_MESSAGE_MAP(oChildWnd, CWnd)
	//{{AFX_MSG_MAP(oChildWnd)
	ON_WM_PAINT()
	ON_WM_LBUTTONDOWN()
	ON_WM_LBUTTONUP()
	ON_WM_MOUSEMOVE()
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

void 
oChildWnd::OnLButtonDown(UINT nFlags, CPoint point) {

	dragState = TRUE;
	downPoint = point;
	SetCapture();
	
	// CWnd::OnLButtonDown(nFlags, point);
}



void 
oChildWnd::OnLButtonUp(UINT nFlags, CPoint point) {

	dragState = FALSE;
	ReleaseCapture();

	// CWnd::OnLButtonUp(nFlags, point);
}

void 
oChildWnd::OnMouseMove(UINT nFlags, CPoint point) {

	MapWindowPoints(GetParent(), &point, 1);

	if (dragState) {
		point -= downPoint;
		
		CRect *myRect = &myItem->myRect;
		myRect->OffsetRect(point - myRect->TopLeft());
		MoveWindow(*myRect, TRUE);
		UpdateWindow();
	}
	
	oView *parent = (oView *)GetParent();
	ASSERT(parent->IsKindOf(RUNTIME_CLASS(oView)));
	parent->AssertValid();
	parent->OnSizingItems(::GetTickCount(), point);

	// CWnd::OnMouseMove(nFlags, point);
}
