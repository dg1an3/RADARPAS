// mapview.h : header file
//

/////////////////////////////////////////////////////////////////////////////
// CMapView view

class CMapView : public CScrollView
{
	DECLARE_DYNCREATE(CMapView)
protected:
	CMapView();			// protected constructor used by dynamic creation

// Attributes
public:
	CObArray refBlock;
	int ActiveRef;	// indicates currently selected reference

// Operations
public:
	void EditRow(int nRow);

// Implementation
protected:
	virtual ~CMapView();
	virtual	void OnDraw(CDC* pDC);		// overridden to draw this view
	virtual	void OnInitialUpdate();		// first time after construct
 	virtual void CMapView::OnUpdate(CView* pSender, 
 		LPARAM lHint, CObject* pHint);

	// Generated message map functions
	//{{AFX_MSG(CMapView)
	afx_msg void OnLButtonDown(UINT nFlags, CPoint point);
	afx_msg void OnLButtonDblClk(UINT nFlags, CPoint point);
	afx_msg void OnMouseMove(UINT nFlags, CPoint point);
	afx_msg void OnLButtonUp(UINT nFlags, CPoint point);
	afx_msg void OnRButtonDown(UINT nFlags, CPoint point);
	//}}AFX_MSG
	DECLARE_MESSAGE_MAP()
};

/////////////////////////////////////////////////////////////////////////////
