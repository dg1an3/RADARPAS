// theWheelDoc.h : interface of the theWheelDoc class
//
/////////////////////////////////////////////////////////////////////////////

#if !defined(AFX_THEWHEELDOC_H__FFE8CF0A_FB18_11D2_AF85_F59AEE2F743B__INCLUDED_)
#define AFX_THEWHEELDOC_H__FFE8CF0A_FB18_11D2_AF85_F59AEE2F743B__INCLUDED_

#if _MSC_VER > 1000
#pragma once
#endif // _MSC_VER > 1000


class theWheelDoc : public CDocument
{
protected: // create from serialization only
	theWheelDoc();
	DECLARE_DYNCREATE(theWheelDoc)

// Attributes
public:

// Operations
public:

// Overrides
	// ClassWizard generated virtual function overrides
	//{{AFX_VIRTUAL(theWheelDoc)
	public:
	virtual BOOL OnNewDocument();
	virtual void Serialize(CArchive& ar);
	//}}AFX_VIRTUAL

// Implementation
public:
	virtual ~theWheelDoc();
#ifdef _DEBUG
	virtual void AssertValid() const;
	virtual void Dump(CDumpContext& dc) const;
#endif

protected:

// Generated message map functions
protected:
	//{{AFX_MSG(theWheelDoc)
		// NOTE - the ClassWizard will add and remove member functions here.
		//    DO NOT EDIT what you see in these blocks of generated code !
	//}}AFX_MSG
	DECLARE_MESSAGE_MAP()
};

/////////////////////////////////////////////////////////////////////////////

//{{AFX_INSERT_LOCATION}}
// Microsoft Visual C++ will insert additional declarations immediately before the previous line.

#endif // !defined(AFX_THEWHEELDOC_H__FFE8CF0A_FB18_11D2_AF85_F59AEE2F743B__INCLUDED_)
