// AxTrans.h
// Copyright (C) 1985,1996 Derek G. Lane

#ifndef __AXTRANS_H__
#define __AXTRANS_H__

#include "stdafx.h"

class AxTrans : public CObject {
public: 
	AxTrans();
	~AxTrans() {};
	
	DECLARE_SERIAL(AxTrans)
        
// I/O
	CString LineEntry() { return "1111\tDesc\t0.00"; };
	
// Attributes
	CTime date;
	CString description;
        float amount;
        float balance;
        CString category;	// acct# if a transfer
};	// AxTrans
  
#endif	// __AXTRANS_H__