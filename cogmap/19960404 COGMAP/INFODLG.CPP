// infodlg.cpp : implementation file
//

#include "stdafx.h"
#include "cogmap.h"
#include "mapdoc.h"
#include "infodlg.h"

#ifdef _DEBUG
#undef THIS_FILE
static char BASED_CODE THIS_FILE[] = __FILE__;
#endif

/////////////////////////////////////////////////////////////////////////////
// InfoDlg dialog

InfoDlg::InfoDlg(MapDoc *forDoc, CWnd* pParent /*=NULL*/)
	: CDialog(InfoDlg::IDD, pParent) {
	//{{AFX_DATA_INIT(InfoDlg)
	m_ItemNum = 0;
	m_RespNum = 0;
	//}}AFX_DATA_INIT
	pDoc = forDoc;
	m_ItemNum = pDoc->m_docItemList.GetCount();
	m_RespNum = pDoc->srList.GetSize();
	
}

void InfoDlg::DoDataExchange(CDataExchange* pDX) {
	CDialog::DoDataExchange(pDX);
	//{{AFX_DATA_MAP(InfoDlg)
	DDX_Text(pDX, IDC_ITEM_NUM, m_ItemNum);
	DDX_Text(pDX, IDC_RESP_NUM, m_RespNum);
	//}}AFX_DATA_MAP
}

BEGIN_MESSAGE_MAP(InfoDlg, CDialog)
	//{{AFX_MSG_MAP(InfoDlg)
	//}}AFX_MSG_MAP
END_MESSAGE_MAP()

/////////////////////////////////////////////////////////////////////////////
// InfoDlg message handlers

BOOL InfoDlg::OnInitDialog() {
	CDialog::OnInitDialog();
	
	m_ItemNum = pDoc->m_docItemList.GetCount();
	m_RespNum = pDoc->srList.GetSize();
	
	return TRUE;  // return TRUE  unless you set the focus to a control
}
