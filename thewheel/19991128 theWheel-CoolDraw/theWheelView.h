// theWheelView.h : interface of the CTheWheelView class
//
/////////////////////////////////////////////////////////////////////////////

#if !defined(AFX_THEWHEELVIEW_H__FFE8CF0C_FB18_11D2_AF85_F59AEE2F743B__INCLUDED_)
#define AFX_THEWHEELVIEW_H__FFE8CF0C_FB18_11D2_AF85_F59AEE2F743B__INCLUDED_

#if _MSC_VER > 1000
#pragma once
#endif // _MSC_VER > 1000

#include <vector>
using namespace std;

class theWheelView : public CView
{
protected: // create from serialization only
	theWheelView();
	DECLARE_DYNCREATE(theWheelView)

// Attributes
public:
	theWheelDoc* GetDocument();

// Operations
public:

// Overrides
	// ClassWizard generated virtual function overrides
	//{{AFX_VIRTUAL(theWheelView)
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
	virtual ~theWheelView();
#ifdef _DEBUG
	virtual void AssertValid() const;
	virtual void Dump(CDumpContext& dc) const;
#endif

protected:

// Generated message map functions
protected:
	//{{AFX_MSG(theWheelView)
	afx_msg void OnPaint();
	afx_msg void OnMouseMove(UINT nFlags, CPoint point);
	afx_msg void OnSize(UINT nType, int cx, int cy);
	//}}AFX_MSG
	DECLARE_MESSAGE_MAP()

private:
	CRect m_rectClient;
	CDC m_memDC;
	CBitmap m_buffer;

	double m_aspectRatio;

	vector<CRect> m_arrNodes;
};

#ifndef _DEBUG  // debug version in theWheelView.cpp
inline theWheelDoc* theWheelView::GetDocument()
   { return (theWheelDoc*)m_pDocument; }
#endif

/////////////////////////////////////////////////////////////////////////////

//{{AFX_INSERT_LOCATION}}
// Microsoft Visual C++ will insert additional declarations immediately before the previous line.

#endif // !defined(AFX_THEWHEELVIEW_H__FFE8CF0C_FB18_11D2_AF85_F59AEE2F743B__INCLUDED_)
