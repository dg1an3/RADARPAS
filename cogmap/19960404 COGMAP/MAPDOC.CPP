// mapdoc.cpp : implementation of the MapDoc class
//

#include "stdafx.h"
#include "cogmap.h"
#include <math.h>
#include <time.h>

#include "mapdoc.h"
#include "infodlg.h"

#ifdef _DEBUG
#undef THIS_FILE
static char BASED_CODE THIS_FILE[] = __FILE__;
#endif

#define randflt(x) (float(rand())*float(x)/float(RAND_MAX))
#define pi (4*atan(1))

/////////////////////////////////////////////////////////////////////////////
// MapDoc

IMPLEMENT_DYNCREATE(MapDoc, COleClientDoc)

BEGIN_MESSAGE_MAP(MapDoc, COleClientDoc)
	//{{AFX_MSG_MAP(MapDoc)
	ON_COMMAND(ID_INSERT_TXTR, OnInsertTxtr)
	ON_COMMAND(ID_INSERT_WORD, OnInsertWord)
	ON_COMMAND(ID_INSERT_CA1D, OnInsertCa1d)
	ON_COMMAND(ID_VIEW_INFO, OnViewInfo)
	//}}AFX_MSG_MAP
END_MESSAGE_MAP()

MapDoc::MapDoc() { }   // MapDoc::MapDoc
MapDoc::~MapDoc() { }	// MapDoc::~MapDoc

MapItem *MapDoc::getItemAt(int at) {
	POSITION pos = GetStartPosition();
	MapItem *item = (MapItem *)GetNextItem(pos);
	for (int count = 0; count < at; count++)
		item = (MapItem *)GetNextItem(pos);
	return item;
}	// MapDoc::getItemAt
                         
void MapDoc::dt(int timeSlices) {
	for (int i = 0; i < 3; i++) {
		POSITION pos = GetStartPosition();
		float sel = (float)rand()/(float)RAND_MAX;
		MapItem *item;
		// ASSERT(totSpeed >= 0.0);
		while ((pos != NULL) && (sel > 0)) {
			item = (MapItem *)GetNextItem(pos);
			sel -= 1/(float)(m_docItemList.GetCount());
			// sel -= item->sqrtSpeed()/totSqrtSpeed();
		}   // while
		ASSERT(item != NULL);
		item->dt();
	}	// for
	t += 1;
	temp *= (float)0.90;   // annealing
}   // MapDoc::dt
    
float MapDoc::totSqrtSpeed() {
	float tot = 0.1;
	MapItem *item;
	for(POSITION pos = GetStartPosition(); pos != NULL;) {
		item = (MapItem *)GetNextItem(pos);
		tot += item->sqrtSpeed();
	}	// for
	return tot;		
}

int MapDoc::newStim() {
	StimResp *newsr = new StimResp(this);
	srList.Add(newsr);
	return (srList.GetSize()-1);
}	// MapDoc::newStim

void MapDoc::recalcCorr() {
	if (user->corr != NULL)
		delete [] user->corr;
	user->corr = new float[m_docItemList.GetCount()];
	for (int count = 0; count < m_docItemList.GetCount(); count++)
		user->corr[count] = 0.9;
	POSITION pos = GetStartPosition();
	int n = 0;
	while (pos != NULL) {
		MapItem *item = (MapItem *)GetNextItem(pos);
		ASSERT(m_docItemList.GetCount() > 0);
		if (n == 0) {
			if (item->corr != NULL)
				delete [] item->corr;
	    	item->corr = new float[m_docItemList.GetCount()];
	    }	// fi
	    item->corr[n] = 1.0;	// set auto correlation
		POSITION pos2 = pos;
		int m = n+1;
		while (pos2 != NULL) {
			MapItem *item2 = (MapItem *)GetNextItem(pos2);
			if (n == 0) {
				if (item->corr != NULL)
					delete [] item2->corr;
		    	item2->corr = new float[m_docItemList.GetCount()];
		    }	// fi
			int neitherpicked = 0;
			int numTrials = 1;
			int numStim = srList.GetSize();
			for (int l = 0; l < numStim; l++) {
				StimResp *curr = (StimResp *)srList[l];
				if (((curr->s1 == n) || (curr->s2 == n) || (curr->s3 == n)) &&
					((curr->s1 == m) || (curr->s2 == m) || (curr->s3 == m))) {
					numTrials++;
					neitherpicked += (int)((curr->resp != m) && (curr->resp != n));
				}	// fi
			}	// rof
			item->corr[m] = (float)neitherpicked/(float)numTrials;
			item2->corr[n] = item->corr[m];
			m++;
		}	// while
		n++;
	}	// while
	temp = 1e-3;	// re-anneal
}	// MapDoc::recalcCorr

