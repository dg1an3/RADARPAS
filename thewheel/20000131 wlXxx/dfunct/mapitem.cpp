// mapdoc.cpp : implementation of the MapDoc class
//

#include "stdafx.h"
#include <math.h>
#include <time.h>

#include "mapdoc.h"

#ifdef _DEBUG
#undef THIS_FILE
static char BASED_CODE THIS_FILE[] = __FILE__;
#endif

#define randflt(x) (float(rand())*float(x)/float(RAND_MAX))
#define pi (4*atan(1))

/////////////////////////////////////////////////////////////////////////////
// MapItem class
                    
IMPLEMENT_DYNAMIC(MapItem, CDocItem)

MapItem::MapItem(MapDoc *pDoc) {
    wx = randflt(600); wy = randflt(400); wz = randflt(200)+1.0;
    dwx = 0.0; dwy = 0.0; dwz = 0.0;
    corr = NULL;
    dirty = TRUE;
}	// MapItem::MapItem

MapItem::~MapItem() {
	if (corr != NULL)
		delete [] corr;
	/* m_pDocument->RemoveItem(this); */
}	// MapItem::~MapItem

float MapItem::avgCorr() {
	MapDoc *pDoc = (MapDoc *)GetDocument();
	float avg = 0.0;
	for (int i = 0; i < pDoc->m_docItemList.GetCount(); i++) {
		ASSERT(corr[i] >= 0.0);
		avg += corr[i];
	}	// for
	avg /= (float)(pDoc->m_docItemList.GetCount());
	ASSERT((avg >= 0.0) && (avg <= 1.0));
	return avg;
}	// MapItem::avgCorr

float dGaussdx(float x, float y, float z, float sigma) {
	return (float)exp(-(x*x+y*y+z*z)/(2*sigma)) / (2*(float)pi*sigma*sigma)
	    * -2*x/(2*sigma);
}   // dGaussdx

#define Rsigma 10000.0
// float Rsigmay = 10000.0;
#define Asigma 20000.0
#define kR 1.1e+11
#define kA 7e+11
// 1e+12; // multiplier for energy gradient
#define kEnv 5e+12
// 1e+12;
#define kUsr 1e+13
#define kFric 0.08

void MapItem::dt(int timeslices) {
	MapDoc *pDoc = (MapDoc *)GetDocument();
	float deltat = 1; //= pDoc->t - lastUpdate;
	// ASSERT(deltat >= 0.0);
	// pDoc->totSpeed -= abs(dwx)+abs(dwy)+abs(dwz);
	float ddwx = 0.0, ddwy = 0.0, ddwz = 0.0;
	// for (int sf = 0; sf < deltat; sf++) {
		ddwx += ((float)rand()-(float)RAND_MAX/(float)2.0-(float)0.5)*pDoc->temp;
		ddwy += ((float)rand()-(float)RAND_MAX/(float)2.0-(float)0.5)*pDoc->temp; 
	    ddwz += ((float)rand()-(float)RAND_MAX/(float)2.0-(float)0.5)*pDoc->temp;
	// }	// for
	ddwx -= dwx*kFric;
	ddwy -= dwy*kFric;
	ddwz -= dwz*kFric;
	float SumdRnidxn = 0.0, SumdRnidyn = 0.0, SumdRnidzn = 0.0;
	float SumdAnidxn = 0.0, SumdAnidyn = 0.0, SumdAnidzn = 0.0;
	POSITION pos2 = pDoc->GetStartPosition();
	int i = 0, at = 0;
	while (pos2 != NULL) {
		MapItem *item2 = (MapItem *)pDoc->GetNextItem(pos2);
		if (item2 != this) {
			// ASSERT(corr[i] == item2->corr[n]);
			SumdRnidxn += dGaussdx(wx-item2->wx,wy-item2->wy,wz-item2->wz,Rsigma);
			SumdRnidyn += dGaussdx(wy-item2->wy,wz-item2->wz,wx-item2->wx,Rsigma);	
			SumdRnidzn += dGaussdx(wz-item2->wz,wx-item2->wx,wy-item2->wy,Rsigma);
			SumdAnidxn += corr[i]*dGaussdx(wx-item2->wx,wy-item2->wy,wz-item2->wz,Asigma);
			SumdAnidyn += corr[i]*dGaussdx(wy-item2->wy,wz-item2->wz,wx-item2->wx,Asigma);
			SumdAnidzn += corr[i]*dGaussdx(wz-item2->wz,wx-item2->wx,wy-item2->wy,Asigma);
		} else {
			at = i;
		}   // fi
		i++;
	}	// while
	ddwx += -kR*SumdRnidxn+kA*SumdAnidxn+kEnv*dGaussdx(wx-400,wy-300,wz-200,40000)+
		kUsr*(pDoc->user->corr[at])*dGaussdx(wx-400,wy-300,wz-40,40000);
	ddwy += -kR*SumdRnidyn+kA*SumdAnidyn+kEnv*dGaussdx(wy-300,wz-200,wx-400,40000)+
		kUsr*(pDoc->user->corr[at])*dGaussdx(wy-300,wz-40,wx-400,40000);
	ddwz += -kR*SumdRnidzn+kA*SumdAnidzn+kEnv*dGaussdx(wz-200,wx-400,wy-300,40000)+
		kUsr*(pDoc->user->corr[at])*dGaussdx(wz-40,wx-400,wy-300,40000);
	dwx += ddwx*deltat; 
	dwy += ddwy*deltat; 
	dwz += ddwz*deltat;
	// pDoc->totSpeed += abs(dwx)+abs(dwy)+abs(dwz);
	// if (((int)(wx+dwx) != (int)(wx)) || ((int)(wy+dwy) != (int)(wy)))
	//	dirty = TRUE;
	wx += dwx; // *(float)deltat;
	wy += dwy; // *(float)deltat;
	wz += dwz; // *(float)deltat;
	lastUpdate = pDoc->t;
}	// MapItem::dt

float MapItem::sqrtSpeed() {	// sqrt of the speed of the object
	return sqrt(abs(dwx)+abs(dwy)+abs(dwz)); 
}

void MapItem::Serialize(CArchive& ar) {
	if (ar.IsStoring()) {
		ar << wx << wy << wz;
	    ar << dwx << dwy << dwz;
	} else {
		ar >> wx >> wy >> wz;
	    ar >> dwx >> dwy >> dwz;
	}	// fi
}	// MapItem::Serialize

#ifdef _DEBUG
void MapItem::AssertValid() const { }	// MapItem::AssertValid
void MapItem::Dump(CDumpContext& dc) const { }	// MapItem::Dump
#endif //_DEBUG

