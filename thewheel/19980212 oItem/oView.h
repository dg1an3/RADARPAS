/////////////////////////////////////////////////////////////////////////////
// oView.h : interface of the oView class
//

#if !defined(_oView_h_)
#define _oView_h_

#if _MSC_VER >= 1000
#pragma once
#endif // _MSC_VER >= 1000

class oItem;

class oView : public CView {

protected: // create from serialization only
	oView();
	DECLARE_DYNCREATE(oView)

public:
	virtual ~oView();

// Attributes
public:
	oItem     *mySelection;
	oDocument *GetDocument();

// Operations
public:

// Overrides
	// ClassWizard generated virtual function overrides
	//{{AFX_VIRTUAL(oView)
	public:
	virtual void OnDraw(CDC* pDC);  // overridden to draw this view
	virtual BOOL PreCreateWindow(CREATESTRUCT& cs);
	protected:
	virtual void OnInitialUpdate(); // called first time after construct
	virtual BOOL IsSelected(const CObject* pDocItem) const;// Container support
	virtual void OnUpdate(CView* pSender, LPARAM lHint, CObject* pHint);
	//}}AFX_VIRTUAL

// Implementation
public:
	double totalActivation;
	void dTotalActivation(double delta);
	POSITION nextPosAt;
	POSITION nextSizeAt;
	void OnPosingItems(DWORD time);
	void OnSizingItems(DWORD time, CPoint mouse);
	void     SetupTracker(oItem *forItem, CRectTracker *tracker);
	void     SetSelection(oItem *toItem);
	oItem *HitTestItems(CPoint point);

#ifdef _DEBUG
	virtual void AssertValid() const;
	virtual void Dump(CDumpContext& dc) const;
#endif

protected:

// Generated message map functions
protected:
	//{{AFX_MSG(oView)
	afx_msg void OnDestroy();
	afx_msg void OnSetFocus(CWnd* pOldWnd);
	afx_msg void OnSize(UINT nType, int cx, int cy);
	afx_msg void OnInsertObject();
	afx_msg void OnCancelEditCntr();
	afx_msg void OnLButtonDown(UINT nFlags, CPoint point);
	afx_msg void OnLButtonDblClk(UINT nFlags, CPoint point);
	afx_msg BOOL OnSetCursor(CWnd* pWnd, UINT nHitTest, UINT message);
	afx_msg void OnEditClear();
	afx_msg void OnUpdateEditClear(CCmdUI* pCmdUI);
	afx_msg void OnEditCopy();
	afx_msg void OnUpdateEditCopy(CCmdUI* pCmdUI);
	afx_msg void OnEditPaste();
	afx_msg void OnMouseMove(UINT nFlags, CPoint point);
	afx_msg void OnDropFiles(HDROP hDropInfo);
	//}}AFX_MSG
	DECLARE_MESSAGE_MAP()
};

#ifndef _DEBUG  // debug version in oView.cpp

inline oDocument * 
oView::GetDocument() { 
	return (oDocument*)m_pDocument; 
}

#endif

/////////////////////////////////////////////////////////////////////////////

//{{AFX_INSERT_LOCATION}}
// Microsoft Developer Studio will insert additional declarations 
// immediately before the previous line.

#endif // !defined _oView_h

