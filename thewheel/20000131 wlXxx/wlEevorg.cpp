// wlEevorg.cpp  Copyright (C) 1994, 95, 96, 97  DG Lane

#include "stdafx.h"
#include "wlEevorg.h"

#define random(max) (int)((long)rand()*((long)(max))/(long)RAND_MAX)

wlEevorg::wlEevorg() : 
	wlObject() 
	{
		rule.Add(0); rule.Add(2); rule.Add(0); rule.Add(1); rule.Add(1);
		rule.Add(3); rule.Add(2); rule.Add(1); rule.Add(1); rule.Add(0);
		maxRule = rule.GetSize() - 1;
		maxVal = 3;

		CByteArray* firstGen = new CByteArray;
		ASSERT(firstGen != NULL);
		firstGen->Add(1);
		gen.Add(firstGen);
	
		parent = (wlEevorg *)NULL;
		ASSERT(maxRule >= 0);
	}

wlEevorg::wlEevorg(wlEevorg *fromParent, int mutFlag) : 
	wlObject()
	{	// copy constructor
		ASSERT(fromParent->maxRule >= 0);
		parent = fromParent;
		for (int count = 0; count < fromParent->rule.GetSize(); count++)
				rule.Add(fromParent->rule.GetAt(count));
		maxRule = fromParent->maxRule;
		maxVal = fromParent->maxVal;
		if (mutFlag) 
			{	// generate a single mutation
				int ruleNum = random(maxRule+1);
				ASSERT((ruleNum >= 0) && (ruleNum <= maxRule));
				int ruleVal;
				if (ruleNum > maxRule) 
					{
						ruleVal = 0;
						maxRule = ruleNum;
					} 
				else 
					{
						ASSERT(ruleNum < rule.GetSize());
						ruleVal = rule.GetAt(ruleNum);
					}
				ruleVal++; // += ((int)((long)rand()*(long)3/(long)RAND_MAX)-1);
				ruleVal = (ruleVal > 0) ? ruleVal : 0;
				while (ruleVal > maxVal) 
					{	// create three new rules
						rule.Add(0);
						rule.Add(0);
						rule.Add(0);
						maxVal++;
					}
				rule.SetAt(ruleNum, ruleVal); 
				ASSERT(ruleNum >= 0 && ruleNum < rule.GetSize());
			}
		CByteArray* firstGen = new CByteArray;   ASSERT(firstGen != NULL);
		firstGen->Add(1);
		gen.Add(firstGen);   ASSERT(maxRule >= 0);
		wlObjectLink *newLink = new wlObjectLink(this, 0.6f);
		fromParent->addLink(newLink);
		newLink = new wlObjectLink(fromParent, 0.5);
		addLink(newLink);
	}

POSITION
wlEevorg::getLinkStartPos() 
	{
		if (getLinkCount() <= 1)
				for (int count = 0; count < 3; count++)		// create three children
						wlEevorg *child = new wlEevorg(this, TRUE);

		POSITION pos = wlObject::getLinkStartPos();
		return pos;
	}

IMPLEMENT_SERIAL(wlEevorg, wlObject, 0)

void 
wlEevorg::Serialize(CArchive& ar) 
	{
		if (ar.IsStoring()) {
				ar << (WORD)maxVal;
				ar << (WORD)maxRule;
		} 
		else {
				ar >> (WORD&)maxVal;
				ar >> (WORD&)maxRule;
		}
		rule.Serialize(ar);
	}

int 
wlEevorg::nextGen() 
	{
		CByteArray *next = new CByteArray; 
		ASSERT(next != NULL);
		int nextNdx = gen.Add(next);
		CByteArray *prev = (CByteArray *)gen.GetAt(nextNdx-1);

		if (prev->GetSize() == 1) 
			{
				next->Add(rule.GetAt(prev->GetAt(0)));
				next->Add(rule.GetAt(prev->GetAt(0)));
			} 
		else 
			{
				next->Add(rule.GetAt(prev->GetAt(0)+2*prev->GetAt(1)));
				for (int n = 1; n < prev->GetSize()-1; n++)
						next->Add(rule.GetAt(prev->GetAt(n-1)+prev->GetAt(n)+prev->GetAt(n+1)));
				next->Add(rule.GetAt(prev->GetAt(n-1)+prev->GetAt(n)));
				next->Add(rule.GetAt(prev->GetAt(n)));
			}
		return nextNdx;
	}

BOOL 
wlEevorg::Draw(CDC* pDC, LPCRECT lpBounds, int *nextScaleHint) 
	{
		int atX = (lpBounds->right - lpBounds->left)/2;
		int atY = lpBounds->top;
		int hgt = lpBounds->bottom - lpBounds->top;
		if (hgt >= 2) 
			{
				CByteArray *curGen;
				int c, at;
				for (int n = 0; n < hgt;) 
					{ 
						ASSERT(n < gen.GetSize());
						curGen = getGen(n);
						for (int m = curGen->GetSize()-1; m > 0; m--) 
							{
								c = curGen->GetAt(m)*64/maxVal;
								at = (int)((float)m*(1.0-(float)n*(float)n*(float)n/	// compute distortion
					     				((float)hgt*(float)hgt*(float)hgt)));
								pDC->SetPixel(atX+at, atY+n, RGB(c*4,c,c*2));
								pDC->SetPixel(atX-at, atY+n, RGB(c*4,c,c*2));
							}		
						pDC->SetPixel(atX, atY+n, RGB(c*4,c,c*2));		
						if (++n >= numOfGen())
								n = nextGen();
					}
				*nextScaleHint = hgt/2;
			}
		else 
			*nextScaleHint = 1;
		return TRUE;
	}

wlEevorg::~wlEevorg() 
	{
		for (int count = 0; count < gen.GetSize(); count++)
				delete (CByteArray *)gen.GetAt(count);
	}

#ifdef _DEBUG

void wlEevorg::AssertValid() const 
	{
		ASSERT(maxRule > 0);
		ASSERT(maxRule < rule.GetSize());
		CObject::AssertValid();
	}

void wlEevorg::Dump(CDumpContext& dc) const 
	{
		CObject::Dump(dc);
	}
	
#endif

