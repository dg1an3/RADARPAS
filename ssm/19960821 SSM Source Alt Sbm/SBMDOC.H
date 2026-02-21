// sbmdoc.h : interface of the CSbmDoc class
/////////////////////////////////////////////////////////////////////////////

#include "AxTrans.h"
#include "AxAcct.h"

class CSbmDoc : public CDocument
{
protected: // create from serialization only
	CSbmDoc();
	DECLARE_DYNCREATE(CSbmDoc)

// Attributes
public:
	CString companyName;
	CString companyAddress;
	CString companyCSZ;
	CObList acct;

// Operations
public:

// Implementation
public:
	virtual ~CSbmDoc();
	virtual void Serialize(CArchive& ar);	// overridden for document i/o
#ifdef _DEBUG
	virtual	void AssertValid() const;
	virtual	void Dump(CDumpContext& dc) const;
#endif
protected:
	virtual	BOOL	OnNewDocument();

// Generated message map functions
protected:
	//{{AFX_MSG(CSbmDoc)
	afx_msg void OnFuelNewtotalizerreadings();
	//}}AFX_MSG
	DECLARE_MESSAGE_MAP()
};

/////////////////////////////////////////////////////////////////////////////
