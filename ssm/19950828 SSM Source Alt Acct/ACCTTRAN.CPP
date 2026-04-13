// accttran.cpp : implementation of the CAcctTrans class
//

#include "stdafx.h"
#include "acct.h"

#include "accttran.h"

#ifdef _DEBUG
#undef THIS_FILE
static char BASED_CODE THIS_FILE[] = __FILE__;
#endif

/////////////////////////////////////////////////////////////////////////////
// CAcctTrans

IMPLEMENT_DYNCREATE(CAcctTrans, CObject)

/////////////////////////////////////////////////////////////////////////////
// CAcctTrans construction/destruction

CAcctTrans::CAcctTrans()
{
	// TODO: add one-time construction code here
}

CAcctTrans::~CAcctTrans()
{
}

// BOOL CAcctTrans::OnNewDocument()
// {
// 	if (!CDocument::OnNewDocument())
// 		return FALSE;
	// TODO: add reinitialization code here
	// (SDI documents will reuse this document)
//	return TRUE;
//}

/////////////////////////////////////////////////////////////////////////////
// CAcctTrans serialization

void CAcctTrans::Serialize(CArchive& ar)
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
// CAcctTrans diagnostics

#ifdef _DEBUG
void CAcctTrans::AssertValid() const
{
	CObject::AssertValid();
}

void CAcctTrans::Dump(CDumpContext& dc) const
{
	CObject::Dump(dc);
}

#endif //_DEBUG

/////////////////////////////////////////////////////////////////////////////
// CAcctTrans commands

/* void CAcctTrans::OnFileImport()
{
	CFileDialog getFileDialog(TRUE, "QIF", NULL, 
	    OFN_HIDEREADONLY | OFN_OVERWRITEPROMPT, "*.QIF");
	if (getFileDialog.DoModal() == IDOK)
	{	// import the specified file

		CStdioFile importFile(getFileDialog.GetPathName(),
			CFile::modeRead | CFile::typeText);

		importFile.ReadString(acctType, sizeof(acctType));

		while (importFile.GetPosition() < importFile.GetLength())
		{
			importFile.ReadString(name, sizeof(name));
		}	// elihw

		importFile.Close();
	}	// fi
}	// CAcctTrans::OnFileImport */
