// mapview.cpp : implementation of the MapView class
//

#include "stdafx.h"
#include "cogmap.h"
#include <math.h>

#include "mapdoc.h"
#include "mapview.h"

#ifdef _DEBUG
#undef THIS_FILE
static char BASED_CODE THIS_FILE[] = __FILE__;
#endif

/////////////////////////////////////////////////////////////////////////////
// MapView

IMPLEMENT_DYNCREATE(MapView, CView)

BEGIN_MESSAGE_MAP(MapView, CView)
	//{{AFX_MSG_MAP(MapView)
	ON_COMMAND(ID_OLE_INSERT_NEW, OnInsertObject)
	ON_WM_MOUSEMOVE()
	ON_COMMAND(ID_VIEW_TRIAD, OnViewTriad)
	ON_UPDATE_COMMAND_UI(ID_VIEW_TRIAD, OnUpdateViewTriad)
	ON_WM_LBUTTONDOWN()
	//}}AFX_MSG_MAP
	// Standard printing commands
	ON_COMMAND(ID_FILE_PRINT, CView::OnFilePrint)
	ON_COMMAND(ID_FILE_PRINT_PREVIEW, CView::OnFilePrintPreview)
END_MESSAGE_MAP()

/////////////////////////////////////////////////////////////////////////////
// MapView construction/destruction

MapView::MapView() {
	triadView = FALSE;
	// CMDIChildWnd *parent = (CMDIChildWnd *)GetParent();
	// if (parent != NULL)
	//	parent->MDIMaximize();
}	// MapView::MapView

MapView::~MapView() { }                           

/////////////////////////////////////////////////////////////////////////////
// MapView drawing
                           
// #define WORD1X 100
// #define WORD1Y 100
// #define WORD2X 400
// #define WORD2Y 100
// #define WORD3X 250
// #define WORD3Y 300

void MapView::OnDraw(CDC* pDC) {
	MapDoc* pDoc = GetDocument();
	CBrush* backBrush = new CBrush(RGB(127,127,127));
	CRect wndExt;
	GetWindowRect(&wndExt); 
	wndExt.right -= wndExt.left; wndExt.left = 0; 
	wndExt.bottom -= wndExt.top; wndExt.top = 0;
	pDC->FillRect(wndExt, backBrush);
	delete backBrush;
    if (triadView) {
    	int currStim = pDoc->srList.GetSize()-1;
    	if ((currStim < 0) || ((StimResp *)pDoc->srList[currStim])->resp != -1)
    		currStim = pDoc->newStim();
    	WordItem *item = (WordItem *)pDoc->getItemAt(((StimResp *)pDoc->srList[currStim])->s1);
    	item->wx = wndExt.right/3.0; item->wy = wndExt.bottom/3.0; item->wz = 0.0;
    	item->Draw(pDC, CRect(0,0,0,0));
    	item = (WordItem *)pDoc->getItemAt(((StimResp *)pDoc->srList[currStim])->s2);
    	item->wx = wndExt.right*2.0/3.0; item->wy = wndExt.bottom/3.0; item->wz = 0.0;
    	item->Draw(pDC, CRect(0,0,0,0));
    	item = (WordItem *)pDoc->getItemAt(((StimResp *)pDoc->srList[currStim])->s3);
    	item->wx = wndExt.right/2.0; item->wy = wndExt.bottom*2.0/3.0; item->wz = 0.0;
    	item->Draw(pDC, CRect(0,0,0,0));
    } else {
    	POSITION pos = pDoc->GetStartPosition();
    	while (pos != NULL) {
    		MapItem *nextItem = (MapItem *)pDoc->GetNextItem(pos);
    		// if (CRect((int)nextItem->wx, (int)nextItem->wy, 
    		// if (nextItem->dirty)
    			nextItem->Draw(pDC, CRect(0,0,0,0));
    		//	nextItem->dirty = FALSE;
    		//}	// fi
	    }	// while
	}	// fi
}   // MapView::OnDraw

void MapView::OnUpdate(CView *pSender, LPARAM lHint, CObject *pHint) {
	// determine rectangle for object to be updated
	// if ((pHint != NULL) && (pHint->IsKindOf(RUNTIME_CLASS(MapItem)))) {
	// } else
	Invalidate(FALSE);
	// CView::OnUpdate(pSender, lHint, pHint);
}	// MapView::OnUpdate 


/////////////////////////////////////////////////////////////////////////////
// MapView printing

BOOL MapView::OnPreparePrinting(CPrintInfo* pInfo) {
	// default preparation
	return DoPreparePrinting(pInfo);
}	// MapView::OnPreparePrinting

void MapView::OnBeginPrinting(CDC* /*pDC*/, CPrintInfo* /*pInfo*/) {
	// TODO: add extra initialization before printing
}	// MapView::OnBeginPrinting

void MapView::OnEndPrinting(CDC* /*pDC*/, CPrintInfo* /*pInfo*/) {
	// TODO: add cleanup after printing
}	// MapView::OnEndPrinting

/////////////////////////////////////////////////////////////////////////////
// OLE Client support and commands

BOOL MapView::IsSelected(const CObject* pDocItem) const {
	// TODO: implement this function that tests for a selected OLE client item
	return FALSE;
}	// MapView::IsSelected

void MapView::OnInsertObject() {
	CString strTypeName;

	if (!AfxOleInsertDialog(strTypeName))
		return;		// no OLE class selected

	TRACE("Trying to Insert OLE item with type '%s'\n",
			(const char*)strTypeName);

	// TODO: create an embedded OLE object with that class name
	char szT[300];
	wsprintf(szT, "TODO: this function is not completely implemented.\n"
		"You must add code to create a COleClientItem\n"
		" with a type name of '%s'.\n"
		"See MapView::OnInsertObject in"
			" COGMAVW.CPP for more info.", (LPCSTR)strTypeName);
	AfxMessageBox(szT);
}	// MapView::OnInsertObject

