// wlChild.cpp  Copyright (C) 1996 DG Lane

#include "stdafx.h"
#include "wlChild.h"

#include <math.h>

#ifdef _DEBUG
#undef THIS_FILE
static char BASED_CODE THIS_FILE[] = __FILE__;
#endif

IMPLEMENT_DYNCREATE( wlChild, CMDIChildWnd )

wlChild::wlChild() 
{ 
		CRect bound = CRect(300, 200, 310, 210);
		// ASSERT(AfxGetApp()->m_pMainWnd != NULL);
		Create(NULL, "Dummy Name",	 // class and window names
			/* WS_BORDER | */ WS_CHILD | WS_CLIPSIBLINGS | WS_VISIBLE,	// styles
			// WS_CAPTION | WS_VSCROLL | WS_CHILD | WS_VISIBLE,
			bound);	// rectangle, parent, child window ID
		activation = 400.0;    // = size*size;
		// sizeSpring = new wlSpring(0.25, 1.5, 
		//	GetTickCount(), activation - 100.0, 0.0);
		PostMessage(WM_UPDATESIZE);
}

wlChild::~wlChild() 
{ 
	// delete sizeSpring;
	// TODO: remove the sizeTimer
}

void 
wlChild::PostNcDestroy()
{ 
}

/* 
void 
wlChild::SetSize(int x, int y) 
{
	CRect bound;
	GetWindowRect(&bound);
	GetParent()->ScreenToClient(&bound);
	int xcenter = (bound.right + bound.left) / 2;
	int ycenter = (bound.bottom + bound.top) / 2;
	bound.left = xcenter - x / 2;
	bound.right = xcenter + x / 2;
	bound.top = ycenter - y / 2;
	bound.bottom = ycenter + y / 2;
	// bound.InflateRect(x - (bound.right - bound.left), 
	//	y - (bound.bottom - bound.top));
	SetWindowPos(&wndTop,
		bound.left, bound.top,
		bound.right - bound.left, 
		bound.bottom - bound.top,
		SWP_NOZORDER);
	// size = (bound.right - bound.left)*(bound.bottom - bound.top);
}	// wlChild::SetSize
*/

BEGIN_MESSAGE_MAP(wlChild, CWnd)
	//{{AFX_MSG_MAP(wlChild)
	ON_WM_PAINT()
	ON_WM_MOUSEMOVE()
	ON_MESSAGE(WM_UPDATESIZE, OnUpdateSize)
	ON_WM_TIMER()
	//}}AFX_MSG_MAP
END_MESSAGE_MAP()

// User-interface messages

BOOL 
wlChild::Draw(CDC* pDC, LPCRECT lpBounds, LPCRECT lpWBound, CDC *pFormatDC) 
{
	// draw the 3-D frame
	CBrush *upperLeftBrush = new CBrush(RGB(255, 255, 255)); // TODO: set the colors from
	CBrush *lowerRightBrush = new CBrush(RGB(127, 127, 127));	// theFrame background
	pDC->SelectObject(upperLeftBrush);
	pDC->MoveTo(lpBounds->left, lpBounds->bottom-1);
	pDC->LineTo(lpBounds->left, lpBounds->top);
	pDC->LineTo(lpBounds->right-1, lpBounds->top);
	pDC->SelectObject(lowerRightBrush);
	pDC->MoveTo(lpBounds->right-1, lpBounds->top);
	pDC->LineTo(lpBounds->right-1, lpBounds->bottom-1);
	pDC->LineTo(lpBounds->left, lpBounds->bottom-1);
	delete upperLeftBrush;
	delete lowerRightBrush;
	// TODO: now call document renderer
	return TRUE;
}

void 
wlChild::OnPaint() 
{
	CPaintDC dc(this); // device context for painting
	CRect clientRect;
	GetClientRect(&clientRect);
	Draw(&dc, &clientRect);
	// Do not call CWnd::OnPaint() for painting messages
}

#define DACTDMICKEY 130

void 
wlChild::OnMouseMove(UINT nFlags, CPoint point) 
{
	activation += DACTDMICKEY;
	UpdateWindow();
}

#define SPRINGK 0.2 // 1/sec^2
#define FRICTIONK 0.10
#define FIXEDDSIZE 100.0	// pixels^2
#define THRESHOLD 0.01
#define SIZETIMER 7

LONG 
wlChild::OnUpdateSize(UINT wParam, LONG lParam) 
{
	TRACE("OnUpdateSize called\n");
	CRect bound;
	GetWindowRect(&bound);
	GetParent()->ScreenToClient(&bound);
	int width = bound.right - bound.left;
	int height = bound.bottom - bound.top;
	if (width < (int)sqrt(activation)) 
	{
		bound.right++;
		bound.left--;
	} 
	else if (width > (int)sqrt(activation)) 
	{
		bound.right--;
		bound.left++;
	}
	if (height < (int)sqrt(activation)) 
	{
		bound.top--;
		bound.bottom++;
	} 
	else if (height > (int)sqrt(activation)) 
	{
		bound.top++;
		bound.bottom--;
	}
	SetWindowPos(&wndTop, bound.left, bound.top,
		bound.right - bound.left, bound.bottom - bound.top,
		SWP_NOZORDER);
	KillTimer(sizeTimer);
	sizeTimer = SetTimer(SIZETIMER, 75, NULL);
	ASSERT(sizeTimer != 0);	
	return 0;
}

void 
wlChild::OnTimer(UINT nIDEvent) 
{
	TRACE("Timer Event: ID %d, time = %ld\n", nIDEvent, ::GetTickCount());
	if (nIDEvent == SIZETIMER)
		PostMessage(WM_UPDATESIZE);
	else
		ASSERT(0);
	// CWnd::OnTimer(nIDEvent);
}

