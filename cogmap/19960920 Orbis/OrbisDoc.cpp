// OrbDoc.cpp  Copyright (C) 1996 DG Lane

#include "stdafx.h"
#include <math.h>
#include <time.h>
#include "misc.h"

#include "Orbis.h"
#include "OrbDoc.h" 
#include "HtmlDoc.h"

#ifdef _DEBUG
#undef THIS_FILE
static char BASED_CODE THIS_FILE[] = __FILE__;
#endif

IMPLEMENT_SERIAL(OrbDoc, COleClientDoc, 1)

BEGIN_MESSAGE_MAP(OrbDoc, COleClientDoc)
	//{{AFX_MSG_MAP(OrbDoc)
	//}}AFX_MSG_MAP
END_MESSAGE_MAP()

OrbDoc::OrbDoc() {
#ifdef _DEBUG
	TRY {
		// CreateItem("file://c:/derek/basket.in/raysmith/example.txt"); 
		CreateItem("file://c:/lcc/orbis/source/sample.htm");
		// CreateItem("http://www.w3.org/pub/WWW/TheProject.html");
		// CreateItem("http://www.wustl.edu/index.html");  
	} CATCH(CException, ex) {
		TRACE0("Exception on create!\n");
	} END_CATCH;
#endif // _DEBUG
}   // OrbDoc::OrbDoc

void OrbDoc::CreateItem(CString name) {
	CString ext = name.Mid(name.ReverseFind('.')+1);
	OrbItem *newItem;
	if ((ext == "html") || (ext == "htm"))
		newItem = new HtmlDoc();
	else
		ASSERT(0);
	// else if (ext == "txt")
	//	AddItem(new TextDoc(name));
	newItem->view = new ItemView;
	((ItemView *)newItem->view)->client = newItem;
	newItem->ParseURL(name);
	newItem->Fetch();
}	// OrbDoc::CreateItem

BOOL OrbDoc::OnNewDocument() {
	if (!COleClientDoc::OnNewDocument())
		return FALSE;
	return TRUE;
}	// OrbDoc::OnNewDocument

void OrbDoc::Serialize(CArchive& ar) {
	if (ar.IsStoring()) {
		POSITION pos;
		ar << (WORD)m_docItemList.GetCount();
		for (pos = GetStartPosition(); pos != NULL; ) {
			OrbItem *item = (OrbItem *)GetNextItem(pos);
			item->Serialize(ar);
		}	// for
	} else {
		WORD count;
		ar >> count;	// number of items in document
		for (; count > 0; count--) {
			OrbItem *item = new OrbItem;
			item->Serialize(ar);
			AddItem(item);
		}	// rof
	}	// if
}	// OrbDoc::Serialize

void OrbDoc::DeleteContents() {
	// TODO: add additional cleanup before doc-items are deleted
	COleClientDoc::DeleteContents();	// delete doc-items
}	// OrbDoc::DeleteContents

#ifdef _DEBUG
void OrbDoc::AssertValid() const {
	COleClientDoc::AssertValid();
}	// OrbDoc::AssertValid

void OrbDoc::Dump(CDumpContext& dc) const {
	COleClientDoc::Dump(dc);
}	// OrbDoc::Dump
#endif //_DEBUG
