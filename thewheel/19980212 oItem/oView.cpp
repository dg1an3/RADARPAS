// oView.cpp : implementation of the oView class
//

#include "stdafx.h"
#include "theWheel.h"

#include "oDocument.h"
#include "oItem.h"
#include "oView.h"
#include "oChildWnd.h"

#ifdef _DEBUG
#define new DEBUG_NEW
#undef THIS_FILE
static char THIS_FILE[] = __FILE__;
#endif

/////////////////////////////////////////////////////////////////////////////
// oView

IMPLEMENT_DYNCREATE(oView, CView)

BEGIN_MESSAGE_MAP(oView, CView)
	//{{AFX_MSG_MAP(oView)
	ON_WM_DESTROY()
	ON_WM_SETFOCUS()
	ON_WM_SIZE()
	ON_COMMAND(ID_OLE_INSERT_NEW, OnInsertObject)
	ON_COMMAND(ID_CANCEL_EDIT_CNTR, OnCancelEditCntr)
	ON_WM_LBUTTONDOWN()
	ON_WM_LBUTTONDBLCLK()
	ON_WM_SETCURSOR()
	ON_COMMAND(ID_EDIT_CLEAR, OnEditClear)
	ON_UPDATE_COMMAND_UI(ID_EDIT_CLEAR, OnUpdateEditClear)
	ON_COMMAND(ID_EDIT_COPY, OnEditCopy)
	ON_UPDATE_COMMAND_UI(ID_EDIT_COPY, OnUpdateEditCopy)
	ON_COMMAND(ID_EDIT_PASTE, OnEditPaste)
	ON_WM_MOUSEMOVE()
	ON_WM_CANCELMODE()
	ON_WM_DROPFILES()
	//}}AFX_MSG_MAP
END_MESSAGE_MAP()

/////////////////////////////////////////////////////////////////////////////
// oView construction/destruction

oView::oView() {

	mySelection = NULL;
	totalActivation = 0.0;
	nextSizeAt = NULL;
	nextPosAt = NULL;
}

oView::~oView() { }

BOOL 
oView::PreCreateWindow(CREATESTRUCT& cs) {

	cs.style |= WS_CLIPCHILDREN;
	return CView::PreCreateWindow(cs);
}

/////////////////////////////////////////////////////////////////////////////
// oView drawing

void 
oView::OnDraw(CDC* pDC) {

	CView::OnDraw(pDC);
	// oDocument *myDoc = GetDocument();
	// ASSERT_VALID(myDoc);

	// draw the OLE items from the list
	// POSITION pos = myDoc->GetStartPosition();
	//while (pos != NULL) {
		// draw the item
	//	oItem* item = (oItem*)myDoc->GetNextItem(pos);
	//	item->Draw(pDC, item->myRect);

		// draw the tracker over the item
	//	CRectTracker tracker;
	//	SetupTracker(item, &tracker);
	//	tracker.Draw(pDC);
	//}
}

void 
oView::OnInitialUpdate() {

	// Enable drag-and-drop for files
	DragAcceptFiles();

	CView::OnInitialUpdate();
	
	mySelection = NULL;    // initialize selection
}

void 
oView::OnDestroy() {

	// Deactivate the item on destruction; this is important
	// when a splitter view is being used.
   CView::OnDestroy();
   COleClientItem* pActiveItem = GetDocument()->GetInPlaceActiveItem(this);
   if (pActiveItem != NULL && pActiveItem->GetActiveView() == this) {
      pActiveItem->Deactivate();
      ASSERT(GetDocument()->GetInPlaceActiveItem(this) == NULL);
   }
}


/////////////////////////////////////////////////////////////////////////////
// OLE Client support and commands

BOOL 
oView::IsSelected(const CObject* item) const {

	// This works for oItems, but not for other COleClientItems
	return item == mySelection;
}

void 
oView::OnInsertObject() {

	// Invoke the standard Insert Object dialog box to obtain information
	//  for new oItem object.
	COleInsertDialog dlg;
	if (dlg.DoModal() != IDOK)
		return;

	BeginWaitCursor();

	oItem* item = NULL;
	TRY {
		// Create new item connected to this document.
		oDocument* myDoc = GetDocument();
		ASSERT_VALID(myDoc);

		item = new oItem(myDoc);
		ASSERT_VALID(item);

		// Initialize the item from the dialog data.
		if (!dlg.CreateItem(item))
			AfxThrowMemoryException();  // any exception will do
		ASSERT_VALID(item);

		item->UpdateLink();     
		item->UpdateFromServerExtent();

		// If item created from class list (not from file) then launch
		//  the server to edit the item.
		// if (dlg.GetSelectionType() == COleInsertDialog::createNewItem)
		//	item->DoVerb(OLEIVERB_SHOW, this);
		ASSERT_VALID(item);

		SetSelection(item);    
		item->InvalidateItem();
	}
	CATCH(CException, e) {
		if (item != NULL) {
			ASSERT_VALID(item);
			item->Delete();
		}
		AfxMessageBox(IDP_FAILED_TO_CREATE);
	}
	END_CATCH

	EndWaitCursor();
}

