// mapview.cpp : implementation file
//

#include "stdafx.h"
#include "refmap.h"
#include "refitem.h"
#include "refmadoc.h"
#include "refitemd.h"
#include "mapview.h"

#ifdef _DEBUG
#undef THIS_FILE
static char BASED_CODE THIS_FILE[] = __FILE__;
#endif

/////////////////////////////////////////////////////////////////////////////
// CMapView

IMPLEMENT_DYNCREATE(CMapView, CScrollView)

CMapView::CMapView()
{
	ActiveRef = 0;
}

CMapView::~CMapView()
{
}

void CMapView::EditRow(int nRow)
{
	CRefItemDlg dlg;
	CRefmapDoc *pDoc = (CRefmapDoc *)GetDocument();
	CRefItem* ref = pDoc->getRef(nRow);
	dlg.m_id = ref->id;
	dlg.m_authors = ref->authors;
	dlg.m_institution = ref->institution;
	dlg.m_title = ref->title;
	dlg.m_source = ref->source;
	dlg.m_authors = ref->authors; 
	dlg.m_MeSH = ref->MeSH;
	dlg.m_abstract = ref->abstract;
	if (dlg.DoModal() == IDOK)
	{
		ref->id = dlg.m_id;
		ref->authors = dlg.m_authors;
		ref->institution = dlg.m_institution;
		ref->title = dlg.m_title;
		ref->source = dlg.m_source;
		ref->authors = dlg.m_authors;
		ref->MeSH = dlg.m_MeSH;
		ref->abstract = dlg.m_abstract;
	}	// if
	GetDocument()->UpdateAllViews(NULL);
}	// CMapView::EditRow

BEGIN_MESSAGE_MAP(CMapView, CScrollView)
	//{{AFX_MSG_MAP(CMapView)
	ON_WM_LBUTTONDOWN()
	ON_WM_LBUTTONDBLCLK()
	ON_WM_MOUSEMOVE()
	ON_WM_LBUTTONUP()
	ON_WM_RBUTTONDOWN()
	//}}AFX_MSG_MAP
END_MESSAGE_MAP()

/////////////////////////////////////////////////////////////////////////////
// CMapView drawing

CFont *itemFont = (CFont *)NULL;

void CMapView::OnInitialUpdate()
{
	CScrollView::OnInitialUpdate();

	CRefmapDoc *pDoc = (CRefmapDoc *)GetDocument();
	
	if (itemFont != NULL)
		delete itemFont;
	itemFont = new CFont();      
	
	int i;
	CSize sizeTotal(0,0);
	for (i = 0; i < pDoc->GetNumRef(); i++)
	{
		CRefItem *atRef = (CRefItem *)pDoc->ref[i];
		sizeTotal.cx = max(atRef->rect.right, sizeTotal.cx);
		sizeTotal.cy = max(atRef->rect.bottom, sizeTotal.cy);
		if ((i < refBlock.GetSize()) && 
			(refBlock.GetAt(i) != NULL))
			delete refBlock.GetAt(i);
		refBlock.SetAtGrow(i, new CEdit());
		                                 
		// ASSERT(atRef->fontSize == 10);
		itemFont->CreateFont(atRef->fontSize, atRef->fontSize*2/5, 
		    0, 0, FW_DONTCARE,
			FALSE, FALSE, FALSE,
			DEFAULT_CHARSET, OUT_TT_PRECIS,
			CLIP_CHARACTER_PRECIS,
			DRAFT_QUALITY, VARIABLE_PITCH | FF_ROMAN | TMPF_TRUETYPE,
			NULL);
		((CEdit *)refBlock[i])->Create(WS_CHILD | WS_VISIBLE |
			WS_BORDER | WS_DISABLED | 
			ES_CENTER | ES_MULTILINE | 
			ES_AUTOVSCROLL | ES_READONLY,
			atRef->rect, this, (UINT)0xfff);
		((CEdit *)refBlock[i])->SetFont(itemFont, TRUE);
		((CEdit *)refBlock[i])->SetWindowText(((CRefItem *)pDoc->ref[i])->title);
		// atRef->rect = // resize rect for (possible) new font		
		
	}	// for
	SetScrollSizes(MM_TEXT, sizeTotal);
	delete itemFont;
}   // CMapView::OnInitialUpdate

void CMapView::OnUpdate(CView* pSender, LPARAM lHint, 
	CObject* pHint)
{           
	CScrollView::OnUpdate(pSender, lHint, pHint);        
	
	CRefmapDoc *pDoc = (CRefmapDoc *)GetDocument();
	    
	int start, end;
	// if (lHint > 0)
	// {
	// 	start = lHint-1;
	//	end = lHint;
	// } else {
		start = 0;
		end = pDoc->GetNumRef();
	// }
		
	int i;
	CSize sizeTotal(0,0);
	for (i = start; i < end; i++)
	{
		CRefItem *atRef = (CRefItem *)pDoc->ref[i];
		ASSERT(atRef != NULL);
		sizeTotal.cx = max(atRef->rect.right, sizeTotal.cx);
		sizeTotal.cy = max(atRef->rect.bottom, sizeTotal.cy);
		if ((i < refBlock.GetSize()) && 
			(refBlock.GetAt(i) != NULL))
			delete refBlock.GetAt(i);
		refBlock.SetAtGrow(i, new CEdit());
		                 
		CFont *itemFont = new CFont();
		// if (itemFont == NULL)
		//	delete itemFont;
		// itemFont = new CFont();      
		
		// atRef->fontSize = 8;
		ASSERT(itemFont->CreateFont(atRef->fontSize, atRef->fontSize*2/5, 
		    0, 0, FW_DONTCARE,
			FALSE, FALSE, FALSE,
			DEFAULT_CHARSET, OUT_TT_PRECIS,
			CLIP_CHARACTER_PRECIS,
			DRAFT_QUALITY, VARIABLE_PITCH | FF_ROMAN | TMPF_TRUETYPE,
			NULL) != 0);
		((CEdit *)refBlock[i])->Create(WS_CHILD | WS_VISIBLE |
			WS_BORDER | WS_DISABLED |
			ES_CENTER | ES_MULTILINE | 
			ES_AUTOVSCROLL | ES_READONLY,
			atRef->rect, this, (UINT)0xfff);
		((CEdit *)refBlock[i])->SetFont(itemFont, TRUE);
		((CEdit *)refBlock[i])->SetWindowText(((CRefItem *)pDoc->ref[i])->title);
		// atRef->rect = // resize rect for (possible) new font	
		InvalidateRect(atRef->rect - GetScrollPosition());	
		
		// delete itemFont;
	}	// for
	// if (lHint == 0) 
	SetScrollSizes(MM_TEXT, sizeTotal);
}	// CMapView::OnUpdate

