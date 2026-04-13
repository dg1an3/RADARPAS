// axacctvw.h : header file
//

/////////////////////////////////////////////////////////////////////////////
// AxAcctView view

#include "AxAcct.h"

class AxAcctView : public CScrollView {
	DECLARE_DYNCREATE(AxAcctView)
protected:
	AxAcctView();			// protected constructor used by dynamic creation

// Attributes
public:
 	AxAcct* GetDocument();
	int atTrans;

// Operations
public:

// Implementation
protected:
	virtual ~AxAcctView();
	virtual	void OnDraw(CDC* pDC);		// overridden to draw this view
	virtual	void OnInitialUpdate();		// first time after construct
#ifdef _DEBUG
	virtual void AssertValid() const;
	virtual void Dump(CDumpContext& dc) const;
#endif

// Printing support
protected:
	virtual BOOL OnPreparePrinting(CPrintInfo* pInfo);
	virtual void OnBeginPrinting(CDC* pDC, CPrintInfo* pInfo);
	virtual void OnEndPrinting(CDC* pDC, CPrintInfo* pInfo);
	
	// Generated message map functions
	//{{AFX_MSG(AxAcctView)
		// NOTE - the ClassWizard will add and remove member functions here.
	//}}AFX_MSG
	DECLARE_MESSAGE_MAP()
}; 

#ifndef _DEBUG	// debug version in sbmview.cpp
inline AxAcct* AxAcctView::GetDocument()
   { return (AxAcct *) m_pDocument; }
#endif

/////////////////////////////////////////////////////////////////////////////