// The following command handler provides the standard keyboard
//  user interface to cancel an in-place editing session.  Here,
//  the container (not the server) causes the deactivation.
void 
oView::OnCancelEditCntr() {

	// Close any in-place active item on this view.
	oItem *item = (oItem *)GetDocument()->GetInPlaceActiveItem(this);
	if (item != NULL)
		item->Close();

	oChildWnd *itemWnd = item->myWnd;
	itemWnd->ShowWindow(SW_SHOW);
	itemWnd->MoveWindow(item->myRect, FALSE);
	itemWnd->RedrawWindow(NULL, NULL, RDW_INVALIDATE | RDW_FRAME | 
						RDW_NOERASE | RDW_UPDATENOW);	
	item->InvalidateItem();
	ASSERT(GetDocument()->GetInPlaceActiveItem(this) == NULL);
}

// Special handling of OnSetFocus and OnSize are required for a container
//  when an object is being edited in-place.
void 
oView::OnSetFocus(CWnd* pOldWnd) {

	COleClientItem* pActiveItem = 
			GetDocument()->GetInPlaceActiveItem(this);
	if (pActiveItem != NULL &&
		pActiveItem->GetItemState() == COleClientItem::activeUIState) {

		// need to set focus to this item if it is in the same view
		CWnd* pWnd = pActiveItem->GetInPlaceWindow();
		if (pWnd != NULL) {

			pWnd->SetFocus();   // don't call the base class
			return;
		}
	}

	CView::OnSetFocus(pOldWnd);
}

void 
oView::OnSize(UINT nType, int cx, int cy) {

	CView::OnSize(nType, cx, cy);
	COleClientItem* pActiveItem = GetDocument()->GetInPlaceActiveItem(this);
	if (pActiveItem != NULL)
		pActiveItem->SetItemRects();
}

/////////////////////////////////////////////////////////////////////////////
// oView diagnostics

#ifdef _DEBUG

void 
oView::AssertValid() const {

	CView::AssertValid();
}

void 
oView::Dump(CDumpContext& dc) const {

	CView::Dump(dc);
}

oDocument * 
oView::GetDocument() { // non-debug version is inline

	ASSERT(m_pDocument->IsKindOf(RUNTIME_CLASS(oDocument)));
	return (oDocument*)m_pDocument;
}

#endif //_DEBUG

/////////////////////////////////////////////////////////////////////////////
// oView message handlers

oItem * 
oView::HitTestItems(CPoint point) {

	oDocument *myDoc = GetDocument();
	oItem     *hitItem = NULL;

	POSITION pos = myDoc->GetStartPosition();
	while (pos != NULL)	{
		oItem *anItem = (oItem *)myDoc->GetNextItem(pos);
		if (anItem->myRect.PtInRect(point))
			hitItem = anItem;
	}

	return hitItem;    // return top item at point
}

void 
oView::SetSelection(oItem *toItem) {

	// close in-place active item
	if (toItem == NULL || mySelection != toItem) {
		oItem *activeItem 
			= (oItem *)GetDocument()->GetInPlaceActiveItem(this);
		if (activeItem != NULL && activeItem != toItem) {
			activeItem->Close();
			activeItem->myWnd->ShowWindow(SW_SHOW);
		}
	}

	// update view to new selection
	if (mySelection != toItem) {
		if (mySelection != NULL)
	        OnUpdate(NULL, HINT_UPDATE_ITEM, mySelection);
        
		mySelection = toItem;
		if (mySelection != NULL)
	        OnUpdate(NULL, HINT_UPDATE_ITEM, mySelection);
	}
}

void 
oView::OnLButtonDown(UINT nFlags, CPoint point)  {

	oItem* hitItem = HitTestItems(point);
	SetSelection(hitItem);

	if (hitItem != NULL) {
		CRectTracker tracker;
		SetupTracker(hitItem, &tracker);
    
		UpdateWindow();
		if (tracker.Track(this, point)) {   
			hitItem->InvalidateItem();
			hitItem->myRect = tracker.m_rect;
			hitItem->InvalidateItem();

			GetDocument()->SetModifiedFlag();
		}
	}    

	CView::OnLButtonDown(nFlags, point);
}

void 
oView::SetupTracker(oItem *forItem, CRectTracker *tracker) {

	tracker->m_rect = forItem->myRect;

	if (forItem == mySelection)
	    tracker->m_nStyle |= CRectTracker::resizeInside;
    
	if (forItem->GetType() == OT_LINK)
	    tracker->m_nStyle |= CRectTracker::dottedLine;
	else
	    tracker->m_nStyle |= CRectTracker::solidLine;
    
	if (forItem->GetItemState() == COleClientItem::openState ||
	    forItem->GetItemState() == COleClientItem::activeUIState) {    
	    tracker->m_nStyle |= CRectTracker::hatchInside;
	}
}

