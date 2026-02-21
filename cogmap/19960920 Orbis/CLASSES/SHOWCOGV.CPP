// showcogv.cpp : implementation file
//

#include "stdafx.h"
#include "cogmap.h"
#include "cogmadoc.h"
#include "showcogv.h"

#ifdef _DEBUG
#undef THIS_FILE
static char BASED_CODE THIS_FILE[] = __FILE__;
#endif

/////////////////////////////////////////////////////////////////////////////
// CShowCogView

IMPLEMENT_DYNCREATE(CShowCogView, CFormView)

CShowCogView::CShowCogView()
	: CFormView(CShowCogView::IDD)
{
	//{{AFX_DATA_INIT(CShowCogView)
		// NOTE: the ClassWizard will add member initialization here
	//}}AFX_DATA_INIT
}

CShowCogView::~CShowCogView()
{
}

void CShowCogView::DoDataExchange(CDataExchange* pDX)
{
	CFormView::DoDataExchange(pDX);
	//{{AFX_DATA_MAP(CShowCogView)
	DDX_Control(pDX, IDC_WORD_LIST, m_WordList);
	DDX_Control(pDX, IDC_RESP_LIST, m_RespList);
	//}}AFX_DATA_MAP
}	// CShowCogView::DoDataExchange


BEGIN_MESSAGE_MAP(CShowCogView, CFormView)
	//{{AFX_MSG_MAP(CShowCogView)
		// NOTE - the ClassWizard will add and remove mapping macros here.
	//}}AFX_MSG_MAP
END_MESSAGE_MAP()

/////////////////////////////////////////////////////////////////////////////
// CShowCogView message handlers

void CShowCogView::OnUpdate(CView *pSender, LPARAM lHint, CObject *pHint)
{
	CCogmapDoc *pDoc = (CCogmapDoc *)GetDocument();
	for (int count = 0; count < pDoc->words.GetSize(); count++)
		m_WordList.AddString(pDoc->words.GetAt(count));
	UpdateData(FALSE);	
}	// CShowCogView::OnUpdate
