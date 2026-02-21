// acctdoc.h : interface of the CAcctDoc class
//
/////////////////////////////////////////////////////////////////////////////

class CAcctDoc : public CDocument
{
protected: // create from serialization only
	CAcctDoc();
	DECLARE_DYNCREATE(CAcctDoc)

// Attributes
public:
    CString acctType;
    CString name;
    CString addr1;
    CString addr2;
    CString city;
    CString state;
    CString zip;
    CObArray trans;

// Operations
public:
	float balAsOf(CTime date);	// computes the balance as of the date

// Implementation
public:
	virtual ~CAcctDoc();
	virtual void Serialize(CArchive& ar);	// overridden for document i/o
#ifdef _DEBUG
	virtual	void AssertValid() const;
	virtual	void Dump(CDumpContext& dc) const;
#endif
protected:
	virtual	BOOL	OnNewDocument();

// Generated message map functions
protected:
	//{{AFX_MSG(CAcctDoc)
	afx_msg void OnFileImport();
	//}}AFX_MSG
	DECLARE_MESSAGE_MAP()
};

/////////////////////////////////////////////////////////////////////////////
