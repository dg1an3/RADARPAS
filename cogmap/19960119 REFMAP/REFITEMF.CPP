// refitemf.cpp : implementation file
//

#include "stdafx.h"
#include "refmap.h"
#include "refitemf.h"

#ifdef _DEBUG
#undef THIS_FILE
static char BASED_CODE THIS_FILE[] = __FILE__;
#endif

/////////////////////////////////////////////////////////////////////////////
// CRefItemForm

IMPLEMENT_DYNCREATE(CRefItemForm, CFormView)

CRefItemForm::CRefItemForm()
	: CFormView(CRefItemForm::IDD)
{
	//{{AFX_DATA_INIT(CRefItemForm)
	m_authors = "";
	m_institution = "";
	m_source = "";
	m_title = "";
	m_id = "";
	//}}AFX_DATA_INIT
}

CRefItemForm::~CRefItemForm()
{
}

void CRefItemForm::DoDataExchange(CDataExchange* pDX)
{
	CFormView::DoDataExchange(pDX);
	//{{AFX_DATA_MAP(CRefItemForm)
	DDX_Text(pDX, IDC_AUTHORS, m_authors);
	DDX_Text(pDX, IDC_INSTITUTION, m_institution);
	DDX_Text(pDX, IDC_SOURCE, m_source);
	DDX_Text(pDX, IDC_TITLE, m_title);
	DDX_Text(pDX, IDC_UNIQUE_ID, m_id);
	//}}AFX_DATA_MAP
}


BEGIN_MESSAGE_MAP(CRefItemForm, CFormView)
	//{{AFX_MSG_MAP(CRefItemForm)
		// NOTE - the ClassWizard will add and remove mapping macros here.
	//}}AFX_MSG_MAP
END_MESSAGE_MAP()

/////////////////////////////////////////////////////////////////////////////
// CRefItemForm message handlers

