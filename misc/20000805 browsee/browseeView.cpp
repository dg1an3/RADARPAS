// browseeView.cpp : implementation of the CBrowseeView class
//

#include "stdafx.h"
#include "browsee.h"

#include "browseeDoc.h"
#include "browseeView.h"

#ifdef _DEBUG
#define new DEBUG_NEW
#undef THIS_FILE
static char THIS_FILE[] = __FILE__;
#endif

/////////////////////////////////////////////////////////////////////////////
// CBrowseeView

IMPLEMENT_DYNCREATE(CBrowseeView, CHtmlView)

BEGIN_MESSAGE_MAP(CBrowseeView, CHtmlView)
	//{{AFX_MSG_MAP(CBrowseeView)
		// NOTE - the ClassWizard will add and remove mapping macros here.
		//    DO NOT EDIT what you see in these blocks of generated code!
	//}}AFX_MSG_MAP
	// Standard printing commands
	ON_COMMAND(ID_FILE_PRINT, CHtmlView::OnFilePrint)
END_MESSAGE_MAP()

/////////////////////////////////////////////////////////////////////////////
// CBrowseeView construction/destruction

CBrowseeView::CBrowseeView()
{
	// TODO: add construction code here

}

CBrowseeView::~CBrowseeView()
{
}

BOOL CBrowseeView::PreCreateWindow(CREATESTRUCT& cs)
{
	// TODO: Modify the Window class or styles here by modifying
	//  the CREATESTRUCT cs

	return CHtmlView::PreCreateWindow(cs);
}

/////////////////////////////////////////////////////////////////////////////
// CBrowseeView drawing

void CBrowseeView::OnDraw(CDC* pDC)
{
	CBrowseeDoc* pDoc = GetDocument();
	ASSERT_VALID(pDoc);
	// TODO: add draw code for native data here
	pDC->SetMapMode(MM_ISOTROPIC);
	pDC->SetWindowExt(2000, 2000);
}

void CBrowseeView::OnInitialUpdate()
{
	CHtmlView::OnInitialUpdate();

	// TODO: This code navigates to a popular spot on the web.
	//  change the code to go where you'd like.
	Navigate2(_T("http://www.yahoo.com"),NULL,NULL);
}

/////////////////////////////////////////////////////////////////////////////
// CBrowseeView printing


/////////////////////////////////////////////////////////////////////////////
// CBrowseeView diagnostics

#ifdef _DEBUG
void CBrowseeView::AssertValid() const
{
	CHtmlView::AssertValid();
}

void CBrowseeView::Dump(CDumpContext& dc) const
{
	CHtmlView::Dump(dc);
}

CBrowseeDoc* CBrowseeView::GetDocument() // non-debug version is inline
{
	ASSERT(m_pDocument->IsKindOf(RUNTIME_CLASS(CBrowseeDoc)));
	return (CBrowseeDoc*)m_pDocument;
}
#endif //_DEBUG

/////////////////////////////////////////////////////////////////////////////
// CBrowseeView message handlers
