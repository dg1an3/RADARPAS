// browseeDoc.cpp : implementation of the CBrowseeDoc class
//

#include "stdafx.h"
#include "browsee.h"

#include "browseeDoc.h"

#ifdef _DEBUG
#define new DEBUG_NEW
#undef THIS_FILE
static char THIS_FILE[] = __FILE__;
#endif

/////////////////////////////////////////////////////////////////////////////
// CBrowseeDoc

IMPLEMENT_DYNCREATE(CBrowseeDoc, CDocument)

BEGIN_MESSAGE_MAP(CBrowseeDoc, CDocument)
	//{{AFX_MSG_MAP(CBrowseeDoc)
		// NOTE - the ClassWizard will add and remove mapping macros here.
		//    DO NOT EDIT what you see in these blocks of generated code!
	//}}AFX_MSG_MAP
END_MESSAGE_MAP()

/////////////////////////////////////////////////////////////////////////////
// CBrowseeDoc construction/destruction

CBrowseeDoc::CBrowseeDoc()
{
	// TODO: add one-time construction code here

}

CBrowseeDoc::~CBrowseeDoc()
{
}

BOOL CBrowseeDoc::OnNewDocument()
{
	if (!CDocument::OnNewDocument())
		return FALSE;

	// TODO: add reinitialization code here
	// (SDI documents will reuse this document)

	return TRUE;
}



/////////////////////////////////////////////////////////////////////////////
// CBrowseeDoc serialization

void CBrowseeDoc::Serialize(CArchive& ar)
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
// CBrowseeDoc diagnostics

#ifdef _DEBUG
void CBrowseeDoc::AssertValid() const
{
	CDocument::AssertValid();
}

void CBrowseeDoc::Dump(CDumpContext& dc) const
{
	CDocument::Dump(dc);
}
#endif //_DEBUG

/////////////////////////////////////////////////////////////////////////////
// CBrowseeDoc commands
