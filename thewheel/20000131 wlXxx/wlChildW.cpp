// wlChildW.cpp  Copyright (C) 1996, 97 DG Lane
///////////////////////////////////////////////////////////////////////

#include "stdafx.h"
#include <math.h>

#include "wlFrameW.h"
#include "wlChildW.h"
#include "wlLookup.h"

#ifdef _DEBUG
#undef THIS_FILE
static char BASED_CODE THIS_FILE[] = __FILE__;
#endif

#define MIN(x, y) ((x) < (y) ? (x) : (y))
#define MAX(x, y) ((x) > (y) ? (x) : (y))

double
expFunc( double x )  {
		return exp( x );
}

wlLookup *expTable = (wlLookup *)NULL;

wlSpring::wlSpring( DWORD t0,  double ks, double kf, double yi, double yf, double dyi_dt )  {
        
		// parameters
		k_s = ks;
		k_f = kf;
				
		// initial values
		y_f = yf;
		t_0 = (double)t0/(double)1000.0;
		
		// general solution
		computeAlphaBeta();
		
		// specific solution
		computeCaCb( yi, dyi_dt );
		
		if (!expTable)  {
				double min = MIN((alpha*5.0), (beta*5.0));
				min = MIN(min, 0.1);
				double max = MAX((alpha*5.0),(beta*5.0));
				max = MAX(max, 0.1);
				expTable = new wlLookup( min, max, 0.05, &expFunc );
		}
}
   
void
wlSpring::computeAlphaBeta()  {

		double sqrDet = (double)sqrt(k_f * k_f - (double)4.0 * k_s);
		alpha = (-k_f + sqrDet) / (double)2.0;
		beta = (-k_f - sqrDet) / (double)2.0;		
}


void
wlSpring::computeCaCb( double yi, double dyi_dt )  {

		double y0 = yi - y_f;
		c_a = (dyi_dt - alpha*y0) / 
						(beta - alpha);
		c_b = (dyi_dt - beta*y0) /
						(alpha - beta);
}

double 
wlSpring::y( DWORD t )  {

		double time = (double)t/(double)1000.0 - t_0;
		ASSERT(fabs(alpha*time) < 50.0);
		ASSERT(fabs(beta*time) < 50.0);
		return c_a*expTable->value(alpha*time) + c_b*expTable->value(beta*time) + y_f;
}

double 
wlSpring::dydt( DWORD t ) {

		double time = (double)t/(double)1000.0 - t_0;
		ASSERT(fabs(alpha*time) < 50.0);
		ASSERT(fabs(beta*time) < 50.0);
		return c_a*alpha*expTable->value(alpha*time) + c_b*beta*expTable->value(beta*time);
}		

void
wlSpring::reset( DWORD t, double yf ) {

		double yi =y(t);
		double dyi_dt = dydt(t);
		y_f = yf;
		t_0 = (double)t/(double)1000.0;
		computeCaCb( yi, dyi_dt );
}
		
// wlChildWnd default constructor
///////////////////////////////////////////////

wlChildWnd::wlChildWnd() : CMDIChildWnd()  {

		//  Initialize the member variables
		setView((wlView *)NULL);
		compDC = NULL;
		compBitmap = NULL;
		
		x = (wlSpring *)NULL;
		y = (wlSpring *)NULL;
		w = (wlSpring *)NULL;
		
		ASSERT( FALSE );
}


// wlChildWnd constructor
/////////////////////////////////////

wlChildWnd::wlChildWnd( wlView *view, DWORD t ) : CMDIChildWnd()  {

// Initialize member variables
		setView(view);
		compDC = NULL;
		compBitmap = NULL;

		x = new wlSpring( t, 1.0, 2.3, 200.0, view->getX( t ), 0.0 );
		y = new wlSpring( t, 1.0, 2.3, 200.0,  view->getY( t ), 0.0 );
		w = new wlSpring( t, 1.0, 2.3, 50.0,  view->getWidth( t ), 0.0 );

//  Set up the window rectangle
		CRect bound( 0, 0, (int) getWidth( t ), (int) getWidth( t ) );
		// myView->getAspectHint((long)(myWidth*myWidth), &bound);
		bound.OffsetRect( (int) (getX( t )-getWidth( t )/2.0), (int) (getY( t )-getWidth( t )/2.0));

//  Create the Windows HWND
		wlFrameWnd *parent = (wlFrameWnd *)AfxGetApp()->m_pMainWnd; ASSERT(parent);
		Create(NULL, "aWheelObject", 
				WS_DLGFRAME | WS_CHILD | WS_CLIPSIBLINGS, // | WS_VISIBLE, 
				bound, parent);
		ASSERT( SetWindowPos( &wndBottom, 
			0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE | 
			SWP_SHOWWINDOW ));
}


