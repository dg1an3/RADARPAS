// wlEevorg.h  Copyright (C) 1994, 95, 96, 97  DG Lane
                                         
#ifndef _wlEevorg_h_
#define _wlEevorg_h_
                                         
#include "wlObject.h"

class wlEevorg : public wlObject {
		wlEevorg *parent;
		CByteArray rule;
		int maxRule;
		CObArray gen;
		int maxVal;
		
	public:
		wlEevorg();
		wlEevorg(wlEevorg *parent, int mutFlag = TRUE);

		virtual POSITION getLinkStartPos();

		int numOfGen()  { return gen.GetSize(); }
	    CByteArray *getGen(int forGen) { return (CByteArray *)gen.GetAt(forGen); }
	    
	    int nextGen();
	    
		// virtual CRect *getAspectHint(int area);
		virtual BOOL Draw(CDC* pDC, LPCRECT lpBounds, int *nextScaleHint);

		DECLARE_SERIAL(wlEevorg)
		void Serialize(CArchive& ar);

		virtual ~wlEevorg();
		
#ifdef _DEBUG
		void AssertValid() const;
    	void Dump(CDumpContext& dc) const;
#endif
};

#endif
