// refmadoc.cpp : implementation of the CRefmapDoc class
//

#include "stdafx.h"
#include "refmap.h"
#include <math.h>

#include "refitem.h"
#include "refmadoc.h"
#include "refitemd.h"

#ifdef _DEBUG
#undef THIS_FILE
static char BASED_CODE THIS_FILE[] = __FILE__;
#endif

/////////////////////////////////////////////////////////////////////////////
// CRefmapDoc

IMPLEMENT_DYNCREATE(CRefmapDoc, CDocument)

BEGIN_MESSAGE_MAP(CRefmapDoc, CDocument)
	//{{AFX_MSG_MAP(CRefmapDoc)
	ON_COMMAND(ID_REF_ADD, OnRefAdd)
	ON_COMMAND(ID_REF_SORT, OnRefSort)
	ON_COMMAND(ID_FILE_IMPORT_CIT, OnFileImportCit)
	ON_COMMAND(ID_FILE_IMPORT_HTML, OnFileImportHtml)
	//}}AFX_MSG_MAP
END_MESSAGE_MAP()

/////////////////////////////////////////////////////////////////////////////
// CRefmapDoc construction/destruction

CRefmapDoc::CRefmapDoc()
{
	// TODO: add one-time construction code here
}

CRefmapDoc::~CRefmapDoc()
{
}

BOOL CRefmapDoc::OnNewDocument()
{
	if (!CDocument::OnNewDocument())
		return FALSE;
	// TODO: add reinitialization code here
	// (SDI documents will reuse this document) 
	
#ifdef _DEBUG
	// if debug, create several references
	//CRefItem* newRef = new CRefItem();
	//ASSERT(newRef != NULL);
	//newRef->id = "012345678";
	//newRef->authors = "DG Lane";
	//newRef->institution = "Washington University, St. Louis";
	//newRef->title = "The cause of all problems";
	//newRef->source = "The Journal of Something";
	
	//ref.Add(newRef);
#endif

	return TRUE;
}

/////////////////////////////////////////////////////////////////////////////
// CRefmapDoc serialization

void CRefmapDoc::Serialize(CArchive& ar)
{   

	// if (ar.IsStoring())
	// {          
	ref.Serialize(ar);
		// ar << ref.GetSize();
		// for (int count = 0; count < ref.GetSize(); count++)
			// ar << ref.GetAt(count);
	//}
	//else
	//{     
	//	ref.Serialize(ar);
		// int size;
		// ar >> size;
		// for (int count = 0; count < size; count++)
		//	ar >> ref.GetAt(count);
		//ar >> ref;
	//}
}

/////////////////////////////////////////////////////////////////////////////
// CRefmapDoc diagnostics

#ifdef _DEBUG
void CRefmapDoc::AssertValid() const
{
	CDocument::AssertValid();
}

void CRefmapDoc::Dump(CDumpContext& dc) const
{
	CDocument::Dump(dc);
}

#endif //_DEBUG

/////////////////////////////////////////////////////////////////////////////
// CRefmapDoc commands

void CRefmapDoc::OnRefAdd()
{
	CRefItemDlg dlg;
	if (dlg.DoModal() == IDOK)
	{
		CRefItem* newRef = new CRefItem;
		ASSERT(newRef != NULL);
		newRef->rect.left = 10;
		newRef->rect.right = 400;
		newRef->rect.top = 5+GetNumRef()*27;
		newRef->rect.bottom = newRef->rect.top+26;
		newRef->id = dlg.m_id;
		newRef->authors = dlg.m_authors;
		newRef->institution = dlg.m_institution;
		newRef->title = dlg.m_title;
		newRef->source = dlg.m_source;
		newRef->MeSH = dlg.m_MeSH;
		newRef->abstract = dlg.m_abstract;
		ref.Add(newRef);
		UpdateAllViews(NULL);
	}	// if
}

