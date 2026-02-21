// trform.h : header file
//

/////////////////////////////////////////////////////////////////////////////
// TRForm form view

#ifndef __AFXEXT_H__
#include <afxext.h>
#endif

#include "FuelTrans.h"

class TRForm : public CFormView {
	DECLARE_DYNCREATE(TRForm)
protected:
	TRForm();
		// protected constructor used by dynamic creation

// Form Data
public:
	//{{AFX_DATA(TRForm)
	enum { IDD = IDD_TOTAL_READ };
	double	m_Curr10;
	double	m_Curr1;
	double	m_Curr2;
	double	m_Curr3;
	double	m_Curr4;
	double	m_Curr5;
	double	m_Curr6;
	double	m_Curr7;
	double	m_Curr8;
	double	m_Curr9;
	CString	m_Date;
	double	m_Diff1;
	double	m_Diff10;
	double	m_Diff2;
	double	m_Diff3;
	double	m_Diff4;
	double	m_Diff5;
	double	m_Diff6;
	double	m_Diff7;
	double	m_Diff8;
	double	m_Diff9;
	double	m_Prev1;
	double	m_Prev10;
	double	m_Prev2;
	double	m_Prev3;
	double	m_Prev4;
	double	m_Prev5;
	double	m_Prev6;
	double	m_Prev7;
	double	m_Prev8;
	double	m_Prev9;
	int		m_Shift;
	CString	m_Time;
	//}}AFX_DATA

// Attributes
public:

// Operations
public:

// Implementation
protected:
	virtual ~TRForm();
	virtual void DoDataExchange(CDataExchange* pDX);	// DDX/DDV support
	// Generated message map functions
	//{{AFX_MSG(TRForm)
		// NOTE - the ClassWizard will add and remove member functions here.
	//}}AFX_MSG
	DECLARE_MESSAGE_MAP()
};

/////////////////////////////////////////////////////////////////////////////