void 
oView::OnLButtonDblClk(UINT nFlags, CPoint point)  {

	OnLButtonDown(nFlags, point);

	if (mySelection != NULL) {
		mySelection->DoVerb(GetKeyState(VK_CONTROL) < 0 ? 
	        OLEIVERB_OPEN : OLEIVERB_PRIMARY, this);
	}

	CView::OnLButtonDblClk(nFlags, point);
}

BOOL 
oView::OnSetCursor(CWnd* pWnd, UINT nHitTest, UINT message)  {

	if (pWnd == this && mySelection != NULL) {
		// give the tracker for the selection a chance
		CRectTracker tracker;
		SetupTracker(mySelection, &tracker);
		if (tracker.SetCursor(this, nHitTest))
	        return TRUE;
	}
	
	return CView::OnSetCursor(pWnd, nHitTest, message);
}

void 
oView::OnEditClear() {

	if (mySelection != NULL) {
		mySelection->Delete();
		mySelection = NULL;
		GetDocument()->UpdateAllViews(NULL);
	}
}

void 
oView::OnUpdateEditClear(CCmdUI* pCmdUI) {

	pCmdUI->Enable(mySelection != NULL);
}

void 
oView::OnEditCopy() {

	if (mySelection)
		mySelection->CopyToClipboard();
}

void 
oView::OnUpdateEditCopy(CCmdUI* pCmdUI) {

	pCmdUI->Enable(mySelection != NULL);
}

void 
oView::OnEditPaste() {

	oItem* item = NULL;
	TRY {
		// Create new item connected to this document.
		oDocument* myDoc = GetDocument();    
		ASSERT_VALID(myDoc);
		item = new oItem(myDoc);
		ASSERT_VALID(item);    
		// Initialize the item from clipboard data
		if (!item->CreateFromClipboard())
			AfxThrowMemoryException();    // any exception will do
		ASSERT_VALID(item);        // update the size before displaying
		item->UpdateFromServerExtent();        
		// set selection to newly pasted item    SetSelection(item);    
		item->InvalidateItem();    
	}
	CATCH(CException, e) {    
		if (item != NULL) {        
			ASSERT_VALID(item);        
			item->Delete();    
		}    
		AfxMessageBox(IDP_FAILED_TO_CREATE);
	}
	END_CATCH
}

void 
oView::OnUpdate(CView* pSender, LPARAM lHint, CObject* pHint) {

	Invalidate();
	return;
	switch (lHint) {    

	case HINT_UPDATE_WINDOW:    // invalidate entire window
        Invalidate();
		break;

    case HINT_UPDATE_ITEM:        // invalidate single item        
		CRectTracker tracker;
	    SetupTracker((oItem*)pHint, &tracker);
        CRect rect;            
		tracker.GetTrueRect(rect);
        InvalidateRect(rect);
		break;    
	}
}

void 
oView::OnSizingItems(DWORD time, CPoint mouse) {

	oDocument *myDoc = GetDocument();
	ASSERT_VALID(myDoc);

	// Select the next item to size
	nextSizeAt = myDoc->GetStartPosition();
	while (nextSizeAt != NULL) {
		oItem* item = (oItem *)myDoc->GetNextItem(nextSizeAt);
	
		if (item) {
			ASSERT_VALID(item);
			item->OnSizing(time, mouse);
		}
	}
}

void 
oView::OnPosingItems(DWORD time) {

	// oDocument *myDoc = GetDocument();
	// ASSERT_VALID(myDoc);

	// Select the next item to size
	// if (!nextPosAt)
	//	nextPosAt = myDoc->GetStartPosition();
	// oItem* item = (oItem *)myDoc->GetNextItem(nextPosAt);

	// Pos it
	// item->OnPosing(time);
}

void 
oView::OnMouseMove(UINT nFlags, CPoint point) {

	DWORD time = ::GetTickCount();
	OnSizingItems(time, point);	

	// CView::OnMouseMove(nFlags, point);
}

void 
oView::dTotalActivation(double delta) {

	totalActivation += delta;
}

void 
oView::OnDropFiles(HDROP hDropInfo)  {

	// Extract the dropped file name
	UINT nameSize = 
		DragQueryFile(hDropInfo, 0, NULL, 0);

	CString fileName;
	DragQueryFile(hDropInfo, 0, 
		fileName.GetBufferSetLength(nameSize+1), nameSize+1);

	// Create the file as a linked OLE object
	oItem *newItem = new oItem(GetDocument());
	newItem->CreateLinkFromFile(fileName);
	
	newItem->UpdateLink();     
	newItem->UpdateFromServerExtent();
	newItem->InvalidateItem();

	// Don't process further, because we don't want the file opened
	// CView::OnDropFiles(hDropInfo);
}