void CRefmapDoc::OnFileImportCit()
{   
	CString mask = "*.*";
	CFileDialog fileDlg(TRUE, NULL, mask);	
	if (fileDlg.DoModal() != IDOK)
		return;
	CStdioFile importFile(fileDlg.GetPathName(), 
		CFile::modeRead | CFile::typeText);
	CRefItem* newRef = new CRefItem();
	ASSERT(newRef != NULL);
	int nextTop = 2;
	CDC *pInfoDC = new CDC();
	CFont *itemFont;
	CFont *oldFont;
	TEXTMETRIC txMet;
	pInfoDC->CreateIC("DISPLAY", NULL, NULL, NULL);
	char fieldName[100];
	char value[100];
	importFile.ReadString(fieldName, 100);
	while (importFile.GetPosition() < importFile.GetLength())
	{
		importFile.ReadString(value, 100);
		while ((value[0] == ' ') && (value[1] == ' '))
		{	// accumulate the value
			strcpy(value, &value[2]);	// remove leading spaces 
			value[strlen(value)-1] = ' ';	// remove trailing cr
			if (strcmp(fieldName, "Abstract\n") == 0)
				newRef->abstract += value;
			else if (strcmp(fieldName, "MeSH Subject Headings\n") == 0)
			{
				newRef->MeSH += value;
				newRef->MeSH += "\r\n";
			}
			else if (strcmp(fieldName, "Unique Identifier\n") == 0)
			{
				if (newRef->id != "")
				{	// calculate position and size of item
					newRef->fontSize = (ref.GetSize()<25) ? (ref.GetSize()+4) : 25; // +rand()/(RAND_MAX/10); 
					itemFont = new CFont();
					itemFont->CreateFont(newRef->fontSize, newRef->fontSize*2/5, 
					    0, 0, FW_DONTCARE,
						FALSE, FALSE, FALSE,
						DEFAULT_CHARSET, OUT_TT_PRECIS,
						CLIP_CHARACTER_PRECIS,
						DRAFT_QUALITY, VARIABLE_PITCH | FF_ROMAN | TMPF_TRUETYPE,
						NULL);
					oldFont = pInfoDC->SelectObject(itemFont);
					pInfoDC->GetTextMetrics(&txMet);
					CSize textSize = pInfoDC->GetTextExtent(newRef->title, 
						newRef->title.GetLength());
					pInfoDC->SelectObject(oldFont);

					UINT width = textSize.cx;
				    newRef->rect.top = nextTop;
				    newRef->rect.bottom = nextTop + 3*txMet.tmHeight;
				    	// 14*newRef->title.GetLength()/20;
				    nextTop = newRef->rect.bottom + 2;
					newRef->rect.left = 320 - width/2;
					newRef->rect.right = 320 + width/2;
					ref.Add(newRef);
					newRef = new CRefItem;
					ASSERT(newRef != NULL);
					delete itemFont;
				}	// if
				newRef->id += value;
			}	// if
			else if (strcmp(fieldName, "Authors\n") == 0)
				newRef->authors += value;
			else if (strcmp(fieldName, "Institution\n") == 0)
				newRef->institution += value;
			else if (strcmp(fieldName, "Title\n") == 0)
				newRef->title += value;
			else if (strcmp(fieldName, "Source\n") == 0)
				newRef->source += value;
			else if (strcmp(fieldName, "Registry Numbers\n") == 0)  
			{
				newRef->reg_num += value;
				newRef->reg_num += "\r\n";
			}
			importFile.ReadString(value, 100);
		}	// while
		strcpy(fieldName, value);
	}	// while
	if (newRef->id != "")
	{
		newRef->fontSize = 10; // +rand()/(RAND_MAX/10);
		itemFont = new CFont();
		itemFont->CreateFont(12, 0, 0, 0, FW_DONTCARE,
			FALSE, FALSE, FALSE,
			DEFAULT_CHARSET, OUT_DEVICE_PRECIS,
			CLIP_CHARACTER_PRECIS,
			DEFAULT_QUALITY, VARIABLE_PITCH | FF_ROMAN,
			NULL);
		oldFont = pInfoDC->SelectObject(itemFont);
		pInfoDC->GetTextMetrics(&txMet);
		CSize textSize = pInfoDC->GetTextExtent(newRef->title, 
			newRef->title.GetLength());
		pInfoDC->SelectObject(oldFont);

		UINT width = textSize.cx;
	    newRef->rect.top = nextTop;
	    newRef->rect.bottom = nextTop + 3*txMet.tmHeight;
	    	// 14*newRef->title.GetLength()/20;
	    nextTop = newRef->rect.bottom + 2;
		newRef->rect.left = 320 - width/2;
        newRef->rect.right = 320 + width/2;
		ref.Add(newRef);
		delete itemFont;
	}	// if
	importFile.Close(); 
	UpdateAllViews(NULL);
}

