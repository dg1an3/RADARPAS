// infodlg.h : header file
//

// #include "mapdoc.h"

/////////////////////////////////////////////////////////////////////////////
// InfoDlg dialog

class InfoDlg : public CDialog {
// Construction
public:
	InfoDlg(MapDoc *forDoc, CWnd* pParent = NULL);	// standard constructor

// Dialog Data
	//{{AFX_DATA(InfoDlg)
	enum { IDD = IDD_INFODLG };
	long	m_ItemNum;
	long	m_RespNum;
	//}}AFX_DATA
	MapDoc *pDoc;
	
// Implementation
protected:
	virtual void DoDataExchange(CDataExchange* pDX);	// DDX/DDV support

	// Generated message map functions
	//{{AFX_MSG(InfoDlg)
	virtual BOOL OnInitDialog();
	//}}AFX_MSG
	DECLARE_MESSAGE_MAP()
};
