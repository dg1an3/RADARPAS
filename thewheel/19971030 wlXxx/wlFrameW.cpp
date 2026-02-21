// wlFrameWnd.cpp  Copyright (C) 1996, 97 DG Lane

#include "stdafx.h"
#include "wlChildW.h"

#include "wlFrameW.h"

#ifdef _DEBUG
#undef THIS_FILE
static char BASED_CODE THIS_FILE[] = __FILE__;
#endif

// wlFrameWnd::wlFrameWnd
//////////////////////////////////////////

wlFrameWnd::wlFrameWnd() : CMDIFrameWnd()  {

		atChild = NULL;
		atView = NULL;
		totArea = 0.0;
}

IMPLEMENT_DYNAMIC(wlFrameWnd, CMDIFrameWnd)


// wlFrameWnd::~wlFrameWnd
///////////////////////////////////////////

wlFrameWnd::~wlFrameWnd()  {

// remove children
		for (POSITION pos = getChildList().GetStartPosition(); pos != NULL;)  {
				wlView *view;
				wlChildWnd *childWnd;
				getChildList().GetNextAssoc(pos, (void *&)view, (void *&)childWnd);
				delete childWnd;
		}
		getChildList().RemoveAll();
		
		// remove views and objects
		for (pos = getViewList().GetStartPosition(); pos != NULL;)  {
				wlObject *object;
				wlView *view;
				getViewList().GetNextAssoc(pos, (void *&)object, (void *&)view);
				delete view;
				delete object;
		}
		getViewList().RemoveAll();
}


// wlFrameWnd::updateChildren
////////////////////////////////////////////

void 
wlFrameWnd::updateChildren(DWORD t, CPoint mouseAt)  {

// iterate through wlChildWnd's
		if (!atChild)
				atChild = getChildList().GetStartPosition();
		ASSERT(atChild);
		wlChildWnd *child;
		wlView *view;
		getChildList().GetNextAssoc(atChild, (void *&)view, (void *&)child);
		
		ASSERT(child);
		ASSERT(child->IsKindOf( RUNTIME_CLASS( wlChildWnd ) ) );

		child->gestureToView( t, mouseAt );
		child->bungeeUpdate( t );
		
		if (!updateNextView(view, t))
			return;
		
// If view activity is below threshold, remove child window
		if (view->getWidth( t ) < 30)  {
				wlChildWnd *child;
				
				// find the child window, if it exists
				if (getChildList().Lookup((void *)view, (void *&)child))  {
				
						dTotalArea(-child->getWidth( t )*child->getWidth( t ));
						getChildList().RemoveKey((void *)view);
						atChild = NULL;
						delete child;

						// Need to remove all links to the view, first
						for (POSITION pos = getViewList().GetStartPosition(); pos != NULL; )  {
						
								wlObject *obj;
								wlView *nextView;
								getViewList().GetNextAssoc(pos, (void *&)obj, (void *&)nextView);
								nextView->delLink(view);
						}							
				}
		}
}


// wlFrameWnd::updateNextView
/////////////////////////////////////////////

int
wlFrameWnd::updateNextView(wlView *view, DWORD t )  {

		ASSERT(view);
		ASSERT(view->IsKindOf( RUNTIME_CLASS( wlView ) ) );
		
		double oldWidth = view->getWidth( t );
		view->update( t, 500, 500);

		// Normalize 
		// double area = view->getWidth( t )*view->getWidth( t );
		// double dWidth = area*(5e-9)*(getAreaDelta());
		// view->setWidth(t, view->getWidth( t ) + dWidth);
		view->normalize( t );
		
		// If view activity crossed threshold, promote and create child window
		if ((oldWidth < 52) && (view->getWidth( t ) >= 52))
				promoteView(view, t);	
				
		if ((oldWidth > 46) && (view->getWidth( t ) <= 46))  {
				getViewList().RemoveKey((void *)view->getObject());
				view->removeReferences( getViewList() );
				// delete view;
				// remove view from all other views
				atView = NULL;
				return FALSE;
		}
		
		return TRUE;
}		


