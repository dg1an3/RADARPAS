// TriadCmp.h  Copyright (C) 1996 DG Lane
////////////////////////////////////////////////////////////////////

#ifndef __TRIADCMP_H__
#define __TRIADCMP_H__

#include "MapDoc.h"

class StimResp : public CObject {
public:
	StimResp(MapDoc *pDoc);
	virtual ~StimResp() { }
	
	DECLARE_DYNAMIC(StimResp)

// Operations	
	void Serialize(CArchive& ar);
	
#ifdef _DEBUG
	void AssertValid() const { }
    void Dump(CDumpContext& dc) const { }
#endif //_DEBUG	

// Attributes
	int s1, s2, s3;	// index of three stimulus objects
	int resp;		// response
	CTime when;		// when did the response occur
};	// StimResp

#endif  // __TRIADCMP_H__