/////////////////////////////////////////////////////////////////////////////
// MapView diagnostics

#ifdef _DEBUG
void MapView::AssertValid() const {
	CView::AssertValid();
}	// MapView::AssertValid

void MapView::Dump(CDumpContext& dc) const {
	CView::Dump(dc);
}	// MapView::Dump

MapDoc* MapView::GetDocument() { // non-debug version is inline
	ASSERT(m_pDocument->IsKindOf(RUNTIME_CLASS(MapDoc)));
	return (MapDoc*) m_pDocument;
}	// MapView::GetDocument
#endif //_DEBUG

/////////////////////////////////////////////////////////////////////////////
// MapView message handlers

void MapView::OnMouseMove(UINT nFlags, CPoint point) {
	if (!triadView) {
		MapDoc* pDoc = GetDocument();
		// determine which item the point is near
    	POSITION pos = pDoc->GetStartPosition();
    	int i = 0;
    	while (pos != NULL) {
    		MapItem *nextItem = (MapItem *)pDoc->GetNextItem(pos);
			int scale = 100;
			if (nextItem->wz > 0.0) 
				scale = (int)(500.0/sqrt(nextItem->wz));
    		CRect itemRect((int)nextItem->wx-scale/2,
    			(int)nextItem->wy-scale/2,
    			(int)nextItem->wx+scale/2,
    			(int)nextItem->wy+scale/2);
    		if (itemRect.PtInRect(point)) {
    			pDoc->user->corr[i] += 0.1;
			    pDoc->temp *= 1.05;
    		} else
    			pDoc->user->corr[i] *= 0.9;
   			i++;
	    }	// while
		pDoc->dt();
		pDoc->UpdateAllViews(NULL);
	}	// if
	CView::OnMouseMove(nFlags, point);
}	// MapView::OnMouseMove

void MapView::OnLButtonDown(UINT nFlags, CPoint point) {
	if (triadView) {
		MapDoc *pDoc = (MapDoc *)GetDocument();
		int currStim = pDoc->srList.GetSize()-1;
		CRect wndExt;
		GetWindowRect(&wndExt); 
		wndExt.right -= wndExt.left; wndExt.left = 0; 
		wndExt.bottom -= wndExt.top; wndExt.top = 0;
		CSize diff = point-CPoint(wndExt.right/3.0, wndExt.bottom/3.0);
		diff.cx = abs(diff.cx);
		diff.cy = abs(diff.cy);
		if (diff.cx + diff.cy < 100) {
			((StimResp *)pDoc->srList[currStim])->resp = 
				((StimResp *)pDoc->srList[currStim])->s1;
		} else {
			CSize diff = point-CPoint(wndExt.right*2.0/3.0, wndExt.bottom/3.0);
			diff.cx = abs(diff.cx);
			diff.cy = abs(diff.cy);
			if (diff.cx + diff.cy < 100) {
				((StimResp *)pDoc->srList[currStim])->resp = 
					((StimResp *)pDoc->srList[currStim])->s2;
			} else {
				CSize diff = point-CPoint(wndExt.right/2.0, wndExt.bottom*2.0/3.0);
				diff.cx = abs(diff.cx);
				diff.cy = abs(diff.cy);
				if (diff.cx + diff.cy < 100) {
					((StimResp *)pDoc->srList[currStim])->resp = 
						((StimResp *)pDoc->srList[currStim])->s3;
				}	// if
			}	// if
		}	// if  
		if (((StimResp *)pDoc->srList[currStim])->resp != -1)
			((StimResp *)pDoc->srList[currStim])->when = CTime::GetCurrentTime();	
				// stamp response with the current time
		// if sqrt(num of stimresp) > num of objects, generate a new object
		if (sqrt((float)pDoc->srList.GetSize()) > pDoc->m_docItemList.GetCount()) {
			pDoc->recalcCorr();
		    // select object with lowest average correlation as parent
		    float minAvg = 1.1;
		    CA1DItem *minItem = NULL;
		    POSITION pos;
		    for (pos = pDoc->GetStartPosition(); pos != NULL;) {
		    	MapItem *nextItem = (MapItem *)pDoc->GetNextItem(pos);
		    	if ((nextItem->IsKindOf(RUNTIME_CLASS(CA1DItem))) && (nextItem->avgCorr() < minAvg)) {
		    		minAvg = nextItem->avgCorr();
		    		minItem = (CA1DItem *)nextItem;
		    	}	// if
		   	}	// for
		   	if (minItem != NULL) {
		   		CA1DItem *newItem = new CA1DItem(pDoc, minItem);
		   		pDoc->AddItem(newItem);
		   		// pDoc->recalcCorr();	// don't need to recalc until end of triad mode
		   	}	// if
		}   // if
		pDoc->UpdateAllViews(NULL);
	}	// if	
	CView::OnLButtonDown(nFlags, point);
}	// MapView::OnLButtonDown

void MapView::OnViewTriad() {
	MapDoc *pDoc = (MapDoc *)GetDocument();
	triadView = !triadView;
	if (!triadView)
		pDoc->recalcCorr();	
	pDoc->UpdateAllViews(NULL);	
}	// MapView::OnViewTriad

void MapView::OnUpdateViewTriad(CCmdUI* pCmdUI) {
	pCmdUI->SetCheck(triadView);	
}	// MapView::OnUpdateViewTriad
