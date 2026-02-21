// CA2DItem.cpp : implementation of the CA2DItemclass
//

#include "stdafx.h"
#include <math.h>

#include "mapdoc.h"	// included in header file
#include "eevorg2d.h"

#ifdef _DEBUG
#undef THIS_FILE
static char BASED_CODE THIS_FILE[] = __FILE__;
#endif
 
/////////////////////////////////////////////////////////////////////////////
// CA2DItem

/* 
double Rnd(double minmax) {
	return (double)rand()*minmax/(double)RAND_MAX;
}	// Rnd
*/

#define pi 3.141593
         
IMPLEMENT_DYNAMIC(CA2DItem, MapItem)

CA2DItem::CA2DItem(MapDoc *pDoc) : 
		MapItem(pDoc) {
	eev = new Eevorg2d();	// with Mutation?
	compDC = NULL;
	compBitmap = NULL;
}	// CA2DItem::CA2DItem

CA2DItem::CA2DItem(MapDoc *pDoc, CA2DItem *fromParent) : 
		MapItem(pDoc) {
	eev = new Eevorg2d(fromParent->eev, WITH_MUTATION);
	compDC = NULL;
	compBitmap = NULL;
}	// CA2DItem::CA2DItem

CA2DItem::~CA2DItem() {
	if (compDC != NULL) {
		delete eev;
		compDC->DeleteDC();
		delete compDC;
		delete compBitmap;
	}	// fi
}	// CA2DItem::~CA2DItem

int CA2DItem::operator!=(CA2DItem& toStim) {	// NEED TO UPDATE FOR NEW STIMULI
	return 0;
}	// CA2DItem::operator!=
		
double CA2DItem::Dist(CA2DItem& toStim) {	// NEED TO UPDATE FOR NEW STIMULI
	return 0;
}	// CA2DItem::Dist

void CA2DItem::genBitmap(CDC *pDC) {
	if (compDC != NULL) {
		compDC->DeleteDC();
		delete compDC;
	}	// if
	compDC = new CDC();
	compDC->CreateCompatibleDC(pDC);
	compBitmap = new CBitmap();
	compBitmap->CreateCompatibleBitmap(pDC, 100, 100);
	CBitmap *oldBitmap = compDC->SelectObject(compBitmap);
	compDC->SelectStockObject(GRAY_BRUSH);
	compDC->Rectangle(0,0,105,105);
	eev->drawAt(compDC, 50, 0, 100);
}	// CA2DItem::Gen

BOOL CA2DItem::Draw(CDC* pDC, LPCRECT lpBounds, 
		LPCRECT lpWBound, CDC *pFormatDC) {
	if ((compDC == NULL) || (compBitmap == NULL))
		genBitmap(pDC);
	int scale = 100;
	if (wz > 0.0) 
		scale = (int)(500.0/sqrt(wz));
	pDC->StretchBlt((int)wx,(int)wy,scale,scale,compDC,0,0,100,100,SRCCOPY);
	return TRUE;
}	// CA2DItem::Draw

void CA2DItem::Serialize(CArchive& ar) {
	eev->Serialize(ar);
}	// CA2DItem::Serialize

#ifdef _DEBUG
void CA2DItem::AssertValid() const { }  // CA2DItem::AssertValid
void CA2DItem::Dump(CDumpContext& dc) const { }  // CA2DItem::Dump
#endif //_DEBUG
