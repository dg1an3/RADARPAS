/////////////////////////////////////////////////////////////////////////////
// oChildWnd window

#if !defined _oChildWnd_h_
#define _oChildWnd_h_

#if _MSC_VER >= 1000
#pragma once
#endif // _MSC_VER >= 1000

class oItem;

class oChildWnd : public CWnd {

// Construction
public:
	oChildWnd();
	oChildWnd(oItem *forItem);

// Attributes
public:
	oItem *myItem;

// Operations
public:

// Overrides
	// ClassWizard generated virtual function overrides
	//{{AFX_VIRTUAL(oChildWnd)
	//}}AFX_VIRTUAL

// Implementation
public:
	CPoint downPoint;
	BOOL   dragState;
	virtual ~oChildWnd();

	// Generated message map functions
protected:
	//{{AFX_MSG(oChildWnd)
	afx_msg void OnPaint();
	afx_msg void OnLButtonDown(UINT nFlags, CPoint point);
	afx_msg void OnLButtonUp(UINT nFlags, CPoint point);
	afx_msg void OnMouseMove(UINT nFlags, CPoint point);
	//}}AFX_MSG
	DECLARE_MESSAGE_MAP()
};

/////////////////////////////////////////////////////////////////////////////

//{{AFX_INSERT_LOCATION}}
// Microsoft Developer Studio will insert additional declarations immediately before the previous line.

#endif // !defined _oChildWnd_h_
