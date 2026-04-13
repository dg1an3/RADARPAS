// theWheelView.cpp : implementation of the CTheWheelView class
//

#include "stdafx.h"
#include "theWheel.h"

#include "theWheelDoc.h"
#include "theWheelView.h"

#ifdef _DEBUG
#define new DEBUG_NEW
#undef THIS_FILE
static char THIS_FILE[] = __FILE__;
#endif

/////////////////////////////////////////////////////////////////////////////
// CTheWheelView

IMPLEMENT_DYNCREATE(CTheWheelView, CView)

BEGIN_MESSAGE_MAP(CTheWheelView, CView)
	//{{AFX_MSG_MAP(CTheWheelView)
		// NOTE - the ClassWizard will add and remove mapping macros here.
		//    DO NOT EDIT what you see in these blocks of generated code!
	//}}AFX_MSG_MAP
	// Standard printing commands
	ON_COMMAND(ID_FILE_PRINT, CView::OnFilePrint)
	ON_COMMAND(ID_FILE_PRINT_DIRECT, CView::OnFilePrint)
	ON_COMMAND(ID_FILE_PRINT_PREVIEW, CView::OnFilePrintPreview)
END_MESSAGE_MAP()

/////////////////////////////////////////////////////////////////////////////
// CTheWheelView construction/destruction

CTheWheelView::CTheWheelView()
{
	// TODO: add construction code here

}

CTheWheelView::~CTheWheelView()
{
}

BOOL CTheWheelView::PreCreateWindow(CREATESTRUCT& cs)
{
	// TODO: Modify the Window class or styles here by modifying
	//  the CREATESTRUCT cs

	return CView::PreCreateWindow(cs);
}

/////////////////////////////////////////////////////////////////////////////
// CTheWheelView drawing

void CTheWheelView::OnDraw(CDC* pDC)
{
	CTheWheelDoc* pDoc = GetDocument();
	ASSERT_VALID(pDoc);
	// TODO: add draw code for native data here
}

/////////////////////////////////////////////////////////////////////////////
// CTheWheelView printing

BOOL CTheWheelView::OnPreparePrinting(CPrintInfo* pInfo)
{
	// default preparation
	return DoPreparePrinting(pInfo);
}

void CTheWheelView::OnBeginPrinting(CDC* /*pDC*/, CPrintInfo* /*pInfo*/)
{
	// TODO: add extra initialization before printing
}

void CTheWheelView::OnEndPrinting(CDC* /*pDC*/, CPrintInfo* /*pInfo*/)
{
	// TODO: add cleanup after printing
}

/////////////////////////////////////////////////////////////////////////////
// CTheWheelView diagnostics

#ifdef _DEBUG
void CTheWheelView::AssertValid() const
{
	CView::AssertValid();
}

void CTheWheelView::Dump(CDumpContext& dc) const
{
	CView::Dump(dc);
}

CTheWheelDoc* CTheWheelView::GetDocument() // non-debug version is inline
{
	ASSERT(m_pDocument->IsKindOf(RUNTIME_CLASS(CTheWheelDoc)));
	return (CTheWheelDoc*)m_pDocument;
}
#endif //_DEBUG

/////////////////////////////////////////////////////////////////////////////
// CTheWheelView message handlers
