// sbmview.cpp : implementation of the CSbmView class
//

#include "stdafx.h"
#include "sbm.h"

#include "sbmdoc.h"
#include "sbmview.h"

#include "AxAcctVw.h"

#ifdef _DEBUG
#undef THIS_FILE
static char BASED_CODE THIS_FILE[] = __FILE__;
#endif

/////////////////////////////////////////////////////////////////////////////
// CSbmView

IMPLEMENT_DYNCREATE(CSbmView, CView)

BEGIN_MESSAGE_MAP(CSbmView, CView)
	//{{AFX_MSG_MAP(CSbmView)
	ON_WM_LBUTTONDOWN()
	//}}AFX_MSG_MAP
	// Standard printing commands
	ON_COMMAND(ID_FILE_PRINT, CView::OnFilePrint)
	ON_COMMAND(ID_FILE_PRINT_PREVIEW, CView::OnFilePrintPreview)
END_MESSAGE_MAP()

/////////////////////////////////////////////////////////////////////////////
// CSbmView construction/destruction

CSbmView::CSbmView() {  
	atAcct = -1;
	// TODO: add construction code here
}

CSbmView::~CSbmView() {
}

/////////////////////////////////////////////////////////////////////////////
// CSbmView drawing

void CSbmView::OnInitialUpdate() {
	CView::OnInitialUpdate();
}	// CSbmView::OnInitialUpdate

#define HEADER_HEIGHT 25
#define NUM_COL 1
#define NAME_COL 40
#define BAL_COL 300
#define ROW_HEIGHT 20

void CSbmView::OnDraw(CDC* pDC) {
	CSbmDoc* pDoc = GetDocument();
	GetParent()->SetWindowText("Lane Consulting Company");
	pDC->SetBkMode(TRANSPARENT);
	CFont hdrFont;
	hdrFont.CreateFont(HEADER_HEIGHT-4, 0, 0, 0, FW_BOLD, 0, 0, 0, 
		ANSI_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,
		PROOF_QUALITY, VARIABLE_PITCH | FF_ROMAN,
		"Times New Roman");
	pDC->SelectObject(&hdrFont);
	pDC->TextOut(0, 0, "Lane Consulting Company"); 	
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
	for (POSITION pos = pDoc->acct.GetHeadPosition(); pos != NULL;) {
		AxAcct *currAcct = (AxAcct *)pDoc->acct.GetNext(pos);
		CString line = currAcct->LineEntry();
		pDC->FillRect(CRect(0, HEADER_HEIGHT+rowCount*ROW_HEIGHT-2, 600, 
			HEADER_HEIGHT+(rowCount+1)*ROW_HEIGHT-2), 
			(rowCount % 2) ? &ltBrush : &dkBrush);
		pDC->TabbedTextOut(1, HEADER_HEIGHT+rowCount*ROW_HEIGHT, 
			line, line.GetLength(), 3, tabStops, NUM_COL);
		if (rowCount == atAcct)
			pDC->InvertRect(CRect(0, HEADER_HEIGHT+rowCount*ROW_HEIGHT-2, 
				600, HEADER_HEIGHT+(rowCount+1)*ROW_HEIGHT-2));
		rowCount++;
	}	// for
	pDC->MoveTo(NAME_COL-5, HEADER_HEIGHT-2);
	pDC->LineTo(NAME_COL-5, 600);
	pDC->MoveTo(BAL_COL-5, HEADER_HEIGHT-2);
	pDC->LineTo(BAL_COL-5, 600);
}	// CSbmView::OnDraw

/////////////////////////////////////////////////////////////////////////////
// CSbmView printing

BOOL CSbmView::OnPreparePrinting(CPrintInfo* pInfo) {
	// default preparation
	return DoPreparePrinting(pInfo);
}

void CSbmView::OnBeginPrinting(CDC* /*pDC*/, CPrintInfo* /*pInfo*/) {
	// TODO: add extra initialization before printing
}

void CSbmView::OnEndPrinting(CDC* /*pDC*/, CPrintInfo* /*pInfo*/) {
	// TODO: add cleanup after printing
}




/////////////////////////////////////////////////////////////////////////////
// CSbmView diagnostics

#ifdef _DEBUG
void CSbmView::AssertValid() const {
	CView::AssertValid();
}

void CSbmView::Dump(CDumpContext& dc) const {
	CView::Dump(dc);
}

CSbmDoc* CSbmView::GetDocument() {
	ASSERT(m_pDocument->IsKindOf(RUNTIME_CLASS(CSbmDoc)));
	return (CSbmDoc*) m_pDocument;
}

#endif //_DEBUG

/////////////////////////////////////////////////////////////////////////////
// CSbmView message handlers

void CSbmView::OnLButtonDown(UINT nFlags, CPoint point) { 
	CView::OnLButtonDown(nFlags, point);
	CSbmDoc *pDoc = (CSbmDoc *)GetDocument();
	atAcct = (point.y - HEADER_HEIGHT) / ROW_HEIGHT;
	pDoc->UpdateAllViews(NULL);
	
	// locate current account
	int count = -1;
	AxAcct *currAcct;
	POSITION pos = pDoc->acct.GetHeadPosition();
	do {
		currAcct = (AxAcct *)pDoc->acct.GetNext(pos);
		count++;
	} while ((pos != NULL) && (count < atAcct));
	if (currAcct == NULL)
		return;

	CSbmApp *app = (CSbmApp *)AfxGetApp();
	CFrameWnd* pNewFrame = 
		app->AxAcctViewTemplate->CreateNewFrame(currAcct, NULL);
	if (pNewFrame == NULL)
		return ;
	app->AxAcctViewTemplate->InitialUpdateFrame(pNewFrame, currAcct);
}
