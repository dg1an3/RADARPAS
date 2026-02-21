// theWheelView.h : interface of the CTheWheelView class
//
/////////////////////////////////////////////////////////////////////////////

#if !defined(AFX_THEWHEELVIEW_H__8FF714AC_CD09_11D2_AB06_CCE30BC10000__INCLUDED_)
#define AFX_THEWHEELVIEW_H__8FF714AC_CD09_11D2_AB06_CCE30BC10000__INCLUDED_

#if _MSC_VER > 1000
#pragma once
#endif // _MSC_VER > 1000


class CTheWheelView : public CView
{
protected: // create from serialization only
	CTheWheelView();
	DECLARE_DYNCREATE(CTheWheelView)

// Attributes
public:
	CTheWheelDoc* GetDocument();

// Operations
public:

// Overrides
	// ClassWizard generated virtual function overrides
	//{{AFX_VIRTUAL(CTheWheelView)
	public:
	virtual void OnDraw(CDC* pDC);  // overridden to draw this view
	virtual BOOL PreCreateWindow(CREATESTRUCT& cs);
	protected:
	virtual BOOL OnPreparePrinting(CPrintInfo* pInfo);
	virtual void OnBeginPrinting(CDC* pDC, CPrintInfo* pInfo);
	virtual void OnEndPrinting(CDC* pDC, CPrintInfo* pInfo);
	//}}AFX_VIRTUAL

// Implementation
public:
	virtual ~CTheWheelView();
#ifdef _DEBUG
	virtual void AssertValid() const;
	virtual void Dump(CDumpContext& dc) const;
#endif

protected:

// Generated message map functions
protected:
	//{{AFX_MSG(CTheWheelView)
		// NOTE - the ClassWizard will add and remove member functions here.
		//    DO NOT EDIT what you see in these blocks of generated code !
	//}}AFX_MSG
	DECLARE_MESSAGE_MAP()
};

#ifndef _DEBUG  // debug version in theWheelView.cpp
inline CTheWheelDoc* CTheWheelView::GetDocument()
   { return (CTheWheelDoc*)m_pDocument; }
#endif

/////////////////////////////////////////////////////////////////////////////

//{{AFX_INSERT_LOCATION}}
// Microsoft Visual C++ will insert additional declarations immediately before the previous line.

#endif // !defined(AFX_THEWHEELVIEW_H__8FF714AC_CD09_11D2_AB06_CCE30BC10000__INCLUDED_)
