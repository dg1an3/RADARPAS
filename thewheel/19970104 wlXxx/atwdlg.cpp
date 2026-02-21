// AboutTheWheelDlg dialog used for App About

class AboutTheWheelDlg : public CDialog {
public:
	AboutTheWheelDlg();

// Dialog Data
	//{{AFX_DATA(AboutTheWheelDlg)
	enum { IDD = IDD_ABOUTBOX };
	//}}AFX_DATA

// Implementation
protected:
	virtual void DoDataExchange(CDataExchange* pDX);	// DDX/DDV support
	//{{AFX_MSG(AboutTheWheelDlg)
		// No message handlers
	//}}AFX_MSG
	DECLARE_MESSAGE_MAP()
};	// class AboutTheWheelDlg

AboutTheWheelDlg::AboutTheWheelDlg() : CDialog(AboutTheWheelDlg::IDD) {
	//{{AFX_DATA_INIT(AboutTheWheelDlg)
	//}}AFX_DATA_INIT
}	// AboutTheWheelDlg::AboutTheWheelDlg

void AboutTheWheelDlg::DoDataExchange(CDataExchange* pDX) {
	CDialog::DoDataExchange(pDX);
	//{{AFX_DATA_MAP(AboutTheWheelDlg)
	//}}AFX_DATA_MAP
}	// AboutTheWheelDlg::DoDataExchange

BEGIN_MESSAGE_MAP(AboutTheWheelDlg, CDialog)
	//{{AFX_MSG_MAP(AboutTheWheelDlg)
		// No message handlers
	//}}AFX_MSG_MAP
END_MESSAGE_MAP()

// App command to run the dialog
void theWheelApp::OnAppAbout() {
	AboutTheWheelDlg aboutDlg;
	aboutDlg.DoModal();
}	// theWheelApp::OnAppAbout

// this goes in theWheel.h
	afx_msg void OnAppAbout();
