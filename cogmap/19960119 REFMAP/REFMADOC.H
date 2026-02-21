// refmadoc.h : interface of the CRefmapDoc class
//
/////////////////////////////////////////////////////////////////////////////

class CRefmapDoc : public CDocument
{
protected: // create from serialization only
	CRefmapDoc();
	DECLARE_DYNCREATE(CRefmapDoc)

// Attributes
public:
    CObArray ref;
	int GetNumRef() { return ref.GetSize(); };
    CRefItem *getRef(int at) 
    	{ ASSERT(ref[at] != NULL); return (CRefItem *)ref[at]; };
    
// Operations
public:
    void SwapRef(int ref1, int ref2)
   	{	CObject *temp = ref[ref1];
   		ref[ref1] = ref[ref2];
   		ref[ref2] = temp;
   	};	// SwapRef
 
 	void DelRef(int atRef) 
 	{	CObject *temp = ref[atRef];
 		ref.RemoveAt(atRef);
 		delete temp;
 	};	// DelRef
 	   
// Implementation
public:
	virtual ~CRefmapDoc();
	virtual void Serialize(CArchive& ar);	// overridden for document i/o
#ifdef _DEBUG
	virtual	void AssertValid() const;
	virtual	void Dump(CDumpContext& dc) const;
#endif
protected:
	virtual	BOOL OnNewDocument();

// Generated message map functions
protected:
	// Generated message map functions
	//{{AFX_MSG(CRefmapDoc)
	afx_msg void OnRefAdd();
	afx_msg void OnRefSort();
	afx_msg void OnFileImportCit();
	afx_msg void OnFileImportHtml();
	//}}AFX_MSG
	DECLARE_MESSAGE_MAP()
};

/////////////////////////////////////////////////////////////////////////////
