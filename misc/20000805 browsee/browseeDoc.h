// browseeDoc.h : interface of the CBrowseeDoc class
//
/////////////////////////////////////////////////////////////////////////////

#if !defined(AFX_BROWSEEDOC_H__9ADEF12C_6AD4_11D4_AF85_00C0F05A20CE__INCLUDED_)
#define AFX_BROWSEEDOC_H__9ADEF12C_6AD4_11D4_AF85_00C0F05A20CE__INCLUDED_

#if _MSC_VER > 1000
#pragma once
#endif // _MSC_VER > 1000


class CBrowseeDoc : public CDocument
{
protected: // create from serialization only
	CBrowseeDoc();
	DECLARE_DYNCREATE(CBrowseeDoc)

// Attributes
public:

// Operations
public:

// Overrides
	// ClassWizard generated virtual function overrides
	//{{AFX_VIRTUAL(CBrowseeDoc)
	public:
	virtual BOOL OnNewDocument();
	virtual void Serialize(CArchive& ar);
	//}}AFX_VIRTUAL

// Implementation
public:
	virtual ~CBrowseeDoc();
#ifdef _DEBUG
	virtual void AssertValid() const;
	virtual void Dump(CDumpContext& dc) const;
#endif

protected:

// Generated message map functions
protected:
	//{{AFX_MSG(CBrowseeDoc)
		// NOTE - the ClassWizard will add and remove member functions here.
		//    DO NOT EDIT what you see in these blocks of generated code !
	//}}AFX_MSG
	DECLARE_MESSAGE_MAP()
};

/////////////////////////////////////////////////////////////////////////////

//{{AFX_INSERT_LOCATION}}
// Microsoft Visual C++ will insert additional declarations immediately before the previous line.

#endif // !defined(AFX_BROWSEEDOC_H__9ADEF12C_6AD4_11D4_AF85_00C0F05A20CE__INCLUDED_)
