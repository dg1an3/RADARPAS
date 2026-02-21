// trform.cpp : implementation file
//

#include "stdafx.h"
#include "sbm.h"
#include "trform.h"

#ifdef _DEBUG
#undef THIS_FILE
static char BASED_CODE THIS_FILE[] = __FILE__;
#endif

/////////////////////////////////////////////////////////////////////////////
// TRForm

IMPLEMENT_DYNCREATE(TRForm, CFormView)

TRForm::TRForm()
	: CFormView(TRForm::IDD) {
	//{{AFX_DATA_INIT(TRForm)
	m_Curr10 = 0;
	m_Curr1 = 0;
	m_Curr2 = 0;
	m_Curr3 = 0;
	m_Curr4 = 0;
	m_Curr5 = 0;
	m_Curr6 = 0;
	m_Curr7 = 0;
	m_Curr8 = 0;
	m_Curr9 = 0;
	m_Date = "";
	m_Diff1 = 0;
	m_Diff10 = 0;
	m_Diff2 = 0;
	m_Diff3 = 0;
	m_Diff4 = 0;
	m_Diff5 = 0;
	m_Diff6 = 0;
	m_Diff7 = 0;
	m_Diff8 = 0;
	m_Diff9 = 0;
	m_Prev1 = 0;
	m_Prev10 = 0;
	m_Prev2 = 0;
	m_Prev3 = 0;
	m_Prev4 = 0;
	m_Prev5 = 0;
	m_Prev6 = 0;
	m_Prev7 = 0;
	m_Prev8 = 0;
	m_Prev9 = 0;
	m_Shift = 0;
	m_Time = "";
	//}}AFX_DATA_INIT
}

TRForm::~TRForm() {
}

void TRForm::DoDataExchange(CDataExchange* pDX) {
	CFormView::DoDataExchange(pDX);
	//{{AFX_DATA_MAP(TRForm)
	DDX_Text(pDX, IDC_CURR10, m_Curr10);
	DDV_MinMaxDouble(pDX, m_Curr10, 0., 999999999999.);
	DDX_Text(pDX, IDC_CURR1, m_Curr1);
	DDV_MinMaxDouble(pDX, m_Curr1, 0., 999999999999.);
	DDX_Text(pDX, IDC_CURR2, m_Curr2);
	DDV_MinMaxDouble(pDX, m_Curr2, 0., 999999999999.);
	DDX_Text(pDX, IDC_CURR3, m_Curr3);
	DDV_MinMaxDouble(pDX, m_Curr3, 0., 999999999999.);
	DDX_Text(pDX, IDC_CURR4, m_Curr4);
	DDV_MinMaxDouble(pDX, m_Curr4, 0., 999999999999.);
	DDX_Text(pDX, IDC_CURR5, m_Curr5);
	DDV_MinMaxDouble(pDX, m_Curr5, 0., 999999999999.);
	DDX_Text(pDX, IDC_CURR6, m_Curr6);
	DDV_MinMaxDouble(pDX, m_Curr6, 0., 999999999999.);
	DDX_Text(pDX, IDC_CURR7, m_Curr7);
	DDV_MinMaxDouble(pDX, m_Curr7, 0., 999999999999.);
	DDX_Text(pDX, IDC_CURR8, m_Curr8);
	DDV_MinMaxDouble(pDX, m_Curr8, 0., 999999999999.);
	DDX_Text(pDX, IDC_CURR9, m_Curr9);
	DDV_MinMaxDouble(pDX, m_Curr9, 0., 999999999999.);
	DDX_Text(pDX, IDC_DATE, m_Date);
	DDX_Text(pDX, IDC_DIFF1, m_Diff1);
	DDX_Text(pDX, IDC_DIFF10, m_Diff10);
	DDX_Text(pDX, IDC_DIFF2, m_Diff2);
	DDX_Text(pDX, IDC_DIFF3, m_Diff3);
	DDX_Text(pDX, IDC_DIFF4, m_Diff4);
	DDX_Text(pDX, IDC_DIFF5, m_Diff5);
	DDX_Text(pDX, IDC_DIFF6, m_Diff6);
	DDX_Text(pDX, IDC_DIFF7, m_Diff7);
	DDX_Text(pDX, IDC_DIFF8, m_Diff8);
	DDX_Text(pDX, IDC_DIFF9, m_Diff9);
	DDX_Text(pDX, IDC_PREV1, m_Prev1);
	DDX_Text(pDX, IDC_PREV10, m_Prev10);
	DDX_Text(pDX, IDC_PREV2, m_Prev2);
	DDX_Text(pDX, IDC_PREV3, m_Prev3);
	DDX_Text(pDX, IDC_PREV4, m_Prev4);
	DDX_Text(pDX, IDC_PREV5, m_Prev5);
	DDX_Text(pDX, IDC_PREV6, m_Prev6);
	DDX_Text(pDX, IDC_PREV7, m_Prev7);
	DDX_Text(pDX, IDC_PREV8, m_Prev8);
	DDX_Text(pDX, IDC_PREV9, m_Prev9);
	DDX_Text(pDX, IDC_SHIFT, m_Shift);
	DDV_MinMaxInt(pDX, m_Shift, 0, 9);
	DDX_Text(pDX, IDC_TIME, m_Time);
	//}}AFX_DATA_MAP
}


BEGIN_MESSAGE_MAP(TRForm, CFormView)
	//{{AFX_MSG_MAP(TRForm)
		// NOTE - the ClassWizard will add and remove mapping macros here.
	//}}AFX_MSG_MAP
END_MESSAGE_MAP()

/////////////////////////////////////////////////////////////////////////////
// TRForm message handlers

