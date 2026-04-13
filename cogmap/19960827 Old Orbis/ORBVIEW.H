// OrbView.h  Copyright (C) 1996  DG Lane

#ifndef __ORBVIEW_H__
#define __ORBVIEW_H__

#include "OrbDoc.h"

class OrbView : public CView {
public:
	OrbView();
	virtual ~OrbView();
	DECLARE_DYNCREATE(OrbView);

	OrbDoc *GetDocument();
	CFont *txtFont;
	CObList iteml;		// list of OrbViewItem
	POSITION currPos;	// where its at
	UINT timerID;		// timer

	virtual void OnDraw(CDC* pDC);  // overridden to draw this view
	virtual void OnInitialUpdate();
	virtual void OnUpdate(CView *pSender, LPARAM lHint, CObject *pHint);

// Diagnostics
#ifdef _DEBUG
	virtual void AssertValid() const;
	virtual void Dump(CDumpContext& dc) const;
#endif

// Printing support
	virtual BOOL OnPreparePrinting(CPrintInfo* pInfo);
	virtual void OnBeginPrinting(CDC* pDC, CPrintInfo* pInfo);
	virtual void OnEndPrinting(CDC* pDC, CPrintInfo* pInfo);

// OLE Client support
	virtual BOOL IsSelected(const CObject* pDocItem) const;

// Generated message map functions
	//{{AFX_MSG(OrbView)
	afx_msg void OnInsertObject();	// OLE support
	afx_msg void OnViewFont();
	afx_msg void OnInsertWord();
	afx_msg void OnTimer(UINT nIDEvent);
	afx_msg void OnDestroy();
	//}}AFX_MSG
	DECLARE_MESSAGE_MAP()
};	// class OrbView

#ifndef _DEBUG	// debug version in orbview.cpp
inline OrbDoc *OrbView::GetDocument() { 
	return (OrbDoc*) m_pDocument;
}	// OrbView::GetDocument
#endif

#endif             
