// axacctvw.cpp : implementation file
//

#include "stdafx.h"
#include "sbm.h"
#include "axacctvw.h"
#include "axtrans.h"

#ifdef _DEBUG
#undef THIS_FILE
static char BASED_CODE THIS_FILE[] = __FILE__;
#endif

/////////////////////////////////////////////////////////////////////////////
// AxAcctView

IMPLEMENT_DYNCREATE(AxAcctView, CScrollView)

AxAcctView::AxAcctView() {
	atTrans = -1;
	// TODO: add construction code here
}

AxAcctView::~AxAcctView() {
}


BEGIN_MESSAGE_MAP(AxAcctView, CScrollView)
	//{{AFX_MSG_MAP(AxAcctView)
		// NOTE - the ClassWizard will add and remove mapping macros here.
	//}}AFX_MSG_MAP
END_MESSAGE_MAP()

/////////////////////////////////////////////////////////////////////////////
// AxAcctView drawing

void AxAcctView::OnInitialUpdate() {
	CScrollView::OnInitialUpdate();
	CSize sizeTotal;
	// TODO: calculate the total size of this view
	sizeTotal.cx = sizeTotal.cy = 100;
	SetScrollSizes(MM_TEXT, sizeTotal);
}      // AxAcctView::OnInitialUpdate

#define HEADER_HEIGHT 25
#define NUM_COL 1
#define NAME_COL 40
#define BAL_COL 300
#define ROW_HEIGHT 20

void AxAcctView::OnDraw(CDC* pDC) {
	AxAcct* pDoc = GetDocument();	
	GetParent()->SetWindowText(pDoc->name);
	pDC->SetBkMode(TRANSPARENT);
	CFont hdrFont;
	hdrFont.CreateFont(HEADER_HEIGHT-4, 0, 0, 0, FW_BOLD, 0, 0, 0, 
		ANSI_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,
		PROOF_QUALITY, VARIABLE_PITCH | FF_ROMAN,
		"Times New Roman");
	pDC->SelectObject(&hdrFont);
	pDC->TextOut(0, 0, pDoc->name);
	int rowCount = 0;
	int tabStops[3] = {NUM_COL, NAME_COL, BAL_COL}; 
	CFont newFont;
	newFont.CreateFont(ROW_HEIGHT-4, 0, 0, 0, FW_BOLD, 0, 0, 0, 
		ANSI_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,
		PROOF_QUALITY, VARIABLE_PITCH | FF_ROMAN,
		"Times New Roman");
	pDC->SelectObject(&newFont);
	CBrush ltBrush, dkBrush;
	ltBrush.CreateSolidBrush(RGB(224, 224, 208));
	dkBrush.CreateSolidBrush(RGB(192, 192, 176));
	for (POSITION pos = pDoc->transl.GetHeadPosition(); pos != NULL;) {
		AxTrans *currTrans = (AxTrans *)pDoc->transl.GetNext(pos);
		CString line = currTrans->LineEntry();
		pDC->FillRect(CRect(0, HEADER_HEIGHT+rowCount*ROW_HEIGHT-2, 600, 
			HEADER_HEIGHT+(rowCount+1)*ROW_HEIGHT-2), 
			(rowCount % 2) ? &ltBrush : &dkBrush);
		pDC->TabbedTextOut(1, HEADER_HEIGHT+rowCount*ROW_HEIGHT, 
			line, line.GetLength(), 3, tabStops, NUM_COL);
		if (rowCount == atTrans)
			pDC->InvertRect(CRect(0, HEADER_HEIGHT+rowCount*ROW_HEIGHT-2, 
				600, HEADER_HEIGHT+(rowCount+1)*ROW_HEIGHT-2));
		rowCount++;
	}	// for
	pDC->MoveTo(NAME_COL-5, HEADER_HEIGHT-2);
	pDC->LineTo(NAME_COL-5, 600);
	pDC->MoveTo(BAL_COL-5, HEADER_HEIGHT-2);
	pDC->LineTo(BAL_COL-5, 600);
}	// AxAcctView::OnDraw

 /////////////////////////////////////////////////////////////////////////////
// AxAcctView printing

BOOL AxAcctView::OnPreparePrinting(CPrintInfo* pInfo) {
	// default preparation
	return DoPreparePrinting(pInfo);
}

void AxAcctView::OnBeginPrinting(CDC* /*pDC*/, CPrintInfo* /*pInfo*/) {
	// TODO: add extra initialization before printing
}

void AxAcctView::OnEndPrinting(CDC* /*pDC*/, CPrintInfo* /*pInfo*/) {
	// TODO: add cleanup after printing
}

 /////////////////////////////////////////////////////////////////////////////
// AxAcctView diagnostics

#ifdef _DEBUG
void AxAcctView::AssertValid() const {
	CView::AssertValid();
}

void AxAcctView::Dump(CDumpContext& dc) const {
	CView::Dump(dc);
}

AxAcct* AxAcctView::GetDocument() {
	ASSERT(m_pDocument->IsKindOf(RUNTIME_CLASS(AxAcct)));
	return (AxAcct*) m_pDocument;
}

#endif //_DEBUG


/////////////////////////////////////////////////////////////////////////////
// AxAcctView message handlers

