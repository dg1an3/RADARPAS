// refitemd.cpp : implementation file
//

#include "stdafx.h"
#include "refmap.h"
#include "refitemd.h"

#ifdef _DEBUG
#undef THIS_FILE
static char BASED_CODE THIS_FILE[] = __FILE__;
#endif

/////////////////////////////////////////////////////////////////////////////
// CRefItemDlg dialog

CRefItemDlg::CRefItemDlg(CWnd* pParent /*=NULL*/)
	: CDialog(CRefItemDlg::IDD, pParent)
{
	//{{AFX_DATA_INIT(CRefItemDlg)
	m_authors = "";
	m_institution = "";
	m_source = "";
	m_title = "";
	m_id = "";
	m_MeSH = "";
	m_abstract = "";
	//}}AFX_DATA_INIT
}

void CRefItemDlg::DoDataExchange(CDataExchange* pDX)
{
	CDialog::DoDataExchange(pDX);
	//{{AFX_DATA_MAP(CRefItemDlg)
	DDX_Text(pDX, IDC_AUTHORS, m_authors);
	DDX_Text(pDX, IDC_INSTITUTION, m_institution);
	DDX_Text(pDX, IDC_SOURCE, m_source);
	DDX_Text(pDX, IDC_TITLE, m_title);
	DDX_Text(pDX, IDC_UNIQUE_ID, m_id);
	DDX_Text(pDX, IDC_MeSH, m_MeSH);
	DDX_Text(pDX, IDC_ABSTRACT, m_abstract);
	//}}AFX_DATA_MAP
}

BEGIN_MESSAGE_MAP(CRefItemDlg, CDialog)
	//{{AFX_MSG_MAP(CRefItemDlg)
	//}}AFX_MSG_MAP
END_MESSAGE_MAP()

/////////////////////////////////////////////////////////////////////////////
// CRefItemDlg message handlers
