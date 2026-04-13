/////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////
// oItem.cpp : implementation of the oItem class
/////////////////////////////////////////////////////////

#include "stdafx.h"

#include <stdlib.h>
#include <math.h>

#include "theWheel.h"

#include "Mathutil.h"

#include "oDocument.h"
#include "oView.h"
#include "oChildWnd.h"
#include "oItem.h"

#ifdef _DEBUG
#define new DEBUG_NEW
#undef THIS_FILE
static char THIS_FILE[] = __FILE__;
#endif

////////////////////////////////////////////////////////////////////
// Math stuff

#define SIGMA 80.0
#define PI    3.14159265359

double
gaussFunc( double x ) {

	double value;

	value = exp(-(x)*(x)/(SIGMA*SIGMA)) /
	             sqrt(2.0*PI*SIGMA);

	return value;
}

Lookup gauss(-160.0, 160.0, 0.1, &gaussFunc);

/////////////////////////////////////////////////////////////////////
// oItem implementation
/////////////////////////////

IMPLEMENT_SERIAL(oItem, COleClientItem, 0)

oItem::oItem(oDocument* pContainer)
	: COleClientItem(pContainer) {

	prevTime = ::GetTickCount();
	prevMag = 0.0;
	sumTime = 0;
	countTime = 0;

	oDocument *myDoc = GetDocument();
	POSITION firstViewPos = myDoc->GetFirstViewPosition();
	myParent = (oView *)myDoc->GetNextView(firstViewPos);

	myRect = CRect( 10, 10, 100, 100 );
	dActivation(myRect.Width());

	myWnd = new oChildWnd(this);
	myWnd->Create(NULL, "aWheelObject", 
		WS_DLGFRAME | WS_CHILD | WS_CLIPSIBLINGS | WS_VISIBLE, 
		myRect, myParent, 0);
}

oItem::~oItem() { 

	myWnd->DestroyWindow();
	delete myWnd;
}

//////////////////////////////////////////////////////////////////////
// When an item is being edited (either in-place or fully open)
//  it sends OnChange notifications for changes in the state of the
//  item or visual appearance of its content.
////////////////////////////////////////////////////

void 
oItem::OnChange(OLE_NOTIFICATION nCode, DWORD dwParam) {

	ASSERT_VALID(this);

	COleClientItem::OnChange(nCode, dwParam);

	switch (nCode) {

	case OLE_CHANGED:
		myWnd->Invalidate();
		UpdateFromServerExtent();
		break;

	case OLE_CHANGED_STATE:
	case OLE_CHANGED_ASPECT:
		myWnd->Invalidate();
		break;
	}
}


/////////////////////////////////////////////////////////////////////////
// During in-place activation oItem::OnChangeItemPosition				
//  is called by the server to change the position of the in-place		
//  window.  Usually, this is a result of the data in the server		
//  document changing such that the extent has changed or as a result	
//  of in-place resizing.												
////////////////////////////////

BOOL 
oItem::OnChangeItemPosition(const CRect& rectPos) {

	ASSERT_VALID(this);

	if (!COleClientItem::OnChangeItemPosition(rectPos))
		return FALSE;

	// myWnd->Invalidate();
	myRect = rectPos;
	activation = (double)(myRect.Width());
	myWnd->MoveWindow(rectPos, FALSE);
	myWnd->RedrawWindow(NULL, NULL, RDW_INVALIDATE | RDW_FRAME | 
					RDW_NOERASE | RDW_UPDATENOW);
	// myWnd->Invalidate();

	GetDocument()->SetModifiedFlag();	// mark document as dirty
	return TRUE;
}


//////////////////////////////////////////////////////////////////////
// During in-place activation, oItem::OnGetItemPosition
//  will be called to determine the location of this item.  
/////////////////////////////////////////////////////////////

void 
oItem::OnGetItemPosition(CRect& posRect) {

	ASSERT_VALID(this);

	posRect = myRect;
}


void 
oItem::OnActivate() {

    // Allow only one inplace activate item per frame
    oView* pView = GetActiveView();
    ASSERT_VALID(pView);
    oItem* oldItem = 
		(oItem *)GetDocument()->GetInPlaceActiveItem(pView);
    if (oldItem != NULL && oldItem != this) {
        oldItem->Close();
		oldItem->myWnd->ShowWindow(SW_SHOW);
	}
    
	// Hide the oChildWnd
	myWnd->ShowWindow(SW_HIDE);
    COleClientItem::OnActivate();
}


