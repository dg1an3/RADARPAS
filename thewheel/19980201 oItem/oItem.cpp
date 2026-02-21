/////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////
// oItem.cpp : implementation of the oItem class
/////////////////////////////////////////////////////////

#include "stdafx.h"
#include "theWheel.h"

#include "oDocument.h"
#include "oView.h"
#include "oChildWnd.h"
#include "oItem.h"

#ifdef _DEBUG
#define new DEBUG_NEW
#undef THIS_FILE
static char THIS_FILE[] = __FILE__;
#endif

/////////////////////////////////////////////////////////////////////
// oItem implementation
/////////////////////////////

IMPLEMENT_SERIAL(oItem, COleClientItem, 0)

oItem::oItem(oDocument* pContainer)
	: COleClientItem(pContainer) {

	myRect = CRect( 10, 10, 100, 100 );
	myWnd = new oChildWnd(this);

	oDocument *myDoc = GetDocument();
	POSITION firstViewPos = myDoc->GetFirstViewPosition();
	oView *parent = 
			(oView *)myDoc->GetNextView(firstViewPos);
	myWnd->Create(NULL, "aWheelObject", 
		WS_DLGFRAME | WS_CHILD | WS_CLIPSIBLINGS | WS_VISIBLE, 
		myRect, parent, 0);
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
		InvalidateItem();
		UpdateFromServerExtent();
		break;

	case OLE_CHANGED_STATE:
	case OLE_CHANGED_ASPECT:
		InvalidateItem();
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

	InvalidateItem();
	myRect = rectPos;
	myWnd->MoveWindow(rectPos, FALSE);
	myWnd->RedrawWindow(NULL, NULL, RDW_INVALIDATE | RDW_FRAME | 
					RDW_NOERASE | RDW_UPDATENOW);
	InvalidateItem();

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
			// invalidate old, update, invalidate new
			InvalidateItem();
			myRect.bottom = myRect.top + size.cy;
			myRect.right = myRect.left + size.cx;

			myWnd->MoveWindow(myRect, FALSE);
			myWnd->RedrawWindow(NULL, NULL, RDW_INVALIDATE | RDW_FRAME | 
					RDW_NOERASE | RDW_UPDATENOW);	
			InvalidateItem();
        
	        // mark document as modified
			GetDocument()->SetModifiedFlag();
		}
	}
}

void 
oItem::OnSizing(DWORD time, CPoint mouse) {

	InvalidateItem();
	myRect.InflateRect(1, 1);
	myWnd->MoveWindow(myRect, FALSE);
	myWnd->RedrawWindow(NULL, NULL, RDW_INVALIDATE | RDW_FRAME | 
					RDW_NOERASE | RDW_UPDATENOW);	
	InvalidateItem();
}
