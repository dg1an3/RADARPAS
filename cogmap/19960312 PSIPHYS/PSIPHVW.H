// psiphvw.h : interface of the CPsiphysView class
//
/////////////////////////////////////////////////////////////////////////////

class CPsiphysView : public CView
{
protected: // create from serialization only
	CPsiphysView();
	DECLARE_DYNCREATE(CPsiphysView)

// Attributes
public:
	CPsiphysDoc* GetDocument();
	
// Operations
public:
	
// Implementation
public:
	virtual ~CPsiphysView();
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
	//{{AFX_MSG(CPsiphysView)
	afx_msg void OnChar(UINT nChar, UINT nRepCnt, UINT nFlags);
	//}}AFX_MSG
	DECLARE_MESSAGE_MAP()
};

#ifndef _DEBUG	// debug version in psiphvw.cpp
inline CPsiphysDoc* CPsiphysView::GetDocument()
   { return (CPsiphysDoc*) m_pDocument; }
#endif

/////////////////////////////////////////////////////////////////////////////
