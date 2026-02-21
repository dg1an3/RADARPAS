// wlObject.cpp  Copyright (C) 1996, 97  DG Lane

#include "stdafx.h"
#include <math.h>

#include "wlObject.h"

#ifdef _DEBUG
#undef THIS_FILE
static char BASED_CODE THIS_FILE[] = __FILE__;
#endif

wlObjectLink::wlObjectLink()
	{
		myTarget = NULL;
		myWeight = 0.0;
	}
	 
wlObjectLink::wlObjectLink(wlObject *to, float weight) 
	{
		myTarget = to;
		myWeight = weight;
	}

void 
wlObjectLink::operator=(const wlObjectLink &other) 
	{
		myTarget = other.myTarget;
		myWeight = other.myWeight;
	}

IMPLEMENT_SERIAL(wlObjectLink, CObject, 0)

void 
wlObjectLink::Serialize(CArchive& ar) 
	{
		if (ar.IsStoring()) 
			{
				ar << myWeight;
			}
		else 
			{
				ar >> myWeight;
				myTarget = (wlObject *)NULL;
			}
	}

////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////

wlObject::wlObject()
	{
	}

BOOL wlObject::OnNewDocument() 
	{
		if (!CDocument::OnNewDocument())
				return FALSE;
		return TRUE;
	}

void 
wlObject::addLink(wlObjectLink *newLink)
	{
		myLinks.SetAt((void *)newLink->getTarget(), (void *)newLink);
		// TODO: fix this memory leak
	}

POSITION 
wlObject::getLinkStartPos()
	{
		return myLinks.GetStartPosition();
	}

wlObjectLink *
wlObject::getNextLink(POSITION &pos)
	{  
		if (pos)
			{
				wlObjectLink *nextLink = (wlObjectLink *)NULL;
				wlObject *target = (wlObject *)NULL;
				myLinks.GetNextAssoc(pos, (void *&)target, (void *&)nextLink);
				return nextLink;
			}
		else
			return (wlObjectLink *)NULL;
	}

wlObjectLink *wlObject::getLinkByTarget(wlObject *to)
	{
		wlObjectLink *link = (wlObjectLink *)NULL;
		if ( myLinks.Lookup((void *)to, (void *&)link) )
				return link;
		else
				return (wlObjectLink *)NULL;
	}

BOOL
wlObject::delLink(wlObject *toObject)
	{
		return myLinks.RemoveKey((void *)toObject);
	}

wlObject::~wlObject()
	{
		for (POSITION pos = myLinks.GetStartPosition(); pos != NULL;)
			{
				wlObject *object;
				wlObjectLink *link;
				myLinks.GetNextAssoc(pos, (void *&)object, (void *&)link);
				delete link;
			}
		myLinks.RemoveAll();
	}
	
IMPLEMENT_SERIAL(wlObject, CDocument, 0 /* schema number*/ )

void 
wlObject::Serialize(CArchive& ar) 
	{
		myLinks.Serialize(ar);
	}

void 
wlObject::getAspectHint(long area, CRect *aspectRect) 
	{
		int edgeLength = (int) sqrt( (double)area );
		*aspectRect = CRect( 0, 0, edgeLength, edgeLength );
	}

BOOL 
wlObject::Draw(CDC* pDC, LPCRECT lpBounds, int *nextScaleHint) 
	{
		*nextScaleHint = 0;
		return TRUE;
	}

BEGIN_MESSAGE_MAP(wlObject, CDocument)
		//{{AFX_MSG_MAP(wlObject)
				// NOTE - the ClassWizard will add and remove mapping macros here.
		//}}AFX_MSG_MAP
END_MESSAGE_MAP()
