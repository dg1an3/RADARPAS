// acctdoc.cpp : implementation of the CAcctDoc class
//

#include "stdafx.h"
#include "acct.h"
#include "accttran.h"

#include "acctdoc.h"

#ifdef _DEBUG
#undef THIS_FILE
static char BASED_CODE THIS_FILE[] = __FILE__;
#endif

/////////////////////////////////////////////////////////////////////////////
// CAcctDoc

IMPLEMENT_DYNCREATE(CAcctDoc, CDocument)

BEGIN_MESSAGE_MAP(CAcctDoc, CDocument)
	//{{AFX_MSG_MAP(CAcctDoc)
	ON_COMMAND(ID_FILE_IMPORT, OnFileImport)
	//}}AFX_MSG_MAP
END_MESSAGE_MAP()

/////////////////////////////////////////////////////////////////////////////
// CAcctDoc construction/destruction

CAcctDoc::CAcctDoc()
{
	// TODO: add one-time construction code here
}

CAcctDoc::~CAcctDoc()
{
}

BOOL CAcctDoc::OnNewDocument()
{
	if (!CDocument::OnNewDocument())
		return FALSE;
	// TODO: add reinitialization code here
	// (SDI documents will reuse this document)
	return TRUE;
}

/////////////////////////////////////////////////////////////////////////////
// CAcctDoc serialization

void CAcctDoc::Serialize(CArchive& ar)
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
// CAcctDoc diagnostics

#ifdef _DEBUG
void CAcctDoc::AssertValid() const
{
	CDocument::AssertValid();
}

void CAcctDoc::Dump(CDumpContext& dc) const
{
	CDocument::Dump(dc);
}

#endif //_DEBUG

/////////////////////////////////////////////////////////////////////////////
// CAcctDoc commands

void CAcctDoc::OnFileImport()
{
	CFileDialog getFileDialog(TRUE, "QIF", NULL, 
	    OFN_HIDEREADONLY | OFN_OVERWRITEPROMPT, "*.QIF");
	if (getFileDialog.DoModal() == IDOK)
	{	// import the specified file
        
        name = getFileDialog.GetFileName();
        
		CStdioFile importFile(getFileDialog.GetPathName(),
			CFile::modeRead | CFile::typeText);

		importFile.ReadString(acctType.GetBuffer(40), 40);
        acctType.ReleaseBuffer();
        
        while (importFile.GetPosition() < importFile.GetLength())
		{       
			CAcctTrans *newTrans = new CAcctTrans();
			CString s; 
			int day, month, year;
			while (s != "^")
			{
			    importFile.ReadString(s.GetBuffer(255), 255);
			    s.ReleaseBuffer();
			    switch (s[0])
			    {
			    	case 'D' :	// date                          
			    		s = s.Mid(1);
			    		day = atoi(s.Left(s.Find('/')));
			    		s = s.Mid(s.Find('/')+1);
			    		month = atoi(s.Left(s.Find('/')));
			    		s = s.Mid(s.Find('/')+1);
			    		year = atoi(s);
			    		newTrans->date = CTime(year, month, 
			    			day, 0, 0, 0);
			    		break;
			    	
			    	case 'T' :	// amount
			    		newTrans->amt = (float)atof(s.Mid(1));
			    		break;
			    	
			    	case 'C' :	// cleared flag
			    		newTrans->clr = s[1];
			    		break;
			    		
			    	case 'N' :	// transaction type
			    		newTrans->type = s.Mid(1);
			    		newTrans->num = atoi(newTrans->type);
			    		if (newTrans->num != -1)
			    			newTrans->type = "CHK";
			    		break;
			    		
			    	case 'P' :	// payee/desc
			    		newTrans->desc = s.Mid(1);
			    		break;
			    		
			    	case 'M' :	// memo
			    		newTrans->memo = s.Mid(1);
			    		break;
			    		
			    	case 'L' :	// category
			    		newTrans->cat = s.Mid(1);
			    		break;
			    }	// hctiws
			}	// elihw
			trans.Add(newTrans);
		}	// elihw
		importFile.Close();
	}	// fi
}	// CAcctDoc::OnFileImport
