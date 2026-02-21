// refitemf.h : header file
//

/////////////////////////////////////////////////////////////////////////////
// CRefItemForm form view

#ifndef __AFXEXT_H__
#include <afxext.h>
#endif

class CRefItemForm : public CFormView
{
	DECLARE_DYNCREATE(CRefItemForm)
protected:
	CRefItemForm();			// protected constructor used by dynamic creation

// Form Data
public:
	//{{AFX_DATA(CRefItemForm)
	enum { IDD = IDD_REF_FORM };
	CString	m_authors;
	CString	m_institution;
	CString	m_source;
	CString	m_title;
	CString	m_id;
	//}}AFX_DATA

// Attributes
public:

// Operations
public:

// Implementation
protected:
	virtual ~CRefItemForm();
	virtual void DoDataExchange(CDataExchange* pDX);	// DDX/DDV support
	// Generated message map functions
	//{{AFX_MSG(CRefItemForm)
		// NOTE - the ClassWizard will add and remove member functions here.
	//}}AFX_MSG
	DECLARE_MESSAGE_MAP()
};

/////////////////////////////////////////////////////////////////////////////
