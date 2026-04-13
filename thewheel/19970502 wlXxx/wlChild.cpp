// wlChild.cpp  Copyright (C) 1996 DG Lane

#include "stdafx.h"
#include "wlChild.h"
#include "wlFrame.h"

#include <math.h>

#ifdef _DEBUG
#undef THIS_FILE
static char BASED_CODE THIS_FILE[] = __FILE__;
#endif

IMPLEMENT_DYNCREATE( wlChild, CMDIChildWnd )

wlChild::wlChild() : CMDIChildWnd() {
	wlFrame *parent = (wlFrame *)AfxGetApp()->m_pMainWnd;
	ASSERT(parent);
	x = rand() % 600 + 100;
	y = rand() % 400 + 100;
	width = 40.0;
	CRect bound = CRect((int)(x - width/2), (int)(y - width/2), 
		(int)(x + width/2), (int)(y + width/2));
	Create(NULL, "Dummy Name",	 // class and window names
		WS_DLGFRAME | WS_CHILD | WS_CLIPSIBLINGS | WS_VISIBLE,	// styles
		bound, parent);
	parent->totSize += (width*width);
	
	myDoc = new wlDoc();
}

wlChild::~wlChild() { 
	// delete sizeSpring;
	delete myDoc;
}

void wlChild::PostNcDestroy() { 
}

BEGIN_MESSAGE_MAP(wlChild, CWnd)
	//{{AFX_MSG_MAP(wlChild)
	ON_WM_PAINT()
	//}}AFX_MSG_MAP
END_MESSAGE_MAP()

// User-interface messages

BOOL wlChild::Draw(CDC* pDC, LPCRECT lpBounds, LPCRECT lpWBound, CDC *pFormatDC) {
	myDoc->Draw(pDC, lpBounds, lpWBound, pFormatDC);
	return TRUE;
}

void wlChild::OnPaint() {
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

void wlChild::updatePos() {
	wlFrame *parent = (wlFrame *)AfxGetApp()->m_pMainWnd;
	ASSERT(parent);	
	CRect parentRect; 
	parent->GetClientRect(&parentRect);

	double gradX = 0.0, 
		   gradY = 0.0;
	for (int count = 0; count < numChildren; count++)
		if (parent->son[count] != this) {
			wlChild *sibling = parent->son[count];
			double sigma = sibling->width*40.0;
			ASSERT(sigma >= 0.0);
			gradX += 1e+8 * dgauss(sibling->x - x, sigma) *
				     gauss(sibling->y - y, sigma) * (sqrt(2.0 * pi )* (sigma));
			gradY += 1e+8 * gauss(sibling->x - x, sigma) * 
					 dgauss(sibling->y - y, sigma) * (sqrt(2.0 * pi )* (sigma));
		}
	x += gradX - 5e-2 * -2.0*((parentRect.right - parentRect.left)/2.0 - x);
	y += gradY - 5e-2 * -2.0*((parentRect.bottom - parentRect.top)/2.0 - y);
	TRACE("gradX = %lf gradY = %lf\n", gradX, gradY);
}

void wlChild::updateSize(CPoint mouseAt) {
	wlFrame *parent = (wlFrame *)AfxGetApp()->m_pMainWnd;
	ASSERT(parent);
	
	CRect myRect;
	GetWindowRect(&myRect);
	parent->ScreenToClient(&myRect);
	
	double area = width*width;
	double sigma = width*14.0; ASSERT(sigma >= 0.0);
	width += (3.5e+4 *
		gauss((double)(x - mouseAt.x), sigma) * 
		gauss((double)(y + 40 - mouseAt.y), sigma)) * (sqrt(2.0 * pi )* (sigma));
	width += area*(1e-7)*(optSize - parent->totSize);	

	parent->totSize += width*width - area;

	SetWindowPos(&wndTop, (int)(x - width/2), (int)(y - width/2), 
		(int)width, (int)(3e-3*width*width+20.0), 
		SWP_NOZORDER | SWP_NOACTIVATE | SWP_NOREDRAW);	
	RedrawWindow(NULL,NULL, RDW_INVALIDATE | RDW_FRAME | RDW_NOERASE | RDW_UPDATENOW);

	parent->InvalidateRect(myRect, FALSE);
	parent->RedrawWindow(NULL, NULL, RDW_NOERASE | RDW_UPDATENOW);
}
