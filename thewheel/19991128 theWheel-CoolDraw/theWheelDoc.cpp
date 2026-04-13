// theWheelDoc.cpp : implementation of the theWheelDoc class
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
// theWheelDoc

IMPLEMENT_DYNCREATE(theWheelDoc, CDocument)

BEGIN_MESSAGE_MAP(theWheelDoc, CDocument)
	//{{AFX_MSG_MAP(theWheelDoc)
		// NOTE - the ClassWizard will add and remove mapping macros here.
		//    DO NOT EDIT what you see in these blocks of generated code!
	//}}AFX_MSG_MAP
END_MESSAGE_MAP()

/////////////////////////////////////////////////////////////////////////////
// theWheelDoc construction/destruction

theWheelDoc::theWheelDoc()
{
	// TODO: add one-time construction code here

}

theWheelDoc::~theWheelDoc()
{
}

BOOL theWheelDoc::OnNewDocument()
{
	if (!CDocument::OnNewDocument())
		return FALSE;

	// TODO: add reinitialization code here
	// (SDI documents will reuse this document)

	return TRUE;
}



/////////////////////////////////////////////////////////////////////////////
// theWheelDoc serialization

void theWheelDoc::Serialize(CArchive& ar)
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
// theWheelDoc diagnostics

#ifdef _DEBUG
void theWheelDoc::AssertValid() const
{
	CDocument::AssertValid();
}

void theWheelDoc::Dump(CDumpContext& dc) const
{
	CDocument::Dump(dc);
}
#endif //_DEBUG

/////////////////////////////////////////////////////////////////////////////
// theWheelDoc commands
