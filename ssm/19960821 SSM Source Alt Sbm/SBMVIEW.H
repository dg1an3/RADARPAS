// sbmview.h : interface of the CSbmView class
//
/////////////////////////////////////////////////////////////////////////////

class CSbmView : public CView
{
protected: // create from serialization only
	CSbmView();
	DECLARE_DYNCREATE(CSbmView)

// Attributes
public:
	CSbmDoc* GetDocument();
	int atAcct;
	
// Operations
public:

// Implementation
public:
	virtual ~CSbmView();
	virtual void OnInitialUpdate();
	virtual void OnDraw(CDC* pDC);  // overridden to draw this view
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
protected:
	//{{AFX_MSG(CSbmView)
	afx_msg void OnLButtonDown(UINT nFlags, CPoint point);
	//}}AFX_MSG
	DECLARE_MESSAGE_MAP()
};

#ifndef _DEBUG	// debug version in sbmview.cpp
inline CSbmDoc* CSbmView::GetDocument()
   { return (CSbmDoc*) m_pDocument; }
#endif

/////////////////////////////////////////////////////////////////////////////
