// sbmdoc.cpp : implementation of the CSbmDoc class
//

#include "stdafx.h"
#include "sbm.h"

#include "sbmdoc.h"

#ifdef _DEBUG
#undef THIS_FILE
static char BASED_CODE THIS_FILE[] = __FILE__;
#endif

/////////////////////////////////////////////////////////////////////////////
// CSbmDoc

IMPLEMENT_DYNCREATE(CSbmDoc, CDocument)

BEGIN_MESSAGE_MAP(CSbmDoc, CDocument)
	//{{AFX_MSG_MAP(CSbmDoc)
	ON_COMMAND(ID_FUEL_NEWTOTALIZERREADINGS, OnFuelNewtotalizerreadings)
	//}}AFX_MSG_MAP
END_MESSAGE_MAP()

/////////////////////////////////////////////////////////////////////////////
// CSbmDoc construction/destruction

CSbmDoc::CSbmDoc()
{
	// TODO: add one-time construction code here
}

CSbmDoc::~CSbmDoc()
{
}

BOOL CSbmDoc::OnNewDocument()
{
	if (!CDocument::OnNewDocument())
		return FALSE;
	// TODO: add reinitialization code here
	// (SDI documents will reuse this document)
	AxAcct *testAcct = new AxAcct(111, "Checking");
	acct.AddTail(testAcct);
	testAcct = new AxAcct(112, "Cash");
	acct.AddTail(testAcct);
	testAcct = new AxAcct(211, "Office equipment");
	acct.AddTail(testAcct);
	testAcct = new AxAcct(311, "Misc Receivables");
	acct.AddTail(testAcct);
	testAcct = new AxAcct(411, "Salary - DGL");
	acct.AddTail(testAcct);
	testAcct = new AxAcct(421, "Office Rent");
	acct.AddTail(testAcct);
	testAcct = new AxAcct(422, "Office Equipment Depreciation");
	acct.AddTail(testAcct);
	testAcct = new AxAcct(423, "Office Supplies");
	acct.AddTail(testAcct);
	testAcct = new AxAcct(431, "Telephone");
	acct.AddTail(testAcct);
	testAcct = new AxAcct(432, "Electricity");
	acct.AddTail(testAcct);
	testAcct = new AxAcct(441, "Misc Expenses");
	acct.AddTail(testAcct);
	testAcct = new AxAcct(511, "Equity - DGL");
	acct.AddTail(testAcct);
	return TRUE;
}

/////////////////////////////////////////////////////////////////////////////
// CSbmDoc serialization

void CSbmDoc::Serialize(CArchive& ar)
{
	if (ar.IsStoring())
	{
		// TODO: add storing code here
	}
	else
	{
		// TODO: add loading code here
	}
}


/////////////////////////////////////////////////////////////////////////////
// CSbmDoc diagnostics

#ifdef _DEBUG
void CSbmDoc::AssertValid() const
{
	CDocument::AssertValid();
}

void CSbmDoc::Dump(CDumpContext& dc) const
{
	CDocument::Dump(dc);
}

#endif //_DEBUG

/////////////////////////////////////////////////////////////////////////////
// CSbmDoc commands

void CSbmDoc::OnFuelNewtotalizerreadings() {
	TRForm newForm();
	newForm->
}
