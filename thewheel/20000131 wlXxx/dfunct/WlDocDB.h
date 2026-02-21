// WlDocDB.h  Copyright (C) 1996 DG Lane
// Database of documents with link weight information

#ifndef _WLDOCDB_H_
#define _WLDOCDB_H_

#include "misc.h"

class WlDocDB : public COleClientDoc {
public:
	WlDocDB();
	virtual ~WlDocDB() { };
	DECLARE_SERIAL(WlDocDB);

	// Operations
	virtual void Serialize(CArchive& ar);	// overridden for document i/o
	virtual void DeleteContents();
	void CreateItem(CString name);	// name = URL for object

	virtual BOOL OnNewDocument();

	// Generated message map functions
	//{{AFX_MSG(WlDocDB)
	//}}AFX_MSG
	DECLARE_MESSAGE_MAP()
	
#ifdef _DEBUG
	virtual	void AssertValid() const;
	virtual	void Dump(CDumpContext& dc) const;
#endif
};	// WlDocDB

#endif
