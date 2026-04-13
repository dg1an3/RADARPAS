// accttran.h : interface of the CAcctTrans class
//
/////////////////////////////////////////////////////////////////////////////

class CAcctTrans : public CObject
{
public:
	CAcctTrans();
	
protected:
	DECLARE_DYNCREATE(CAcctTrans)

// Attributes
public:
	CTime date;
	int num;
	CString type;
	CString desc;
	CString cat;
	CString memo;
    char clr;
	float amt;

// Operations
public:
// Implementation
public:
	virtual ~CAcctTrans();
	virtual void Serialize(CArchive& ar);	// overridden for document i/o
#ifdef _DEBUG
	virtual	void AssertValid() const;
	virtual	void Dump(CDumpContext& dc) const;
#endif
protected:
	// virtual	BOOL	OnNewDocument();

// Generated message map functions
protected:
	//{{AFX_MSG(CAcctDoc)
		// NOTE - the ClassWizard will add and remove member functions here.
		//    DO NOT EDIT what you see in these blocks of generated code !
	//}}AFX_MSG
	//DECLARE_MESSAGE_MAP()
};

/////////////////////////////////////////////////////////////////////////////
