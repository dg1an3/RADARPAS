// theWheelDoc.h : interface of the CTheWheelDoc class
//
/////////////////////////////////////////////////////////////////////////////

#if !defined(AFX_THEWHEELDOC_H__8FF714AA_CD09_11D2_AB06_CCE30BC10000__INCLUDED_)
#define AFX_THEWHEELDOC_H__8FF714AA_CD09_11D2_AB06_CCE30BC10000__INCLUDED_

#if _MSC_VER > 1000
#pragma once
#endif // _MSC_VER > 1000


class CTheWheelDoc : public CDocument
{
protected: // create from serialization only
	CTheWheelDoc();
	DECLARE_DYNCREATE(CTheWheelDoc)

// Attributes
public:

// Operations
public:

// Overrides
	// ClassWizard generated virtual function overrides
	//{{AFX_VIRTUAL(CTheWheelDoc)
	public:
	virtual BOOL OnNewDocument();
	virtual void Serialize(CArchive& ar);
	//}}AFX_VIRTUAL

// Implementation
public:
	virtual ~CTheWheelDoc();
#ifdef _DEBUG
	virtual void AssertValid() const;
	virtual void Dump(CDumpContext& dc) const;
#endif

protected:

// Generated message map functions
protected:
	//{{AFX_MSG(CTheWheelDoc)
		// NOTE - the ClassWizard will add and remove member functions here.
		//    DO NOT EDIT what you see in these blocks of generated code !
	//}}AFX_MSG
	DECLARE_MESSAGE_MAP()
};

/////////////////////////////////////////////////////////////////////////////

//{{AFX_INSERT_LOCATION}}
// Microsoft Visual C++ will insert additional declarations immediately before the previous line.

#endif // !defined(AFX_THEWHEELDOC_H__8FF714AA_CD09_11D2_AB06_CCE30BC10000__INCLUDED_)
