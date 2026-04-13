// wlChildView.cpp  Copyright (C) 1996, 97 DG Lane

#include "stdafx.h"
#include <math.h>
#include "wlFrameView.h"
#include "wlObject.h"

#ifdef _DEBUG
#undef THIS_FILE
static char BASED_CODE THIS_FILE[] = __FILE__;
#endif

wlChildView::wlChildView() : CMDIChildWnd() {
		myObject = (wlObject *)NULL;

		compDC = NULL;
		compBitmap = NULL;
		
		myX = 0;
		myY = 0;
		myWidth = 0;
		CRect bound;
}

wlChildView::wlChildView(wlObject *ofObject) : CMDIChildWnd() {
		myObject = ofObject;

		compDC = NULL;
		compBitmap = NULL;
		
		myX = rand() % 600 + 100;
		myY = rand() % 400 + 100;
		myWidth = 40.0;
		CRect bound;
		myObject->getAspectHint((long)(myWidth*myWidth), &bound);
		bound.OffsetRect((int)myX, (int)myY);

		wlFrameView *parent = (wlFrameView *)AfxGetApp()->m_pMainWnd; ASSERT(parent);
		parent->dTotalArea( myWidth*myWidth );
		
		Create(NULL, "aWheelObject", WS_DLGFRAME | WS_CHILD | WS_CLIPSIBLINGS | WS_VISIBLE, 
				bound, parent);
}

IMPLEMENT_DYNCREATE( wlChildView, CMDIChildWnd )

wlChildView::~wlChildView() { 
		if (compDC) {
				compDC->DeleteDC();
				delete compDC;
		}
		if (compBitmap)
				delete compBitmap;
				
		delete myObject;
}

BOOL wlChildView::Draw(CDC* pDC, LPCRECT lpBounds, LPCRECT lpWBound, CDC *pFormatDC) {
		if (!compDC) {
				compDC = new CDC();
				compDC->CreateCompatibleDC(pDC);
				ASSERT(!compBitmap);
				compBitmap = new CBitmap();
				compBitmap->CreateCompatibleBitmap(pDC, 100, 100);
				compDC->SelectObject(compBitmap);
				compDC->SelectStockObject(BLACK_BRUSH);
				compDC->Rectangle(0, 0, 105, 105);
				int nextScaleHint;
				myObject->Draw(compDC, CRect(0, 0, 100, 100), &nextScaleHint);
		}
		BOOL status = pDC->StretchBlt(lpBounds->left, lpBounds->top, 
				lpBounds->right-lpBounds->left, lpBounds->bottom-lpBounds->top,
				compDC, 0, 0, 100, 100, SRCCOPY);
		return status;
}

void wlChildView::OnPaint() {
		CPaintDC dc(this); // device context for painting
		CRect clientRect;
		GetClientRect(&clientRect);
		Draw(&dc, &clientRect);
		// Do not call CWnd::OnPaint() for painting messages
}

#define pi (atan(1.0)*4.0)
#define gauss(x, s) (exp( -(x)*(x) / (2.0*(s)) ) / (sqrt(2.0 * pi )* (s)) )
#define dgauss(x, s) ((-2*(x) / (2.0*(s))) * gauss(x, s))
// #define sigma 1000.0
#define optSize (600.0 * 800.0/8.0)

void wlChildView::updatePos() {
		wlFrameView *parent = (wlFrameView *)AfxGetApp()->m_pMainWnd;
		ASSERT(parent);	
		CRect parentRect; 
		parent->GetClientRect(&parentRect);

		double gradX = 0.0, 
			   gradY = 0.0;
		for (int count = 0; count < numChildren; count++) {
				wlChildView *sibling = parent->getChild(count);
				if (sibling != this) {
						double sigma = sibling->myWidth*40.0;
						ASSERT(sigma >= 0.0);
						gradX += 1e+8 * dgauss(sibling->myX - myX, sigma) *
				     			gauss(sibling->myY - myY, sigma) * (sqrt(2.0 * pi )* (sigma));
						gradY += 1e+8 * gauss(sibling->myX - myX, sigma) * 
					 			dgauss(sibling->myY - myY, sigma) * (sqrt(2.0 * pi )* (sigma));
				}
		}
		myX += gradX - 5e-2 * -2.0*((parentRect.right - parentRect.left)/2.0 - myX);
		myY += gradY - 5e-2 * -2.0*((parentRect.bottom - parentRect.top)/2.0 - myY);
		// TRACE("gradX = %lf gradY = %lf\n", gradX, gradY);
}

void wlChildView::updateSize(CPoint mouseAt) {
		wlFrameView *parent = (wlFrameView *)AfxGetApp()->m_pMainWnd;
		ASSERT(parent);
	
		CRect oldRect;
		GetWindowRect(&oldRect);
		parent->ScreenToClient(&oldRect);
	
		double area = myWidth*myWidth;
		double sigma = myWidth*14.0; ASSERT(sigma >= 0.0);
		myWidth += (3.5e+4 *
				gauss((double)(myX - mouseAt.x), sigma) * 
				gauss((double)(myY + 40 - mouseAt.y), sigma)) * (sqrt(2.0 * pi )* (sigma));
		myWidth += area*(1e-7)*(optSize - parent->getTotalArea());

		parent->dTotalArea( myWidth*myWidth - area );

		CRect aspectRect;
		myObject->getAspectHint( (long)(myWidth*myWidth), &aspectRect );
		aspectRect.OffsetRect((int)myX, (int)myY);
		MoveWindow(aspectRect, FALSE);
		RedrawWindow(NULL, NULL, RDW_INVALIDATE | RDW_FRAME | 
				RDW_NOERASE | RDW_UPDATENOW);

		parent->InvalidateRect(oldRect, FALSE);
		parent->RedrawWindow(NULL, NULL, RDW_NOERASE | RDW_UPDATENOW);
}

BEGIN_MESSAGE_MAP(wlChildView, CWnd)
	//{{AFX_MSG_MAP(wlChildView)
	ON_WM_PAINT()
	//}}AFX_MSG_MAP
END_MESSAGE_MAP()
