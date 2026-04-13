// wlObject.cpp : implementation file
//

#include "stdafx.h"

#include "thewheel.h"
#include "wlObject.h"

#ifdef _DEBUG
#undef THIS_FILE
static char BASED_CODE THIS_FILE[] = __FILE__;
#endif

char getAt(char *matrix, int girth, int x, int y)
{
	int offset = girth/2;
	if (x < -offset || offset < x || y < -offset || offset < y)
		return 0;
	else
		return matrix[(offset-x) + girth*(offset-y)];
}

void setAt(char **matrix, int *girth, int x, int y, char value)
{
	if (!value)
		return;
		
	int offset = (*girth) / 2;
	while (x < -offset || offset < x || y < -offset || offset < y)
	{
		int newGirth = (*girth) + 2;
		char *newMatrix = new char[newGirth*newGirth];
		for (int atx = -offset; atx <= offset; atx++)
			for (int aty = -offset; aty <= offset; aty++)
				setAt(&newMatrix, &newGirth, atx, aty, getAt((*matrix), (*girth), atx, aty));
		delete [] (*matrix);
		(*matrix) = newMatrix;
		(*girth) = newGirth;
		offset = *girth / 2;
	}
	(*matrix)[(offset-x) + (*girth)*(offset-y)] = value;
}


/////////////////////////////////////////////////////////////////////////////
// wlObject

IMPLEMENT_SERIAL(wlObject, CDocument, 0 /* schema number*/ )

wlObject::wlObject() {
		girth = 1;
		body = new char[girth*girth];
		setAt(&body, &girth, 0, 0, 1);
		rules = new char[10];
		for (int count = 0; count < 10; count++)
				rules[count] = (rand() > RAND_MAX/2);
}

BOOL wlObject::OnNewDocument() {
		if (!CDocument::OnNewDocument())
				return FALSE;
		return TRUE;
}

wlObject::~wlObject() {
		delete [] rules;
		delete [] body;
}

void wlObject::grow() {
		if (rand() > RAND_MAX/girth)
				return;
				
		int newGirth = girth;
		int offset = newGirth/2+1;
		char *newBody = new char[newGirth*newGirth];
		for (int atx = -offset; atx <= offset; atx++)
				for (int aty = -offset; aty <= offset; aty++) {
						int dx, dy;
						int sum = 0;
						for (dx = -1; dx <= 1; dx++)
								for (dy = -1; dy <= 1; dy++)
										sum += (int)getAt(body, girth, atx+dx, aty+dy);
						setAt(&newBody, &newGirth, atx, aty, rules[sum]);
				}
				
		delete [] body;
		body = newBody;
		girth = newGirth;
}

BOOL wlObject::Draw(CDC* pDC, LPCRECT lpBounds, LPCRECT lpWBound, CDC *pFormatDC) {  
		it.Draw(pDC, lpBounds, lpWBound, pFormatDC);
		return FALSE;
	
		CBrush *onBrush = new CBrush(RGB(128, 128, 128));
		CBrush *offBrush = new CBrush(RGB(92, 92, 92));
		CBrush *oldBrush = pDC->SelectObject(onBrush);
	
		int dx = (lpBounds->right - lpBounds->left)/(girth+1);
		int dy = (lpBounds->bottom - lpBounds->top)/(girth+1);
	
		for (int atx = 0; atx < girth; atx++)
				for (int aty = 0; aty < girth; aty++) {
						pDC->SelectObject(body[atx+girth*aty] ? onBrush : offBrush);
						pDC->Ellipse(atx*dx, aty*dy, atx*dx+3*dx/2, aty*dy+3*dy/2);
				}
		
		pDC->SelectObject(oldBrush);
		delete offBrush;
		delete onBrush;
		return TRUE;
}

BEGIN_MESSAGE_MAP(wlObject, CDocument)
		//{{AFX_MSG_MAP(wlObject)
				// NOTE - the ClassWizard will add and remove mapping macros here.
		//}}AFX_MSG_MAP
END_MESSAGE_MAP()

/////////////////////////////////////////////////////////////////////////////
// wlObject serialization

void wlObject::Serialize(CArchive& ar) {
		if (ar.IsStoring()) {
				// TODO: add storing code here
		}
		else {
				// TODO: add loading code here
		}
}
