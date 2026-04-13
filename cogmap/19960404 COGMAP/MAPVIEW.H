// mapview.h : interface of the MapView class
//
/////////////////////////////////////////////////////////////////////////////

class MapView : public CView
{
protected: // create from serialization only
	MapView();
	DECLARE_DYNCREATE(MapView)

// Attributes
public:
	MapDoc* GetDocument();
	BOOL triadView;
	
// Operations
public:

// Implementation
public:
	virtual ~MapView();
	virtual void OnDraw(CDC* pDC);  // overridden to draw this view
	virtual void OnUpdate(CView *pSender, LPARAM lHint, CObject *pHint);
	
#ifdef _DEBUG
	virtual void AssertValid() const;
	virtual void Dump(CDumpContext& dc) const;
#endif

	// Printing support
protected:
	virtual BOOL OnPreparePrinting(CPrintInfo* pInfo);
	virtual void OnBeginPrinting(CDC* pDC, CPrintInfo* pInfo);
	virtual void OnEndPrinting(CDC* pDC, CPrintInfo* pInfo);

	// OLE Client support
	virtual BOOL IsSelected(const CObject* pDocItem) const;

// Generated message map functions
protected:
	//{{AFX_MSG(MapView)
	afx_msg void OnInsertObject();	// OLE support
	afx_msg void OnMouseMove(UINT nFlags, CPoint point);
	afx_msg void OnViewTriad();
	afx_msg void OnUpdateViewTriad(CCmdUI* pCmdUI);
	afx_msg void OnLButtonDown(UINT nFlags, CPoint point);
	//}}AFX_MSG
	DECLARE_MESSAGE_MAP()
};

#ifndef _DEBUG	// debug version in cogmavw.cpp
inline MapDoc* MapView::GetDocument()
   { return (MapDoc*) m_pDocument; }
#endif

