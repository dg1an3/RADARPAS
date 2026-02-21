// OrbDoc.h  Copyright (C) 1996 DG Lane

#ifndef OrbDoc_h
#define OrbDoc_h

#include "misc.h"

class OrbDoc : public COleClientDoc {
public:
	OrbDoc();
	virtual ~OrbDoc() { };
	DECLARE_SERIAL(OrbDoc);

	// Operations
	virtual void Serialize(CArchive& ar);	// overridden for document i/o
	virtual	void DeleteContents();
	void CreateItem(CString name);	// name = URL for object

	virtual	BOOL OnNewDocument();

	// Generated message map functions
	//{{AFX_MSG(OrbDoc)
	//}}AFX_MSG
	DECLARE_MESSAGE_MAP()
	
#ifdef _DEBUG
	virtual	void AssertValid() const;
	virtual	void Dump(CDumpContext& dc) const;
#endif
};	// class OrbDoc

#endif
