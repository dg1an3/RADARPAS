// refmavw.h : interface of the CRefmapView class
//
/////////////////////////////////////////////////////////////////////////////

// Format of Reference View line 1:
#define TITLE_COL 	0
#define TITLE_LEN 	80
#define AUTHORS_COL	(TITLE_COL + TITLE_LEN + 1)
#define AUTHORS_LEN	40    
#define SOURCE_COL	(AUTHORS_COL + AUTHORS_LEN + 1)
#define SOURCE_LEN	30
#define ROW_WIDTH   (SOURCE_COL + SOURCE_LEN)

class CRefmapView : public CRowView
{
protected: // create from serialization only
	CRefmapView();
	DECLARE_DYNCREATE(CRefmapView)

// Attributes
public:
	int m_nActiveRef;
	
	CRefmapDoc* GetDocument();
// Overrides of CRowView
	void GetRowWidthHeight(CDC* pDC, int& nRowWidth, int& nRowHeight);
	int GetActiveRow();
	int GetRowCount();
	void OnDrawRow(CDC* pDC, int nRowNo, int y, BOOL bSelected);
	void ChangeSelectionNextRow(BOOL bNext);
	void ChangeSelectionToRow(int nRow);
	void EditRow(int nRow);
	void SwapRows();
	void DelRef();

// Operations
public:

// Implementation
public:
	virtual ~CRefmapView();
//	virtual void OnDraw(CDC* pDC);  // overridden to draw this view
#ifdef _DEBUG
	virtual void AssertValid() const;
	virtual void Dump(CDumpContext& dc) const;
#endif

	// Printing support
protected:
	//virtual BOOL OnPreparePrinting(CPrintInfo* pInfo);
	//virtual void OnBeginPrinting(CDC* pDC, CPrintInfo* pInfo);
	//virtual void OnEndPrinting(CDC* pDC, CPrintInfo* pInfo);

	// OLE Client support
	//virtual BOOL IsSelected(const CObject* pDocItem) const;

// Generated message map functions
   protected:
	//{{AFX_MSG(CRefmapView)
		// NOTE - the ClassWizard will add and remove member functions here.
		//    DO NOT EDIT what you see in these blocks of generated code !
//	afx_msg void OnInsertObject();	// OLE support
	//}}AFX_MSG
//	DECLARE_MESSAGE_MAP()
};

#ifndef _DEBUG	// debug version in refmavw.cpp
inline CRefmapDoc* CRefmapView::GetDocument()
   { return (CRefmapDoc*) m_pDocument; }
#endif

/////////////////////////////////////////////////////////////////////////////
