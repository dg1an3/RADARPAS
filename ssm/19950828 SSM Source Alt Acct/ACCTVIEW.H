// acctview.h : interface of the CAcctView class
//
/////////////////////////////////////////////////////////////////////////////

class CAcctView : public CView
{
protected: // create from serialization only
	CAcctView();
	DECLARE_DYNCREATE(CAcctView)

// Attributes
public:
	CAcctDoc* GetDocument();

// Operations
public:

// Implementation
public:
	virtual ~CAcctView();
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
	//{{AFX_MSG(CAcctView)
		// NOTE - the ClassWizard will add and remove member functions here.
		//    DO NOT EDIT what you see in these blocks of generated code !
	//}}AFX_MSG
	DECLARE_MESSAGE_MAP()
};

#ifndef _DEBUG	// debug version in acctview.cpp
inline CAcctDoc* CAcctView::GetDocument()
   { return (CAcctDoc*) m_pDocument; }
#endif

/////////////////////////////////////////////////////////////////////////////
