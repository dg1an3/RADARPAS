// txtritem.cpp : implementation of the TxtrItem class
//

#include "stdafx.h"
#include <math.h>

#include "mapdoc.h"	// included in header file

#ifdef _DEBUG
#undef THIS_FILE
static char BASED_CODE THIS_FILE[] = __FILE__;
#endif
 
/////////////////////////////////////////////////////////////////////////////
// TxtrItem

double Rnd(double minmax) {
	return (double)rand()*minmax/(double)RAND_MAX;
}	// Rnd

#define pi 3.141593
         
IMPLEMENT_DYNAMIC(TxtrItem, MapItem)

TxtrItem::TxtrItem(MapDoc *pDoc) : 
		MapItem(pDoc) {
	kx = Rnd(6.0); ky = Rnd(6.0); phi = Rnd(pi*2); 
	A1 = Rnd(6.0)-3.0; kx1 = Rnd(6.0); ky1 = Rnd(6.0); phi1 = Rnd(pi*2);
	A11 = Rnd(6.0)-3.0; kx11 = Rnd(6.0); ky11 = Rnd(6.0); phi11 = Rnd(pi*2);
	A12 = Rnd(6.0)-3.0; kx12 = Rnd(6.0); ky12 = Rnd(6.0); phi12 = Rnd(pi*2);
	A2 = Rnd(6.0)-3.0; kx2 = Rnd(6.0); ky2 = Rnd(6.0); phi2 = Rnd(pi*2);
	A21 = Rnd(6.0)-3.0; kx21 = Rnd(6.0); ky21 = Rnd(6.0); phi21 = Rnd(pi*2);
	A22 = Rnd(6.0)-3.0; kx22 = Rnd(6.0); ky22 = Rnd(6.0); phi22 = Rnd(pi*2);
	compDC = NULL;
	compBitmap = NULL;
}	// TxtrItem::TxtrItem

TxtrItem::~TxtrItem() {
	if (compDC != NULL) {
		compDC->DeleteDC();
		delete compDC;
		delete compBitmap;
	}	// fi
}	// TxtrItem::~TxtrItem

int TxtrItem::operator!=(TxtrItem& toStim) {	// NEED TO UPDATE FOR NEW STIMULI
	return ((kx != toStim.kx) || (ky != toStim.ky) || (phi != toStim.phi) ||
		(A1 != toStim.A1) || (kx1 != toStim.kx1) || (ky1 != toStim.ky1) || 
			(phi1 != toStim.phi1) ||
		(A2 != toStim.A2) || (kx2 != toStim.kx2) || (ky2 != toStim.ky2) || 
			(phi2 != toStim.phi2));
}	// TxtrItem::operator!=
		
double TxtrItem::Dist(TxtrItem& toStim) {	// NEED TO UPDATE FOR NEW STIMULI
	return 	(sqrt(kx*toStim.kx + ky*toStim.ky + phi*toStim.phi +
		A1*toStim.A1 + kx1*toStim.kx1 + ky1*toStim.ky1 + phi1*toStim.phi1 +
		A2*toStim.A2 + kx2*toStim.kx2 + ky2*toStim.ky2 + phi2*toStim.phi2));
}	// TxtrItem::Dist

void TxtrItem::genBitmap(CDC *pDC) {
	if (compDC != NULL) {
		compDC->DeleteDC();
		delete compDC;
	}	// if
	compDC = new CDC();
	compDC->CreateCompatibleDC(pDC);
	compBitmap = new CBitmap();
	compBitmap->CreateCompatibleBitmap(pDC, 100, 100);
	CBitmap *oldBitmap = compDC->SelectObject(compBitmap);
	for (int atx = 0; atx < 100; atx++)
		for (int aty = 0; aty < 100; aty++) {         
			double x = ((double)atx-50.0)*(pi/50.0);
			double y = ((double)aty-50.0)*(pi/50.0);
			char value = (char)(128.0+
				128.0*exp(-(x*x+y*y)/2.0)*
				cos(kx*x + ky*y + phi +
					A1*cos(kx1*x + ky1*y + phi1 +
						A11*cos(kx11*x + ky11*y + phi11) +
						A12*cos(kx12*x + ky12*y + phi12)) +
					A2*cos(kx2*x + ky2*y + phi2 +
						A21*cos(kx21*x + ky21*y + phi21) +
						A22*cos(kx22*x + ky22*y + phi22))));
			compDC->SetPixel(atx, aty, RGB(value, value, value));
		}	// rof
	// compDC->SelectObject(oldBitmap);
}	// TxtrItem::Gen

BOOL TxtrItem::Draw(CDC* pDC, LPCRECT lpBounds, 
		LPCRECT lpWBound, CDC *pFormatDC) {
	if ((compDC == NULL) || (compBitmap == NULL))
		genBitmap(pDC);
	int scale = 100;
	if (wz > 0.0) 
		scale = (int)(500.0/sqrt(wz));
	pDC->StretchBlt((int)wx,(int)wy,scale,scale,compDC,0,0,100,100,SRCCOPY);
	return TRUE;
}	// TxtrItem::Draw

void TxtrItem::Serialize(CArchive& ar) {
	if (ar.IsStoring()) {
		ar << kx << ky << phi;
		ar << A1 << kx1 << ky1 << phi1;
		ar << A11 << kx11 << ky11 << phi11;
		ar << A12 << kx12 << ky12 << phi12;
		ar << A2 << kx2 << ky2 << phi2;
		ar << A21 << kx21 << ky21 << phi21;
		ar << A22 << kx22 << ky22 << phi22;
	} else {
		ar >> kx >> ky >> phi;
		ar >> A1 >> kx1 >> ky1 >> phi1;
		ar >> A11 >> kx11 >> ky11 >> phi11;
		ar >> A12 >> kx12 >> ky12 >> phi12;
		ar >> A2 >> kx2 >> ky2 >> phi2;
		ar >> A21 >> kx21 >> ky21 >> phi21;
		ar >> A22 >> kx22 >> ky22 >> phi22;
	}	// fi
}	// TxtrItem::Serialize

#ifdef _DEBUG
void TxtrItem::AssertValid() const { }  // TxtrItem::AssertValid
void TxtrItem::Dump(CDumpContext& dc) const { }  // TxtrItem::Dump
#endif //_DEBUG
