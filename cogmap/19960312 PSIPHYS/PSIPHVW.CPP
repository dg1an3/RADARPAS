// psiphvw.cpp : implementation of the CPsiphysView class
//

#include "stdafx.h"
#include "psiphys.h"

#include "psiphdoc.h"
#include "psiphvw.h"
#include <math.h>

#ifdef _DEBUG
#undef THIS_FILE
static char BASED_CODE THIS_FILE[] = __FILE__;
#endif

/////////////////////////////////////////////////////////////////////////////
// CPsiphysView

IMPLEMENT_DYNCREATE(CPsiphysView, CView)

BEGIN_MESSAGE_MAP(CPsiphysView, CView)
	//{{AFX_MSG_MAP(CPsiphysView)
	ON_WM_CHAR()
	//}}AFX_MSG_MAP
	// Standard printing commands
	ON_COMMAND(ID_FILE_PRINT, CView::OnFilePrint)
	ON_COMMAND(ID_FILE_PRINT_PREVIEW, CView::OnFilePrintPreview)
END_MESSAGE_MAP()

/////////////////////////////////////////////////////////////////////////////
// CPsiphysView construction/destruction

CPsiphysView::CPsiphysView()
{   
}

CPsiphysView::~CPsiphysView()
{
}

/////////////////////////////////////////////////////////////////////////////
// CPsiphysView drawing
void CPsiphysView::OnDraw(CDC* pDC)
{
	CPsiphysDoc* pDoc = GetDocument();
	CBrush* backBrush = new CBrush(RGB(0,127,0));
	CSize wndExt = pDC->GetWindowExt();   // FUCK YOU BILL GATES!!!!
	wndExt.cx = 640;
	wndExt.cy = 480;
	pDC->FillRect(CRect(0, 0, wndExt.cx, wndExt.cy), backBrush);
	pDoc->stims[pDoc->nextResp][0]->Draw(pDC, wndExt.cx/3, wndExt.cy/3, 0);
	pDoc->stims[pDoc->nextResp][1]->Draw(pDC, wndExt.cx*2/3, wndExt.cy/3, 0);
	pDoc->stims[pDoc->nextResp][2]->Draw(pDC, wndExt.cx/2, wndExt.cy*2/3, 0);
}	// CPsiphysView::OnDraw

/////////////////////////////////////////////////////////////////////////////
// CPsiphysView printing

BOOL CPsiphysView::OnPreparePrinting(CPrintInfo* pInfo)
{
	// default preparation
	return DoPreparePrinting(pInfo);
}

void CPsiphysView::OnBeginPrinting(CDC* /*pDC*/, CPrintInfo* /*pInfo*/)
{
	// TODO: add extra initialization before printing
}

void CPsiphysView::OnEndPrinting(CDC* /*pDC*/, CPrintInfo* /*pInfo*/)
{
	// TODO: add cleanup after printing
}




////////////////////////////////////////////////////////////////////////////
// CPsiphysView diagnostics

#ifdef _DEBUG
void CPsiphysView::AssertValid() const
{
	CView::AssertValid();
}

void CPsiphysView::Dump(CDumpContext& dc) const
{
	CView::Dump(dc);
}

CPsiphysDoc* CPsiphysView::GetDocument() // non-debug version is inline
{
	ASSERT(m_pDocument->IsKindOf(RUNTIME_CLASS(CPsiphysDoc)));
	return (CPsiphysDoc*) m_pDocument;
}

#endif //_DEBUG

/////////////////////////////////////////////////////////////////////////////
// CPsiphysView message handlers

void CPsiphysView::OnChar(UINT nChar, UINT nRepCnt, UINT nFlags)
{
	CPsiphysDoc *pDoc = GetDocument();

	if (pDoc->nextResp < 0)
		return;
	switch (nChar)
	{
		case 'a' : 
			pDoc->resp[pDoc->nextResp] = 0;
			break;
		case ';' : 
			pDoc->resp[pDoc->nextResp] = 1;
			break;
		case ' ' : 
			pDoc->resp[pDoc->nextResp] = 2;
			break;
		default:
			AfxMessageBox("Invalid Response.  Try Again.");
			return;
	}	// switch
	pDoc->GenNextStim();
}	// CPsiphysView::OnChar

