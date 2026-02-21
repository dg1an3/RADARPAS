// showcogv.h : header file
//

/////////////////////////////////////////////////////////////////////////////
// CShowCogView form view

#ifndef __AFXEXT_H__
#include <afxext.h>
#endif

class CShowCogView : public CFormView
{
	DECLARE_DYNCREATE(CShowCogView)
protected:
	CShowCogView();			// protected constructor used by dynamic creation

// Form Data
public:
	//{{AFX_DATA(CShowCogView)
	enum { IDD = IDD_SHOW_MAP };
	CListBox	m_WordList;
	CListBox	m_RespList;
	//}}AFX_DATA

// Attributes
public:

// Operations
public:

// Implementation
protected:
	virtual ~CShowCogView();
	virtual void DoDataExchange(CDataExchange* pDX);	// DDX/DDV support
	virtual void OnUpdate(CView *pSender, LPARAM lHint, CObject *pHint);
	// Generated message map functions
	//{{AFX_MSG(CShowCogView)
		// NOTE - the ClassWizard will add and remove member functions here.
	//}}AFX_MSG
	DECLARE_MESSAGE_MAP()
};

/////////////////////////////////////////////////////////////////////////////