// wlFrameWnd::updateViews
/////////////////////////////////////////
	
void 
wlFrameWnd::updateViews( DWORD t )  {

		if (!atView)
				atView = getViewList().GetStartPosition();
		ASSERT(atView);
		wlView *view;
		wlObject *object;
		getViewList().GetNextAssoc(atView, (void *&)object, (void *&)view);
		updateNextView(view, t);
}

	
wlView *
wlFrameWnd::createView(wlObject *forObject, int atX, int atY)  {
		wlView *newView = (wlView *)NULL;
		if (!viewList.Lookup( (void *)forObject, (void *&)newView )) {
			newView = new wlView(forObject, atX, atY);
			viewList.SetAt((void *)forObject, (void *)newView);
		
			// create links to active views
			for (POSITION pos = childList.GetStartPosition(); pos != NULL;)  {
					wlChildWnd *nextWnd;
					wlView *nextActiveView;
					childList.GetNextAssoc(pos, (void *&) nextActiveView, (void *&)nextWnd);
					newView->addLink(nextActiveView);
			}
		}	
		return newView;
}
	
void
wlFrameWnd::promoteView(wlView *view, DWORD t)  {

		// create a child window for the view
		wlChildWnd *newChildWnd;
		if (!childList.Lookup((void *)view, (void *&)newChildWnd))  {
		
				newChildWnd = new wlChildWnd(view, t);
				childList.SetAt((void *)view, (void *)newChildWnd);
		
				// update existing views
				for (POSITION pos = viewList.GetStartPosition(); pos != NULL;)  {
				
						wlObject *nextObj;
						wlView *nextView;
						viewList.GetNextAssoc(pos, (void *&)nextObj, (void *&)nextView);
						nextView->addLink(view);
				}
			
				// create linked views
				wlObject *theObject = view->getObject();
				int count;
				for (pos = theObject->getLinkStartPos(), count = 0; pos != NULL; count++)  {
				
						wlObjectLink *nextLink = theObject->getNextLink(pos);
						wlView *nextView;
						if (!viewList.Lookup((void *)nextLink->getTarget(), (void *&)nextView))
								createView(nextLink->getTarget(), (int)view->getX( t )+50, (int)view->getY( t )-50+count*20);
				}
		}
}
	
#ifdef _DEBUG

void 
wlFrameWnd::AssertValid() const  {

		childList.AssertValid();
		// ASSERT(totArea >= 0.0);
		CMDIFrameWnd::AssertValid();
}

void 
wlFrameWnd::Dump(CDumpContext& dc) const  {

		dc << childList;
		dc << totArea;
		CMDIFrameWnd::Dump(dc);
}
	
#endif //_DEBUG

BEGIN_MESSAGE_MAP(wlFrameWnd, CMDIFrameWnd)
	//{{AFX_MSG_MAP(wlFrameWnd)
	ON_WM_CREATE()
	ON_WM_TIMER()
	//}}AFX_MSG_MAP
END_MESSAGE_MAP()


int 
wlFrameWnd::OnCreate( LPCREATESTRUCT lpCreateStruct )  {

		int result = 0;
		if (CMDIFrameWnd::OnCreate(lpCreateStruct) == -1)
				result = -1;				
		return result;
}


void 
wlFrameWnd::OnTimer( UINT nIDEvent )  {

	 	// Perform same function as theWheelApp::OnIdle
	 	POINT cursorPos;
		::GetCursorPos(&cursorPos);
		const MSG *currMsg = GetCurrentMessage();
	
		updateChildren( currMsg->time, CPoint(cursorPos));
		updateViews( currMsg->time );
		
		// CMDIFrameWnd::OnTimer(nIDEvent);
		
		// Call OnTimer again in 25 msec
		// const HWND handle = GetSafeHwnd();
		// timerID = SetTimer( (UINT)handle, 100, NULL );
		// ASSERT( timerID > 0 );
}