//  We need to be able to create childWnd's on-the-fly
IMPLEMENT_DYNCREATE( wlChildWnd, CMDIChildWnd )


// wlChildWnd destructor
///////////////////////////////////

wlChildWnd::~wlChildWnd()  { 

//  Destroy the DC and bitmap
		if (compDC)  {
				compDC->DeleteDC();
				delete compDC;
		}
			
		if (compBitmap)
				delete compBitmap;

// Remove the timer
		// KillTimer( timerID );
				
//  Get rid of the window, too
		DestroyWindow();
		
// Update the parent
		CRect oldRect;
		GetWindowRect(&oldRect);
		GET_PARENT( parent );
		parent->ScreenToClient(&oldRect);
		parent->InvalidateRect(oldRect, FALSE);
		parent->RedrawWindow(NULL, NULL, RDW_NOERASE | RDW_UPDATENOW);		
}


// wlChildWnd::setView
////////////////////////////////

void
wlChildWnd::setView(wlView *toView)  {

//  Remove the key from the frameWnd's child list
		wlFrameWnd *parent = (wlFrameWnd *)AfxGetApp()->m_pMainWnd; ASSERT(parent);
		parent->getChildList().RemoveKey(getView());
		
//  Set the member variable
		myView = toView;
		
//  Put the new key into the childList
		parent->getChildList().SetAt((void *)getView(), (void *)this);
}


// wlChildWnd::setWidth
////////////////////////////////
	
void
wlChildWnd::setWidth(double width)  {

		// wlFrameWnd *parent = (wlFrameWnd *)AfxGetApp()->m_pMainWnd; 
		// ASSERT(parent);
		// parent->dTotalArea( width * width - getWidth()*getWidth() );
		// myWidth = (float)width; 
		ASSERT( FALSE );
}


// wlChildWnd::Draw
/////////////////////////////

BOOL 
wlChildWnd::Draw(CDC* pDC, LPCRECT lpBounds, LPCRECT lpWBound, CDC *pFormatDC) {

//  If a bitmap has not yet been created, ask the object for one
		if (!compDC) {
				compDC = new CDC();
				compDC->CreateCompatibleDC(pDC);
				ASSERT(!compBitmap);
				compBitmap = new CBitmap();
				compBitmap->CreateCompatibleBitmap(pDC, 50, 50);
				compDC->SelectObject(compBitmap);
				compDC->SelectStockObject(BLACK_BRUSH);
				compDC->Rectangle(0, 0, 53, 53);
				// int nextScaleHint;
				myView->draw(compDC, CRect(0, 0, 50, 50)); // , &nextScaleHint);
		}
		
//  StretchBlt the bitmap into the target area
		BOOL status = pDC->StretchBlt(lpBounds->left, lpBounds->top, 
				lpBounds->right-lpBounds->left, lpBounds->bottom-lpBounds->top,
				compDC, 0, 0, 50, 50, SRCCOPY);
				
		return status;
}


#define pi (atan(1.0)*4.0)
#define gauss(x, s) (exp( -(x)*(x) / (2.0*(s)) ) / (sqrt(2.0 * pi )* (s)) )
#define dgauss(x, s) ((-2*(x) / (2.0*(s))) * gauss(x, s))


// wlChildWnd::gestureToView
///////////////////////////////////////////

