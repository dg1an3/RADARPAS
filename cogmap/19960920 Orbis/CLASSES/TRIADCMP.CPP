// TriadCmp.cpp  Copyright (C) 1996 DG Lane
/////////////////////////////////////////////////////////////////////////////

#include "stdafx.h"
#include "cogmap.h"

#include "TriadCmp.h"

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

void MapDoc::recalcCorr() {
	if (user->corr != NULL)
		delete [] user->corr;
	user->corr = new REAL[m_docItemList.GetCount()];
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
	    	item->corr = new REAL[m_docItemList.GetCount()];
	    }	// fi
	    item->corr[n] = 1.0;	// set auto correlation
		POSITION pos2 = pos;
		int m = n+1;
		while (pos2 != NULL) {
			MapItem *item2 = (MapItem *)GetNextItem(pos2);
			if (n == 0) {
				if (item->corr != NULL)
					delete [] item2->corr;
		    	item2->corr = new REAL[m_docItemList.GetCount()];
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
			item->corr[m] = (REAL)neitherpicked/(REAL)numTrials;
			item2->corr[n] = item->corr[m];
			m++;
		}	// while
		n++;
	}	// while
	temp = 1e-3;	// re-anneal
}	// MapDoc::recalcCorr

int MapDoc::newStim() {
	StimResp *newsr = new StimResp(this);
	srList.Add(newsr);
	return (srList.GetSize()-1);
}	// MapDoc::newStim

// triadView class
	if (triadView) {
		MapDoc *pDoc = (MapDoc *)GetDocument();
		int currStim = pDoc->srList.GetSize()-1;
		CRect wndExt;
		GetWindowRect(&wndExt); 
		wndExt.right -= wndExt.left; wndExt.left = 0; 
		wndExt.bottom -= wndExt.top; wndExt.top = 0;
		CSize diff = point-CPoint(wndExt.right/3.0, wndExt.bottom/3.0);
		diff.cx = abs(diff.cx);
		diff.cy = abs(diff.cy);
		if (diff.cx + diff.cy < 100) {
			((StimResp *)pDoc->srList[currStim])->resp = 
				((StimResp *)pDoc->srList[currStim])->s1;
		} else {
			CSize diff = point-CPoint(wndExt.right*2.0/3.0, wndExt.bottom/3.0);
			diff.cx = abs(diff.cx);
			diff.cy = abs(diff.cy);
			if (diff.cx + diff.cy < 100) {
				((StimResp *)pDoc->srList[currStim])->resp = 
					((StimResp *)pDoc->srList[currStim])->s2;
			} else {
				CSize diff = point-CPoint(wndExt.right/2.0, wndExt.bottom*2.0/3.0);
				diff.cx = abs(diff.cx);
				diff.cy = abs(diff.cy);
				if (diff.cx + diff.cy < 100) {
					((StimResp *)pDoc->srList[currStim])->resp = 
						((StimResp *)pDoc->srList[currStim])->s3;
				}	// if
			}	// if
		}	// if  
		if (((StimResp *)pDoc->srList[currStim])->resp != -1)
			((StimResp *)pDoc->srList[currStim])->when = CTime::GetCurrentTime();	
				// stamp response with the current time
		// if sqrt(num of stimresp) > num of objects, generate a new object
		if (sqrt((float)pDoc->srList.GetSize()) > pDoc->m_docItemList.GetCount()) {
			pDoc->recalcCorr();
		    // select object with lowest average correlation as parent
		    float minAvg = 1.1;
		    // CA1DItem *minItem = NULL;
		    WordItem *minItem = NULL;
		    POSITION pos;
		    for (pos = pDoc->GetStartPosition(); pos != NULL;) {
		    	MapItem *nextItem = (MapItem *)pDoc->GetNextItem(pos);
		    	if ((nextItem->IsKindOf(RUNTIME_CLASS(WordItem))) && 
		    	    (nextItem->avgCorr() < minAvg)) {
		    		minAvg = nextItem->avgCorr();
		    		minItem = (WordItem *)nextItem;
		    	}	// if
		   	}	// for
		   	if (minItem != NULL) {
		   		WordItem *newItem = new WordItem(pDoc, minItem);
		   		pDoc->AddItem(newItem);
		   		// pDoc->recalcCorr();	// don't need to recalc until end of triad mode
		   	}	// if
		}   // if
		pDoc->UpdateAllViews(NULL);
	}	// if	
