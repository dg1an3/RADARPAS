// FuelTran.h

#ifndef __FUELTRAN_H__
#define __FUELTRAN_H__

#include "AxTrans.h"

class FuelTrans : public AxTrans {
public: 
	FuelTrans();
	~FuelTrans();
	DECLARE_SERIAL(FuelTrans)
        
// I/O
	CString LineEntry() { return "1111\tDesc\t0.00"; };
	
// Attributes
	int shift;
        float readings[10];
};	// FuelTrans

#endif __FUELTRAN_H__
