/////////////////////////////////////////////////////////////////////////////
// oDocument.h interface of the oDocument class
//

#if !defined _oDocument_h_
#define _oDocument_h_

#if _MSC_VER >= 1000
#pragma once
#endif // _MSC_VER >= 1000

#define HINT_UPDATE_WINDOW	0
#define HINT_UPDATE_ITEM	1

class oDocument : public COleDocument {

protected: // create from serialization only
	oDocument();
	DECLARE_DYNCREATE(oDocument)

// Attributes
public:

// Operations
public:

// Overrides
	// ClassWizard generated virtual function overrides
	//{{AFX_VIRTUAL(oDocument)
	public:
	virtual BOOL OnNewDocument();
	virtual void Serialize(CArchive& ar);
	//}}AFX_VIRTUAL

// Implementation
public:
	virtual ~oDocument();
#ifdef _DEBUG
	virtual void AssertValid() const;
	virtual void Dump(CDumpContext& dc) const;
#endif

protected:

// Generated message map functions
protected:
	//{{AFX_MSG(oDocument)
		// NOTE - the ClassWizard will add and remove member functions here.
		//    DO NOT EDIT what you see in these blocks of generated code !
	//}}AFX_MSG
	DECLARE_MESSAGE_MAP()
};

/////////////////////////////////////////////////////////////////////////////

//{{AFX_INSERT_LOCATION}}
// Microsoft Developer Studio will insert additional declarations immediately before the previous line.

#endif // !defined _oDocument_h
