// wlObject.cpp  Copyright (C) 1996, 97  DG Lane

#include "stdafx.h"
#include <math.h>
#include "theWheel.h"
#include "wlObject.h"

#ifdef _DEBUG
#undef THIS_FILE
static char BASED_CODE THIS_FILE[] = __FILE__;
#endif
 
////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////

wlObjectLink::wlObjectLink(wlObject *to, float weight) {
		myTarget = to;
		myWeight = weight;
}

IMPLEMENT_SERIAL(wlObjectLink, CObject, 0)

void wlObjectLink::Serialize(CArchive& ar) {
		if (ar.IsStoring) {
				ar << myWeight;
		}
		else {
				ar >> myWeight;
				myTarget = (wlObject *)NULL;
		}
}

////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////

wlObject::wlObject() {
		numLinks = 0;
		myLink = (wlObjectLink *)NULL;
}

BOOL wlObject::OnNewDocument() {
		if (!CDocument::OnNewDocument())
				return FALSE;
		return TRUE;
}

void wlObject::addLink(wlObject *toObject, float weight) {
		wlObjectLink *newLinks = new wlObjectLink[++numLinks];
		if (myLink) {
				for (int count = 0; count < numLinks-1; count++)
						newLinks[count] = myLink[count];
				delete [] myLink;
		}
		myLink = newLinks;
		myLink[numLinks-1].setTarget(toObject);
		myLink[numLinks-1].setWeight(weight);
}

IMPLEMENT_SERIAL(wlObject, CDocument, 0 /* schema number*/ )

void wlObject::Serialize(CArchive& ar) {
		if (ar.IsStoring())
				ar << (WORD)numLinks;
		else {
				WORD numValue;
				ar >> numValue;
				numLinks = numValue;
		}
		for (int count = 0; count < numLinks; count++)
				myLink[count].Serialize(ar);
}

void wlObject::getAspectHint(long area, CRect *aspectRect) {
		int edgeLength = (int) sqrt( (double)area );
		*aspectRect = CRect( 0, 0, edgeLength, edgeLength );
}

BOOL wlObject::Draw(CDC* pDC, LPCRECT lpBounds, int *nextScaleHint) {
		*nextScaleHint = 0;
		return TRUE;
}

BEGIN_MESSAGE_MAP(wlObject, CDocument)
		//{{AFX_MSG_MAP(wlObject)
				// NOTE - the ClassWizard will add and remove mapping macros here.
		//}}AFX_MSG_MAP
END_MESSAGE_MAP()
