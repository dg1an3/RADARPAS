// theWheelDoc.cpp : implementation of the CTheWheelDoc class
//

#include "stdafx.h"
#include "theWheel.h"

#include "theWheelDoc.h"

#ifdef _DEBUG
#define new DEBUG_NEW
#undef THIS_FILE
static char THIS_FILE[] = __FILE__;
#endif

/////////////////////////////////////////////////////////////////////////////
// CTheWheelDoc

IMPLEMENT_DYNCREATE(CTheWheelDoc, CDocument)

BEGIN_MESSAGE_MAP(CTheWheelDoc, CDocument)
	//{{AFX_MSG_MAP(CTheWheelDoc)
		// NOTE - the ClassWizard will add and remove mapping macros here.
		//    DO NOT EDIT what you see in these blocks of generated code!
	//}}AFX_MSG_MAP
END_MESSAGE_MAP()

/////////////////////////////////////////////////////////////////////////////
// CTheWheelDoc construction/destruction

CTheWheelDoc::CTheWheelDoc()
{
	// TODO: add one-time construction code here

}

CTheWheelDoc::~CTheWheelDoc()
{
}

BOOL CTheWheelDoc::OnNewDocument()
{
	if (!CDocument::OnNewDocument())
		return FALSE;

	// TODO: add reinitialization code here
	// (SDI documents will reuse this document)

	return TRUE;
}



/////////////////////////////////////////////////////////////////////////////
// CTheWheelDoc serialization

void CTheWheelDoc::Serialize(CArchive& ar)
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
// CTheWheelDoc diagnostics

#ifdef _DEBUG
void CTheWheelDoc::AssertValid() const
{
	CDocument::AssertValid();
}

void CTheWheelDoc::Dump(CDumpContext& dc) const
{
	CDocument::Dump(dc);
}
#endif //_DEBUG

/////////////////////////////////////////////////////////////////////////////
// CTheWheelDoc commands
