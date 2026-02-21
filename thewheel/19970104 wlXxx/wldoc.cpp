// WlDoc.cpp  (C) 1996 DG Lane

#include "stdafx.h"
#include "misc.h"
#include <math.h>
#include "theWheel.h"
#include "WlDocDB.h"
#include "WlDoc.h"
                 
IMPLEMENT_SERIAL(WlDoc, CDocItem, 1);	// schema 1

WlDoc::WlDoc() {
	s = INVALID_SOCKET;
	data = "";
	url = "";
	host = "";
	view = NULL;
}	// WlDoc::WlDoc

WlDoc::WlDoc(CString withURL) { 
	s = INVALID_SOCKET;
	ASSERT(data == "");
	ParseURL(withURL);
	ASSERT(ext != "");
	ASSERT(url != "");
	view = new ItemView;
	((ItemView *)view)->client = this;
	Fetch();
}	// WlDoc::WlDoc

WlDoc::~WlDoc() {
	ASSERT(this != NULL);
	((OrbDoc *)GetDocument())->RemoveItem(this);
}	// WlDoc::~WlDoc

void WlDoc::Serialize(CArchive& ar) {
	// if (ar.IsStoring()) {
	// } else {
	// }	// if
}	// WlDoc::Serialize

void WlDoc::ParseURL(CString URL) {
	int at = URL.Find(":");
	ASSERT(at >= 0);
	CString servName = URL.Left(at);
	ASSERT(servName.GetLength() >= 3);
	URL = URL.Mid(at+3);	// 3 skips over ???://???
	ASSERT(URL.GetLength() > 0);
	if (servName == "http") {
		service = http;
		at = URL.Find("/");
		ASSERT(at > 5);
		host = URL.Left(at);
		url = URL.Mid(at);
		ASSERT(url.GetLength() > 0);
	} else if (servName == "file") {
		service = file;
		host = "";	// host is this computer
		url = URL;
	} else {
		TRACE("unknown	service request\n");
		ASSERT(0);
	}	// if
	ext = URL.Mid(URL.ReverseFind('.')+1);
	ASSERT(ext.GetLength() > 0);
}	// WlDoc::ParseURL

void WlDoc::Fetch() {
	switch (service) {
		case http  :	
			view->PostMessage(WM_SOCKINITFETCH);
			data = "Getting ";
			data += host;
			data += " Internet address...\n";
			view->Invalidate();
			break;
		case file  :
			TRY {
				CFile inFile(url, CFile::modeRead);
				UINT length = (UINT)inFile.GetLength();
				UINT result = inFile.Read(data.GetBuffer(length), length);
				data.ReleaseBuffer();
				inFile.Close();
				((ItemView *)view)->Process();
			} CATCH(CFileException, ex) {
				TRACE("File exception!\n");
			} END_CATCH;
			break;
		case mem  :
			// TODO: initialize structure
			break;
		default  :
			ASSERT(0);
			break;
	}	// switch
}	// OrbItem::Fetch

void OrbItem::Process() { }

#ifdef _DEBUG
void OrbItem::AssertValid() const { 
}	// OrbItem::AssertValid

void OrbItem::Dump(CDumpContext& dc) const {
}	// OrbItem::Dump
#endif //_DEBUG