BOOL MapDoc::OnNewDocument() {
	if (!COleClientDoc::OnNewDocument())
		return FALSE;
#ifdef _DEBUG
// #include "dumitems.cpp"
	temp = 1e-3;
	// totSpeed = 0.0;  
	t = 0;
	// TxtrItem *newItem = new TxtrItem(this);
	CA1DItem *newItem = new CA1DItem(this);
	AddItem(newItem);
	newItem = new CA1DItem(this, newItem);
	AddItem(newItem);
	newItem = new CA1DItem(this, newItem);
	AddItem(newItem);
	newItem = new CA1DItem(this, newItem);
	AddItem(newItem);
	// newItem = new TxtrItem(this);
	// AddItem(newItem);
	// newItem = new TxtrItem(this);
	// AddItem(newItem);
	// newItem = new TxtrItem(this);
	// AddItem(newItem);
	user = new MapItem(this);
	user->wx = 400; user->wy = 300; user->wz = 0;
	recalcCorr();
#endif // _DEBUG
	return TRUE;
}	// MapDoc::OnNewDocument

void MapDoc::OnInsertWord() {
	WordItem *newItem = new WordItem(this, "television");
	AddItem(newItem);
	recalcCorr();
}	// MapDoc::OnInsertWord

void MapDoc::OnInsertTxtr() {
	TxtrItem *newItem = new TxtrItem(this);
	AddItem(newItem);
	recalcCorr();
}	// MapDoc::OnInsertTxtr

void MapDoc::OnInsertCa1d(){
	CA1DItem *newItem = new CA1DItem(this);
	AddItem(newItem);
	recalcCorr();
}	// MapDoc::OnInsertCa1d()

void MapDoc::OnViewInfo() {
	InfoDlg info(this);
	info.DoModal();
}	// MapDoc::OnViewInfo

void MapDoc::Serialize(CArchive& ar) {
	if (ar.IsStoring()) {
		POSITION pos;
		ar << (WORD)m_docItemList.GetCount();
		for (pos = GetStartPosition(); pos != NULL; ) {
			CDocItem *item = GetNextItem(pos);
			if (item->IsKindOf(RUNTIME_CLASS(WordItem)))
				ar << (WORD) CLASS_WORDITEM;
			else if (item->IsKindOf(RUNTIME_CLASS(TxtrItem)))
				ar << (WORD) CLASS_TXTRITEM;
			else if (item->IsKindOf(RUNTIME_CLASS(CA1DItem)))
				ar << (WORD) CLASS_CA1DITEM;
			item->Serialize(ar);
		}	// rof
		ar << (WORD)srList.GetSize();
		for (int count = 0; count < srList.GetSize(); count++) {
			StimResp *sr = (StimResp *)srList[count];
			sr->Serialize(ar);
		}	// rof
	} else {
		WORD count;
		ar >> count;	// number of items in document
		for (; count > 0; count--) {
			WORD itemToken;
			ar >> itemToken;
			// itemToken = CLASS_WORDITEM;
			CDocItem *item;
			switch (itemToken) {
				case CLASS_WORDITEM :
					item = new WordItem(this);
					break;
				case CLASS_TXTRITEM :
					item = new TxtrItem(this);
					break;
				case CLASS_CA1DITEM :
					item = new CA1DItem(this);
					break;
			}	// switch
			ASSERT(item != NULL);
			item->Serialize(ar);
			AddItem(item);
		}	// rof
		ar >> count;	// number of stimulus/response sets
		for (; count > 0; count--) {
			StimResp *sr = new StimResp(this);
			sr->Serialize(ar);
		}	// rof
		user = new MapItem(this);
		user->wx = 400; user->wy = 300; user->wz = 0;
		recalcCorr();
		temp = 1e-3;	// re-anneal
		// totSpeed = 0.0;
		t = 0;
		MapItem *item;
		for (POSITION pos = GetStartPosition(); pos == NULL;) {
			item = (MapItem *)GetNextItem(pos);
			item->dt();
		}   // for
	}	// fi
}	// MapDoc::Serialize