void 
wlChildWnd::gestureToView( DWORD t, CPoint mouseAt )  {

		// Compute the new view width
		// double area = getWidth()*getWidth();
		double sigma = myView->getWidth( t )*14.0; // ASSERT(sigma >= 0.0);
		double newWidth = myView->getWidth( t ) 
				+ (1e+5 * gauss((double)(getX( t ) - mouseAt.x), sigma) * 
					gauss((double)(getY( t ) + 40 - mouseAt.y), sigma)) * (sqrt(2.0 * pi )* (sigma));
					
		// Set my view's width
		myView->setWidth( t, newWidth );
}


// wlChildWnd::bungeeUpdate
/////////////////////////////////////////

void
wlChildWnd::bungeeUpdate( DWORD t )  {

		GET_PARENT( parent );

/* 		x->reset( t, myView->getX( t ) );
		y->reset( t, myView->getY( t ) );
		w->reset( t, myView->getWidth( t ) ); */
		
		// Get the original bounding rectangle
		CRect oldRect;
		GetWindowRect(&oldRect);
		parent->dTotalArea( - oldRect.Width() * oldRect.Height() );
		parent->ScreenToClient(&oldRect);
        
		// Move/resize the window
		// myObject->getAspectHint( (long)(myWidth*myWidth), &aspectRect );
		float width = (float)getWidth( t );
		CRect aspectRect;		
		aspectRect = CRect(0, 0, (int)width, (int)width );
		parent->dTotalArea( aspectRect.Width() * aspectRect.Height() );
		aspectRect.OffsetRect((int)(getX( t ) - width/2.0), (int)(getY( t ) - width/2.0));
		MoveWindow(aspectRect, FALSE);
		RedrawWindow(NULL, NULL, RDW_INVALIDATE | RDW_FRAME | 
				RDW_NOERASE | RDW_UPDATENOW);

		// Update the left-over region
		parent->InvalidateRect(oldRect, FALSE);
		parent->RedrawWindow(NULL, NULL, RDW_NOERASE | RDW_UPDATENOW);
}

	 
// wlChildWnd message map
//////////////////////////////////////

BEGIN_MESSAGE_MAP(wlChildWnd, CWnd)
	//{{AFX_MSG_MAP(wlChildWnd)
	ON_WM_PAINT()
	ON_WM_TIMER()
	ON_WM_CREATE()
	//}}AFX_MSG_MAP
END_MESSAGE_MAP()


// wlChildWnd::OnPaint
//////////////////////////////////

void 
wlChildWnd::OnPaint()  {

//  Get the device context for painting
		CPaintDC dc(this);
		CRect clientRect;
		GetClientRect(&clientRect);
		
//  Pass to Draw
		Draw(&dc, &clientRect);
		// Do not call CWnd::OnPaint() for painting messages
}


// wlChildWnd::OnTimer
///////////////////////////////////

void 
wlChildWnd::OnTimer(UINT nIDEvent)  {

		GET_PARENT( parent );

		// ASSERT( nIDEvent == timerID );
				
		// Give the view an opportunity to update
        myView->update( ::GetCurrentTime(), 500, 500 );
        
		// normalize the view
		myView->normalize( 20 );
		
		//  Update the window relative to the view
		const MSG *curMsg = GetCurrentMessage();
		bungeeUpdate( curMsg->time );
        
		unsigned long interval = (unsigned long)curMsg->time - (unsigned long)lastUpdate;
		lastUpdate = curMsg->time;
         
		//  Call again in 20 msec
		// ASSERT( KillTimer( timerID ) != 0);
		// const HWND handle = GetSafeHwnd();
		// timerID = SetTimer( (UINT)handle, 20, NULL );
		// ASSERT(timerID > 0);
		// if (interval > 500)  {
		//		TRACE( "timerID = %d\n", timerID );
		//		TRACE( "interval = %ld\n", interval );
		// }
		// CWnd::OnTimer(nIDEvent);
}

int 
wlChildWnd::OnCreate( LPCREATESTRUCT lpCreateStruct )  {

		if (CWnd::OnCreate(lpCreateStruct) == -1)
				return -1;

		//  Set up timer call-back
		const HWND handle = GetSafeHwnd();
		// timerID = SetTimer( (UINT)handle, 50, NULL );
		// ASSERT(timerID > 0);		
	
		const MSG *curMsg = GetCurrentMessage();
		lastUpdate = curMsg->time;
		return 0;
}
