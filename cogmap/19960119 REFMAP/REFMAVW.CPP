// refmavw.cpp : implementation of the CRefmapView class
//

#include "stdafx.h"
#include "refmap.h"  

#include "rowview.h"
#include "refitem.h"
#include "refmadoc.h"
#include "refitemd.h"
#include "refmavw.h"

#ifdef _DEBUG
#undef THIS_FILE
static char BASED_CODE THIS_FILE[] = __FILE__;
#endif

/////////////////////////////////////////////////////////////////////////////
// CRefmapView

IMPLEMENT_DYNCREATE(CRefmapView, CView)

/////////////////////////////////////////////////////////////////////////////
// CRefmapView construction/destruction

CRefmapView::CRefmapView()
{
	// TODO: add construction code here
	m_nActiveRef = 0;
}

CRefmapView::~CRefmapView()
{
}

/////////////////////////////////////////////////////////////////////////////
// CRefmapView drawing

void CRefmapView::GetRowWidthHeight(CDC* pDC, int& nRowWidth, int& nRowHeight)
{
	CFont itemFont;
	itemFont.CreateFont(14, 0, 0, 0, FW_DONTCARE, FALSE, FALSE, 
		FALSE, ANSI_CHARSET, OUT_DEFAULT_PRECIS, 
		CLIP_DEFAULT_PRECIS, DEFAULT_QUALITY, VARIABLE_PITCH, 
		NULL);
	CFont *oldFont = pDC->SelectObject(&itemFont);
	TEXTMETRIC tm;
	pDC->GetTextMetrics(&tm);
	nRowWidth = tm.tmAveCharWidth * ROW_WIDTH;
	nRowHeight = tm.tmHeight;
	pDC->SelectObject(oldFont);
}

int CRefmapView::GetActiveRow()
{
	return m_nActiveRef;
}

int CRefmapView::GetRowCount()
{
	CRefmapDoc* pDoc = GetDocument();
	return pDoc->GetNumRef();
}

void CRefmapView::ChangeSelectionNextRow(BOOL bNext)
{
	if ((bNext) && (m_nActiveRef < (GetRowCount()-1)))
		m_nActiveRef++;
	else if (m_nActiveRef > 0)
		m_nActiveRef--;
	GetDocument()->UpdateAllViews(NULL);
}

void CRefmapView::ChangeSelectionToRow(int nRow)
{
	if (nRow < GetRowCount()-1);
	m_nActiveRef = nRow;
	GetDocument()->UpdateAllViews(NULL);
}

// void CRefmapView::OnUpdate(CView*, LPARAM lHint, CObject* pHint)
// {
	// OnUpdate() is called whenever the document has changed and,
	// therefore, the view needs to redisplay some or all of itself.

//	if (pHint != NULL && pHint->IsKindOf(RUNTIME_CLASS(CFixedLenRecHint)))
//	{
//		int nRow = LOWORD(lHint);
//		UpdateRow(nRow);
//	}
//	else
//	{
//		Invalidate();
//	}
//}

void CRefmapView::EditRow(int nRow)
{
	CRefItemDlg dlg;
	CRefItem* ref = (CRefItem *)GetDocument()->ref.GetAt(nRow);
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
}

void CRefmapView::SwapRows()
{
	CRefmapDoc *pDoc = (CRefmapDoc *)GetDocument();
	if (m_nActiveRef < pDoc->GetNumRef()-1)
		pDoc->SwapRef(m_nActiveRef, m_nActiveRef+1);
	pDoc->UpdateAllViews(NULL);
}	// CRefmapView::SwapRows    

void CRefmapView::DelRef()
{
	CRefmapDoc *pDoc = (CRefmapDoc *)GetDocument();
	if ((m_nActiveRef >= 0) && (m_nActiveRef < pDoc->GetNumRef()-1))
		pDoc->DelRef(m_nActiveRef);
	pDoc->UpdateAllViews(NULL);
}	// CRefmapView::DelRef

void CRefmapView::OnDrawRow(CDC* pDC, int nRow, int y, BOOL bSelected)
{
	// Prepare for highlighting or un-highlighting the check, depending
	// on whether it is the currently selected check or not.  And
	// paint the background (behind the text) accordingly.
	CBrush brushBackground;

	// save colors for drawing selected item on the screen
	COLORREF crOldText = 0;
	COLORREF crOldBackground = 0;

	if (!pDC->IsPrinting())
	{
		if (bSelected)
		{
			brushBackground.CreateSolidBrush(::GetSysColor(COLOR_HIGHLIGHT));
			crOldBackground = pDC->SetBkColor(::GetSysColor(COLOR_HIGHLIGHT));
			crOldText = pDC->SetTextColor(::GetSysColor(COLOR_HIGHLIGHTTEXT));
		}
		else
		{
			brushBackground.CreateSolidBrush(::GetSysColor(COLOR_WINDOW));
		}

		CRect rectSelection;
		pDC->GetClipBox(&rectSelection);
		rectSelection.top = y;
		rectSelection.bottom = y + m_nRowHeight;
		pDC->FillRect(&rectSelection, &brushBackground);
	}

	// Get the data for the specific reference
	CRefItem* ref = (CRefItem *)(GetDocument()->ref.GetAt(nRow));
	ASSERT(ref != NULL);
	CString title = ref->title.Left(TITLE_LEN-2);
	CString authors = ref->authors.Left(AUTHORS_LEN-2);
	CString source = ref->source.Left(SOURCE_LEN-2);

	CFont itemFont;
	itemFont.CreateFont(14, 0, 0, 0, FW_DONTCARE, FALSE, FALSE, 
		FALSE, ANSI_CHARSET, OUT_DEFAULT_PRECIS, 
		CLIP_DEFAULT_PRECIS, DEFAULT_QUALITY, VARIABLE_PITCH, 
		NULL);
	CFont *oldFont = pDC->SelectObject(&itemFont);
	TEXTMETRIC tm;
	pDC->GetTextMetrics(&tm);

	pDC->TextOut(TITLE_COL*tm.tmAveCharWidth, y, title);
	pDC->TextOut(AUTHORS_COL*tm.tmAveCharWidth, y, authors);
	pDC->TextOut(SOURCE_COL*tm.tmAveCharWidth, y, source);

	// Restore the DC.
	if (!pDC->IsPrinting() && bSelected)
	{
		pDC->SetBkColor(crOldBackground);
		pDC->SetTextColor(crOldText);
	}
}

/////////////////////////////////////////////////////////////////////////////
// CRefmapView diagnostics

#ifdef _DEBUG
void CRefmapView::AssertValid() const
{
	CView::AssertValid();
}

void CRefmapView::Dump(CDumpContext& dc) const
{
	CView::Dump(dc);
}

CRefmapDoc* CRefmapView::GetDocument() // non-debug version is inline
{
	ASSERT(m_pDocument->IsKindOf(RUNTIME_CLASS(CRefmapDoc)));
	return (CRefmapDoc*) m_pDocument;
}

#endif //_DEBUG

/////////////////////////////////////////////////////////////////////////////
// CRefmapView message handlers
