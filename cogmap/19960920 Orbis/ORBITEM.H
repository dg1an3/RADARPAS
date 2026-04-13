// OrbItem.h  Copyright (C) 1996 DG Lane

#ifndef __ORBITEM_H__
#define __ORBITEM_H__

#include "misc.h"
#include "winsock.h"

class OrbItem : public CDocItem {
public:
	OrbItem();
	OrbItem(CString url);
	virtual ~OrbItem();
	DECLARE_SERIAL(OrbItem)

	// Operations
	void ParseURL(CString URL);
	void Fetch();
	void CreateView();
	// TODO: Move Draw to view class
	virtual BOOL Draw(CDC* pDC, LPCRECT lpBounds, 
		LPCRECT lpWBound = NULL, CDC *pFormatDC = NULL) { return TRUE; };
	virtual void Process();
	virtual void Serialize(CArchive& ar); // for Native data

      // Member variables
      enum {ok, badURL, socketError, timeout};
	int state;
	CWnd *view;
	enum {mem, file, http};	// service enumeration	
      int service;
      CString host, url, ext, data;
	SOCKET s;
	struct sockaddr_in SockAddr;
	char *hostData;

#ifdef _DEBUG
	virtual void AssertValid() const;
	virtual void Dump(CDumpContext& dc) const;
#endif
};	// class OrbItem

#endif