void CMapView::OnDraw(CDC* pDC)
{                          
	CBrush *bkBrush = new CBrush(RGB(128,128,128));
	CRect wndRect(CPoint(0,0), pDC->GetViewportExt());
	pDC->FillRect(wndRect, bkBrush);
	return;
}

/////////////////////////////////////////////////////////////////////////////
// CMapView message handlers

CPoint lButnDownAt;
int lButnDownAtRef = -1;

void CMapView::OnLButtonDown(UINT nFlags, CPoint point)
{
	CRefmapDoc *pDoc = (CRefmapDoc *)GetDocument();
	CPoint scrlPos = GetScrollPosition();	
	CPoint actPoint = point + CSize(scrlPos);
	CRefItem *atRef = (CRefItem *)pDoc->ref[ActiveRef];
	CRect textRect = atRef->rect;
	InvalidateRect(textRect - GetScrollPosition(), TRUE);

	int count;
	for (count = 0; count < pDoc->GetNumRef(); count++)
	{                                            
		atRef = (CRefItem *)pDoc->ref[count];
		textRect = atRef->rect;
		if (textRect.PtInRect(actPoint))
		{
			ActiveRef = count;			
			InvalidateRect(textRect - GetScrollPosition(), TRUE);
			lButnDownAt = actPoint;
			lButnDownAtRef = count;
			break;
		}	// if 
	}   // if
	
	CScrollView::OnLButtonDown(nFlags, point);
}   // CMapView::OnLButtonDown

void CMapView::OnLButtonDblClk(UINT nFlags, CPoint point)
{
	OnLButtonDown(nFlags, point);
	lButnDownAtRef = -1;
	lButnDownAt = CPoint(0,0);
	EditRow(ActiveRef);
	
	CScrollView::OnLButtonDblClk(nFlags, point);
}

void CMapView::OnMouseMove(UINT nFlags, CPoint point)
{
	CRefmapDoc *pDoc = (CRefmapDoc *)GetDocument();
	CPoint actPoint = point + CSize(GetScrollPosition());
	if (lButnDownAtRef >= 0)
	{
		CRefItem *atRef = 
			(CRefItem *)pDoc->ref[lButnDownAtRef];
		InvalidateRect(atRef->rect - GetScrollPosition(), TRUE);
		atRef->rect += CPoint(actPoint - lButnDownAt);
		((CEdit *)refBlock[lButnDownAtRef])->
			MoveWindow(atRef->rect - GetScrollPosition(), TRUE);
		InvalidateRect(atRef->rect - GetScrollPosition(), TRUE);
		lButnDownAt = actPoint;
	}	// if
	CScrollView::OnMouseMove(nFlags, point);
}   // CMapView::OnMouseMove


void CMapView::OnLButtonUp(UINT nFlags, CPoint point)
{
	CRefmapDoc *pDoc = (CRefmapDoc *)GetDocument();
	CPoint actPoint = point + CSize(GetScrollPosition());
	if (lButnDownAtRef >= 0)
	{
		CRefItem *atRef = 
			(CRefItem *)pDoc->ref[lButnDownAtRef];
		InvalidateRect(atRef->rect - GetScrollPosition(), TRUE);
		atRef->rect += CPoint(actPoint - lButnDownAt);
		((CEdit *)refBlock[lButnDownAtRef])->
			MoveWindow(atRef->rect - GetScrollPosition(), TRUE);
		InvalidateRect(atRef->rect - GetScrollPosition(), TRUE);
		lButnDownAtRef = -1;
	}	// if
	CScrollView::OnLButtonUp(nFlags, point);
}	// CMapView::OnLButtonUp

void CMapView::OnRButtonDown(UINT nFlags, CPoint point)
{
	CRefmapDoc *pDoc = (CRefmapDoc *)GetDocument();
	CPoint scrlPos = GetScrollPosition();
	CPoint actPoint = point + CSize(scrlPos);
	CRefItem *atRef = (CRefItem *)pDoc->ref[ActiveRef];
	CRect textRect = atRef->rect;
	InvalidateRect(textRect - GetScrollPosition(), TRUE);

	int count;
	for (count = 0; count < pDoc->GetNumRef(); count++)
	{                                            
		atRef = (CRefItem *)pDoc->ref[count];
		textRect = atRef->rect;
		if (textRect.PtInRect(actPoint))
		{
			ActiveRef = count;			
			InvalidateRect(textRect - GetScrollPosition(), TRUE);
			atRef->fontSize++;
			atRef->rect.top--;
			atRef->rect.bottom++;
			atRef->rect.left--;
			atRef->rect.right++;
			pDoc->UpdateAllViews(NULL);
			break;
		}	// if 
	}   // if

	CScrollView::OnRButtonDown(nFlags, point);
}
