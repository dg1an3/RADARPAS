// refitem.cpp : implementation file
//

#include "stdafx.h"
#include "refmap.h"
#include "refitem.h"

#ifdef _DEBUG
#undef THIS_FILE
static char BASED_CODE THIS_FILE[] = __FILE__;
#endif

/////////////////////////////////////////////////////////////////////////////
// CRefItem

IMPLEMENT_SERIAL(CRefItem, CObject, 0 /* schema number*/ ) 

CRefItem::CRefItem()
{
}

CRefItem::~CRefItem()
{
}

double CRefItem::corr(CRefItem *withItem)
{
	double count1 = 1.0;
	double count2 = 1.0;
	double matches = 0.0;
	int i, j;
	CString currMeSH, withMeSH;
	CString currMeSHlist = MeSH;
	while (currMeSHlist.GetLength() > 0)
	{               
		i = currMeSHlist.Find("\r\n");
		currMeSH = currMeSHlist.Left(i);
		currMeSHlist = currMeSHlist.Mid(i+2);
		count1 += 1.0;
		CString withMeSHlist = withItem->MeSH;
		while (withMeSHlist.GetLength() > 0)
		{
			j = withMeSHlist.Find("\r\n");
			withMeSH = withMeSHlist.Left(j);
			withMeSHlist = withMeSHlist.Mid(j+2);
			count2 += 1.0;
			if (withMeSH == currMeSH)
				matches += 1.0;
		}	// while
	}	// while
	return ((matches/count1)+(matches/count2))/2.0;
}   // CRefItem::corr

/////////////////////////////////////////////////////////////////////////////
// CRefItem serialization

void CRefItem::Serialize(CArchive& ar)
{
	if (ar.IsStoring())
	{
		ar << (WORD)rect.left;
		ar << (WORD)rect.top;
		ar << (WORD)rect.right;
		ar << (WORD)rect.bottom;
		ar << (WORD)fontSize;
		ar << id;
		ar << authors;
		ar << institution;
		ar << title;
		ar << source;
		ar << MeSH;
		ar << abstract;
		ar << reg_num;
		ref.Serialize(ar);
	}
	else
	{     
		WORD fuck, you, bill, gates;
		ar >> fuck;  rect.left = fuck;
		ar >> you;  rect.top = you;
		ar >> bill;  rect.right = bill;
		ar >> gates;  rect.bottom = gates;
		ar >> fuck; fontSize = fuck;
		ar >> id;
		ar >> authors;
		ar >> institution;
		ar >> title;
		ar >> source;
		ar >> MeSH;
		ar >> abstract;
		ar >> reg_num;
		ref.Serialize(ar);
	}
}

