// refitemd.h : header file
//

/////////////////////////////////////////////////////////////////////////////
// CRefItemDlg dialog

class CRefItemDlg : public CDialog
{
// Construction
public:
	CRefItemDlg(CWnd* pParent = NULL);	// standard constructor

// Dialog Data
	//{{AFX_DATA(CRefItemDlg)
	enum { IDD = IDD_REF_DLG };
	CString	m_authors;
	CString	m_institution;
	CString	m_source;
	CString	m_title;
	CString	m_id;
	CString	m_MeSH;
	CString	m_abstract;
	//}}AFX_DATA

// Implementation
protected:
	virtual void DoDataExchange(CDataExchange* pDX);	// DDX/DDV support

	// Generated message map functions
	//{{AFX_MSG(CRefItemDlg)
	//}}AFX_MSG
	DECLARE_MESSAGE_MAP()
};
