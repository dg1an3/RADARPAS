// browseeView.h : interface of the CBrowseeView class
//
/////////////////////////////////////////////////////////////////////////////

#if !defined(AFX_BROWSEEVIEW_H__9ADEF12E_6AD4_11D4_AF85_00C0F05A20CE__INCLUDED_)
#define AFX_BROWSEEVIEW_H__9ADEF12E_6AD4_11D4_AF85_00C0F05A20CE__INCLUDED_

#if _MSC_VER > 1000
#pragma once
#endif // _MSC_VER > 1000


class CBrowseeView : public CHtmlView
{
protected: // create from serialization only
	CBrowseeView();
	DECLARE_DYNCREATE(CBrowseeView)

// Attributes
public:
	CBrowseeDoc* GetDocument();

// Operations
public:

// Overrides
	// ClassWizard generated virtual function overrides
	//{{AFX_VIRTUAL(CBrowseeView)
	public:
	virtual void OnDraw(CDC* pDC);  // overridden to draw this view
	virtual BOOL PreCreateWindow(CREATESTRUCT& cs);
	protected:
	virtual void OnInitialUpdate(); // called first time after construct
	//}}AFX_VIRTUAL

// Implementation
public:
	virtual ~CBrowseeView();
#ifdef _DEBUG
	virtual void AssertValid() const;
	virtual void Dump(CDumpContext& dc) const;
#endif

protected:

// Generated message map functions
protected:
	//{{AFX_MSG(CBrowseeView)
		// NOTE - the ClassWizard will add and remove member functions here.
		//    DO NOT EDIT what you see in these blocks of generated code !
	//}}AFX_MSG
	DECLARE_MESSAGE_MAP()
};

#ifndef _DEBUG  // debug version in browseeView.cpp
inline CBrowseeDoc* CBrowseeView::GetDocument()
   { return (CBrowseeDoc*)m_pDocument; }
#endif

/////////////////////////////////////////////////////////////////////////////

//{{AFX_INSERT_LOCATION}}
// Microsoft Visual C++ will insert additional declarations immediately before the previous line.

#endif // !defined(AFX_BROWSEEVIEW_H__9ADEF12E_6AD4_11D4_AF85_00C0F05A20CE__INCLUDED_)
