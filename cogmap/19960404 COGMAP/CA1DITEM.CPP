// ca1ditem.cpp : implementation of the CA1DItem class
//

#include "stdafx.h"
#include <math.h>

#include "mapdoc.h"	// included in header file
#include "eevorg.h"

#ifdef _DEBUG
#undef THIS_FILE
static char BASED_CODE THIS_FILE[] = __FILE__;
#endif
 
/////////////////////////////////////////////////////////////////////////////
// CA1DItem

/* 
double Rnd(double minmax) {
	return (double)rand()*minmax/(double)RAND_MAX;
}	// Rnd
*/

#define pi 3.141593
         
IMPLEMENT_DYNAMIC(CA1DItem, MapItem)

CA1DItem::CA1DItem(MapDoc *pDoc) : 
		MapItem(pDoc) {
	eev = new Eevorg();	// with Mutation?
	compDC = NULL;
	compBitmap = NULL;
}	// CA1DItem::CA1DItem

CA1DItem::CA1DItem(MapDoc *pDoc, CA1DItem *fromParent) : 
		MapItem(pDoc) {
	eev = new Eevorg(fromParent->eev, WITH_MUTATION);
	compDC = NULL;
	compBitmap = NULL;
}	// CA1DItem::CA1DItem

CA1DItem::~CA1DItem() {
	if (compDC != NULL) {
		delete eev;
		compDC->DeleteDC();
		delete compDC;
		delete compBitmap;
	}	// fi
}	// CA1DItem::~CA1DItem

int CA1DItem::operator!=(CA1DItem& toStim) {	// NEED TO UPDATE FOR NEW STIMULI
	return 0;
}	// CA1DItem::operator!=
		
double CA1DItem::Dist(CA1DItem& toStim) {	// NEED TO UPDATE FOR NEW STIMULI
	return 0;
}	// CA1DItem::Dist

void CA1DItem::genBitmap(CDC *pDC) {
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
}	// CA1DItem::Gen

BOOL CA1DItem::Draw(CDC* pDC, LPCRECT lpBounds, 
		LPCRECT lpWBound, CDC *pFormatDC) {
	if ((compDC == NULL) || (compBitmap == NULL))
		genBitmap(pDC);
	int scale = 100;
	if (wz > 0.0) 
		scale = (int)(500.0/sqrt(wz));
	pDC->StretchBlt((int)wx,(int)wy,scale,scale,compDC,0,0,100,100,SRCCOPY);
	return TRUE;
}	// CA1DItem::Draw

void CA1DItem::Serialize(CArchive& ar) {
	eev->Serialize(ar);
}	// CA1DItem::Serialize

#ifdef _DEBUG
void CA1DItem::AssertValid() const { }  // CA1DItem::AssertValid
void CA1DItem::Dump(CDumpContext& dc) const { }  // CA1DItem::Dump
#endif //_DEBUG