void MapDoc::DeleteContents() {
	// TODO: add additional cleanup before doc-items are deleted
	COleClientDoc::DeleteContents();	// delete doc-items
}	// MapDoc::DeleteContents

#ifdef _DEBUG
void MapDoc::AssertValid() const {
	COleClientDoc::AssertValid();
}	// MapDoc::AssertValid

void MapDoc::Dump(CDumpContext& dc) const {
	COleClientDoc::Dump(dc);
}	// MapDoc::Dump
#endif //_DEBUG


/////////////////////////////////////////////////////////////////////////////
// StimResp class

IMPLEMENT_DYNAMIC(StimResp, CObject)

StimResp::StimResp(MapDoc *pDoc) {
	s1 = (int)randflt(pDoc->m_docItemList.GetCount());
	do {   
		s2 = (int)randflt(pDoc->m_docItemList.GetCount());
	} while (s2 == s1);
	do {
		s3 = (int)randflt(pDoc->m_docItemList.GetCount());
	} while ((s3 == s1) || (s3 == s2));
	resp = -1;
}	// StimResp::StimResp

// Operations	
StimResp::~StimResp() { }	// StimResp::~StimResp

void StimResp::Serialize(CArchive& ar) {
	if (ar.IsStoring() && (resp != -1)) {
		ar << (WORD)s1 << (WORD)s2 << (WORD)s3 << (WORD)resp << when;
	} else {
		WORD tmp;
		ar >> tmp; s1 = (int)tmp;
		ar >> tmp; s2 = (int)tmp;
		ar >> tmp; s3 = (int)tmp;
		ar >> tmp; resp = (int)tmp;
		// when = CTime();
		ar >> when;
	}	// fi
}	// StimResp::Serialize

#ifdef _DEBUG
void StimResp::AssertValid() const { }	// StimResp::AssertValid
void StimResp::Dump(CDumpContext& dc) const { }	// StimResp::Dump
#endif //_DEBUG


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
	m_pDocument->RemoveItem(this);
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


/////////////////////////////////////////////////////////////////////////////
// WordItem class
                    
IMPLEMENT_DYNAMIC(WordItem, MapItem)

WordItem::WordItem(MapDoc *pDoc) :
		MapItem(pDoc) {
}	// WordItem::WordItem

WordItem::WordItem(MapDoc *pDoc, CString initStr) :
		MapItem(pDoc) {
	word = initStr;
}	// WordItem::WordItem

WordItem::~WordItem() { }	// WordItem::~WordItem

BOOL WordItem::Draw(CDC* pDC, LPCRECT lpBounds, LPCRECT lpWBound, CDC *pFormatDC) {
    pDC->SetTextAlign(TA_CENTER);
	pDC->ExtTextOut((int)wx, (int)wy, 0, NULL, word, word.GetLength(), NULL);
	return TRUE;
}	// WordItem::Draw

void WordItem::Serialize(CArchive& ar) { 
	MapItem::Serialize(ar);
	if (ar.IsStoring())
		ar << word;
	else
		ar >> word;
}	// WordItem::Serialize

#ifdef _DEBUG
void WordItem::AssertValid() const { }	// WordItem::AssertValid
void WordItem::Dump(CDumpContext& dc) const { } 	// WordItem::Dump
#endif //_DEBUG