void 
oItem::OnDeactivateUI(BOOL bUndoable) {

	COleClientItem::OnDeactivateUI(bUndoable);

    // Hide the object if it is not an outside-in object
    DWORD dwMisc = 0;
    m_lpObject->GetMiscStatus(GetDrawAspect(), &dwMisc);
    if (dwMisc & OLEMISC_INSIDEOUT)
        DoVerb(OLEIVERB_HIDE, NULL);
}


void 
oItem::Serialize(CArchive& ar) {

	ASSERT_VALID(this);

	// Call base class first to read in COleClientItem data.
	// Since this sets up the m_pDocument pointer returned from
	//  oItem::GetDocument, it is a good idea to call
	//  the base class Serialize first.
	COleClientItem::Serialize(ar);

	// now store/retrieve data specific to oItem
	if (ar.IsStoring()) {

		ar << myRect;
	}
	else {

		ar >> myRect;
		activation = (double)(myRect.Width());
	}
}


/////////////////////////////////////////////////////////////////////////////
// oItem diagnostics
////////////////////////////////

#ifdef _DEBUG

void 
oItem::AssertValid() const {

	COleClientItem::AssertValid();
}

void 
oItem::Dump(CDumpContext& dc) const {

	COleClientItem::Dump(dc);
}

#endif

///////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////

void 
oItem::InvalidateItem() {

	myParent->InvalidateRect(myRect);
	myWnd->Invalidate();
	// GetDocument()->UpdateAllViews(NULL); // , HINT_UPDATE_ITEM, this);
}

void 
oItem::UpdateFromServerExtent() {

	CSize size;
	if (GetCachedExtent(&size)) {
		// OLE returns the extent in HIMETRIC units -- we need pixels
		CClientDC dc(NULL);
		dc.HIMETRICtoDP(&size);
    
		// only invalidate if it has actually changed and also only
		// if it is not in-place active.
		if (size != myRect.Size() && !IsInPlaceActive()) {

			myParent->InvalidateRect(myRect, FALSE);

			myRect.bottom = myRect.top + size.cy;
			myRect.right = myRect.left + size.cx;
			activation = (double)(myRect.Width());

			myWnd->MoveWindow(myRect, FALSE);
			myWnd->RedrawWindow(NULL, NULL, RDW_INVALIDATE | RDW_FRAME | 
					RDW_NOERASE | RDW_UPDATENOW);
			
	        // mark document as modified
			GetDocument()->SetModifiedFlag();
		}
	}
}

void 
oItem::OnSizing(DWORD time, CPoint mouse) {

	CRect oldRect;
	myWnd->GetWindowRect(&oldRect);
	myParent->ScreenToClient(&oldRect);

	sumTime += (time - prevTime);
	countTime++;
	TRACE( "avg time = %lf\n", (double)sumTime/(double)countTime );

	CPoint center = myRect.CenterPoint();
	double mag = gauss.value((double)(center.x - mouse.x))*
				 gauss.value((double)(center.y - mouse.y));
	double integ = (time - prevTime)*(mag + prevMag)/2.0;

	dActivation(0.5 * integ * myParent->totalActivation);

	prevTime = time;
	prevMag = mag;

	LONG width = getWidth();
	myRect = CRect(center - CSize(width/2, width/2),
				   CSize(width, width));

	myWnd->MoveWindow(myRect, FALSE);
	myWnd->RedrawWindow(NULL, NULL, 
		RDW_INVALIDATE | RDW_FRAME | RDW_NOERASE | RDW_UPDATENOW);	

	myParent->RedrawWindow(oldRect, NULL, 
		RDW_INVALIDATE | RDW_ERASE | RDW_UPDATENOW);
}

void 
oItem::dActivation(double delta) {

	activation += delta;
	myParent->dTotalActivation(delta);
}

#define SCALE 200.0

LONG
oItem::getWidth() {

	return (LONG)(SCALE*activation /
		                myParent->totalActivation);
}