void CRefmapDoc::OnRefSort()
{
	int count, count2;
	
	double avgCorr = 0.0;
	for (count = 0; count < GetNumRef()-1; count++)
		avgCorr += getRef(count)->corr(getRef(count+1));
	avgCorr /= (double)GetNumRef();
	
	for (count = 0; count < GetNumRef(); count++)
	{
		int maxCorrPos = count;
		double maxCorr = 0.0;
		if (count > 0)
			maxCorr += getRef(count)->corr(getRef(count-1));
		if (count < GetNumRef()-1)
			maxCorr += getRef(count)->corr(getRef(count+1));
		for (count2 = 1; count2 < GetNumRef()-1; count2++)
		{
			if ((count != count2+1) && (count != count2))
			{
				double tempCorr = getRef(count)->corr(getRef(count2)) +
					getRef(count)->corr(getRef(count2+1));
				if (tempCorr > maxCorr)
				{
					maxCorr = tempCorr;
					maxCorrPos = count2+1;
				}	// if
			}	// if
		}	// for
		CRefItem *temp = getRef(count);
		DelRef(count);
		ref.InsertAt(maxCorrPos, temp);
		if (count < maxCorrPos)
			count--;
	}	// for
	
	double newAvgCorr = 0.0;
	for (count = 0; count < GetNumRef()-1; count++)
		newAvgCorr += getRef(count)->corr(getRef(count+1));
	newAvgCorr /= (double)GetNumRef();
	
	char resultMsg[100];
	sprintf(resultMsg, "Avg Corr Before: %lf  After %lf", 
		avgCorr, newAvgCorr);
	AfxMessageBox(resultMsg);
	UpdateAllViews(NULL);
}	// CRefmapDoc::OnRefSort



void CRefmapDoc::OnFileImportHtml()
{
	CString mask = "*.htm";
	CFileDialog fileDlg(TRUE, NULL, mask);	
	CDC *pInfoDC = new CDC();
	CFont *itemFont;
	CFont *oldFont;
	TEXTMETRIC txMet;
	int nextTop = 10;
	if (fileDlg.DoModal() != IDOK)
		return;
	CRefItem *newRef = new CRefItem();
	newRef->fileName = fileDlg.GetPathName();
	newRef->title = newRef->fileName;
	// CStdioFile importFile(newRef->fileName, 
	//	CFile::modeRead | CFile::typeText); 
	
	// scan for <TITLE> field
	// set fields
	newRef->fontSize = 10; // +rand()/(RAND_MAX/10);
	itemFont = new CFont();
	itemFont->CreateFont(12, 0, 0, 0, FW_DONTCARE,
		FALSE, FALSE, FALSE,
		DEFAULT_CHARSET, OUT_DEVICE_PRECIS,
		CLIP_CHARACTER_PRECIS,
		DEFAULT_QUALITY, VARIABLE_PITCH | FF_ROMAN,
		NULL); 
	ASSERT(itemFont != NULL);
	pInfoDC->CreateIC("DISPLAY", NULL, NULL, NULL);
	oldFont = pInfoDC->SelectObject(itemFont);
	pInfoDC->GetTextMetrics(&txMet);
	CSize textSize = pInfoDC->GetTextExtent(newRef->title, 
		newRef->title.GetLength());
	pInfoDC->SelectObject(oldFont);

	UINT width = textSize.cx;
	newRef->rect.top = nextTop;
	newRef->rect.bottom = nextTop + 3*txMet.tmHeight;
	    	// 14*newRef->title.GetLength()/20;
	nextTop = newRef->rect.bottom + 2;
	newRef->rect.left = 320 - width/2;
    newRef->rect.right = 320 + width/2;
	ref.Add(newRef);
	delete itemFont;
	
	// importFile.Close();
	UpdateAllViews(NULL);
}
