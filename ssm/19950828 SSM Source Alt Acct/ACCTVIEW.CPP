// acctview.cpp : implementation of the CAcctView class
//

#include "stdafx.h"
#include "acct.h"

#include "acctdoc.h"
#include "acctview.h"

#ifdef _DEBUG
#undef THIS_FILE
static char BASED_CODE THIS_FILE[] = __FILE__;
#endif

/////////////////////////////////////////////////////////////////////////////
// CAcctView

IMPLEMENT_DYNCREATE(CAcctView, CView)

BEGIN_MESSAGE_MAP(CAcctView, CView)
	//{{AFX_MSG_MAP(CAcctView)
		// NOTE - the ClassWizard will add and remove mapping macros here.
		//    DO NOT EDIT what you see in these blocks of generated code !
	//}}AFX_MSG_MAP
	// Standard printing commands
	ON_COMMAND(ID_FILE_PRINT, CView::OnFilePrint)
	ON_COMMAND(ID_FILE_PRINT_PREVIEW, CView::OnFilePrintPreview)
END_MESSAGE_MAP()

/////////////////////////////////////////////////////////////////////////////
// CAcctView construction/destruction

CAcctView::CAcctView()
{
	// TODO: add construction code here
}

CAcctView::~CAcctView()
{
}

/////////////////////////////////////////////////////////////////////////////
// CAcctView drawing

void CAcctView::OnDraw(CDC* pDC)
{
	CAcctDoc* pDoc = GetDocument();

	// TODO: add draw code here
}

/////////////////////////////////////////////////////////////////////////////
// CAcctView printing

BOOL CAcctView::OnPreparePrinting(CPrintInfo* pInfo)
{
	// default preparation
	return DoPreparePrinting(pInfo);
}

void CAcctView::OnBeginPrinting(CDC* /*pDC*/, CPrintInfo* /*pInfo*/)
{
	// TODO: add extra initialization before printing
}

void CAcctView::OnEndPrinting(CDC* /*pDC*/, CPrintInfo* /*pInfo*/)
{
	// TODO: add cleanup after printing
}




/////////////////////////////////////////////////////////////////////////////
// CAcctView diagnostics

#ifdef _DEBUG
void CAcctView::AssertValid() const
{
	CView::AssertValid();
}

void CAcctView::Dump(CDumpContext& dc) const
{
	CView::Dump(dc);
}

CAcctDoc* CAcctView::GetDocument() // non-debug version is inline
{
	ASSERT(m_pDocument->IsKindOf(RUNTIME_CLASS(CAcctDoc)));
	return (CAcctDoc*) m_pDocument;
}

#endif //_DEBUG

/////////////////////////////////////////////////////////////////////////////
// CAcctView message handlers
