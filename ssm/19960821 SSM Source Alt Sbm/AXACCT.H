// AxAcct.h
// Copyright (C) 1985,1996 Derek G. Lane

#ifndef	__AXACCT_H__
#define	__AXACCT_H__

#include "stdafx.h"
#include "AxTrans.h"

class AxAcct : public CDocument {
public:
	AxAcct() { };
	AxAcct(int num, CString withName) {
		number = num;
		name = withName;
		AxTrans *newTrans = new AxTrans();
		transl.AddTail(newTrans);
	};
	virtual ~AxAcct() { };
	
	DECLARE_SERIAL(AxAcct)
	
// Attributes
	float balance();
	float aged(int NumDays = 30);
	// void addTrans(AxTrans forTrans);
	
// I/O
        void Serialize(CArchive& ar);
         CString LineEntry();	// returns one-line entry for account
         
// Attributes
	int number;
	CString name;
	CString address;
	CString city;
	CString phone;
	CObList transl;
};	// AxAcct

#endif	// __AXACCT_H__
