// Eevorg2d.cpp : implementation of the Eevorg class
//

#include "stdafx.h"
// #include "winorg.h"
#include <math.h>

#include "eevorg2d.h"

#ifdef _DEBUG
#undef THIS_FILE
static char BASED_CODE THIS_FILE[] = __FILE__;
#endif

#define random(max) (int)((long)rand()*((long)(max))/(long)RAND_MAX)

/////////////////////////////////////////////////////////////////////////////
// Eevorg2D

IMPLEMENT_SERIAL(Eevorg2d, CObject, 0)

/////////////////////////////////////////////////////////////////////////////
// Eevorg2d construction/destruction

Eevorg2d::Eevorg2d()
{	// default constructor 2d rules 1 rule = 10 states
	rule.Add(0); rule.Add(1); rule.Add(0); rule.Add(1); rule.Add(1);
	rule.Add(0); rule.Add(0); rule.Add(1); rule.Add(1); rule.Add(0);
	maxRule = rule.GetSize()-1;
	maxVal = 3;
	score = 0;
	
	CByteArray* firstGen = new CByteArray; ASSERT(firstGen != NULL);
	firstGen->Add(1);
	genQuad.Add(firstGen);
	
	parent = (Eevorg2d *)NULL;
	ASSERT(maxRule >= 0);
}	// Eevorg2d::Eevorg2d

Eevorg2d::Eevorg2d(Eevorg2d *fromParent, int mutFlag)
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
		} else
		{
			ASSERT(ruleNum < rule.GetSize());
			ruleVal = rule.GetAt(ruleNum);
		}	// if 
			
		ruleVal++; // += ((int)((long)rand()*(long)3/(long)RAND_MAX)-1);
		ruleVal = (ruleVal > 0) ? ruleVal : 0;
		while (ruleVal > maxVal)
		{	// create three new rules
			rule.Add(0);
			rule.Add(0);
			rule.Add(0);
			maxVal++;
		}	// while         
		rule.SetAt(ruleNum, ruleVal);
		ASSERT(ruleNum >= 0 && ruleNum < rule.GetSize());
	}	// if

	CByteArray* firstGen = new CByteArray; ASSERT(firstGen != NULL);
	firstGen->Add(1);
	genQuad.Add(firstGen);
	
	score = 0;
	ASSERT(maxRule >= 0);
}	// Eevorg2d::Eevorg2d

Eevorg2d::~Eevorg2d()
{
	for (int count = 0; count < genQuad.GetSize(); count++)
		((CByteArray *)genQuad.GetAt(count))->RemoveAll();
	genQuad.RemoveAll();
	rule.RemoveAll();
}	// Eevorg2d::~Eevorg2d


void put2d(CByteArray *into, int size, int atx, int aty, char val) {
	// determine if the coordinates are within range
	ASSERT(atx >= 0);  ASSERT(aty >= 0);
	while ((atx >= size) || (aty >= size)) {
		// expand the array
		CByteArray *newArray = new CByteArray;
		int intoCount = 0;
		for (int j = 0; j < size; j++) {
			// for each line
			for (int i = 0; i < size; i++) {
				// for each element
				newArray->Add(into->GetAt(intoCount));
				intoCount++;
			}
			newArray->Add(0);
		}
		for (int i = 0; i <= size; i++)
			newArray->Add(0);
		delete into;
		into = newArray;
		size++;
	}	// while
	into->SetAt(aty*size+atx, val);
}	// put2d

int get2d(CByteArray *from, int size, int atx, int aty) {
	// ASSERT(aty < size); ASSERT(atx < size);
	if (atx < 0) atx = -atx;
	if (aty < 0) aty = -aty;
	// ASSERT(atx >= 0); ASSERT(aty >= 0);
	if ((atx < size) && (aty < size))
		return from->GetAt(aty*size + atx);
	else
		return 0;
}	// get2d

int Eevorg2d::nextGen()
{	// compute next generation and return
	CByteArray *next = new CByteArray; 
	int nextSize = (int)sqrt((double)(next->GetSize()+1));
	ASSERT(next != NULL);
	int nextNdx = genQuad.Add(next);
	int nextVal;
	CByteArray *prev = (CByteArray *)genQuad.GetAt(nextNdx-1);
	int prevSize = (int)sqrt((double)(prev->GetSize()+1));
	
	if (prev->GetSize() == 1) {
	    nextVal = rule.GetAt(prev->GetAt(0));
		put2d(next, nextSize, 0, 0, nextVal);
		put2d(next, nextSize, 0, 1, nextVal);
		put2d(next, nextSize, 1, 0, nextVal);
		put2d(next, nextSize, 1, 1, nextVal);
	} else {
		nextVal = rule.GetAt(get2d(prev, prevSize, 0, 0) + 
						   2*get2d(prev, prevSize, 0, 1) +
						   2*get2d(prev, prevSize, 1, 0) +
			               4*get2d(prev, prevSize, 1, 1));
		put2d(next, nextSize, 0, 0, nextVal);
		
		for (int i = 1; i <= prevSize; i++) {
			// across the first row
			nextVal = rule.GetAt(get2d(prev, prevSize, i-1, 0) +
			                     get2d(prev, prevSize, i,   0) +
			                     get2d(prev, prevSize, i+1, 0) +
			                   2*get2d(prev, prevSize, i-1, 1) +
			                   2*get2d(prev, prevSize, i,   1) +
			                   2*get2d(prev, prevSize, i+1, 1));
			put2d(next, nextSize, i, 0, nextVal);	 
		}
		for (int j = 1; j <= prevSize; j++) {
			// first element of each row
			nextVal = rule.GetAt(get2d(prev, prevSize, 0, j-1) +
			                   2*get2d(prev, prevSize, 1, j-1) +
			                     get2d(prev, prevSize, 0, j) +
			                   2*get2d(prev, prevSize, 1, j) +
			                     get2d(prev, prevSize, 0, j+1) +
			                   2*get2d(prev, prevSize, 1, j+1));
			put2d(next, nextSize, 0, j, nextVal);
			// for each row
			for (int i = 1; i <= prevSize; i++) {
				nextVal = rule.GetAt(get2d(prev, prevSize, i-1, j-1) +
			                         get2d(prev, prevSize, i,   j-1) +
			                         get2d(prev, prevSize, i+1, j-1) +
			                         get2d(prev, prevSize, i-1, j) +
			                     	 get2d(prev, prevSize, i,   j) +
			                         get2d(prev, prevSize, i+1, j) +
			                         get2d(prev, prevSize, i-1, j+1) +
			                     	 get2d(prev, prevSize, i,   j+1) +
			                         get2d(prev, prevSize, i+1, j+1));
			    put2d(next, nextSize, i, j, nextVal);
			}	// for
		}	// for
	}	// if
	
	return nextNdx;
}	// Eevorg2d::nextGen

void Eevorg2d::drawAt(CDC* pDC, int atX, int atY, int hgt)
{   
	if (hgt < 2)
		return;

	CByteArray *curGen;
	int c, at;
	for (int n = 0; n < hgt;)
	{ 
		ASSERT(n < genQuad.GetSize());
		curGen = getGen(n);
		for (int m = curGen->GetSize()-1; m > 0; m--)
		{                           
			c = curGen->GetAt(m)*64/maxVal;
			at = (int)((float)m*(1.0-(float)n*(float)n*(float)n/
			     ((float)hgt*(float)hgt*(float)hgt)));
			pDC->SetPixel(atX+at, atY+n, RGB(c*4,c,c*2));
			pDC->SetPixel(atX-at, atY+n, RGB(c*4,c,c*2));
		}	// for
		
		pDC->SetPixel(atX, atY+n, RGB(c*4,c,c*2));
		
		if (++n >= numOfGen())
			n = nextGen();
	}	// for
}	// Eevorg2d::drawAt


/////////////////////////////////////////////////////////////////////////////
// Eevorg2d serialization

void Eevorg2d::Serialize(CArchive& ar)
{
	if (ar.IsStoring())
	{	// write member variables to archive
		ar << (WORD)maxVal;
		ar << (WORD)maxRule;
		ar << (WORD)score;
		rule.Serialize(ar);
	} else
	{	// read member variables from archive
		ar >> (WORD&)maxVal;
		ar >> (WORD&)maxRule;
		ar >> (WORD&)score;
		rule.Serialize(ar);
	}	// if
}	// Eevorg2d::Serialize

/////////////////////////////////////////////////////////////////////////////
// Eevorg2d diagnostics

#ifdef _DEBUG
void Eevorg2d::AssertValid() const
{   
	ASSERT((maxRule > 0) && (maxRule < rule.GetSize()));
	CObject::AssertValid();
}   // Eevorg2d::AssertValid

void Eevorg2d::Dump(CDumpContext& dc) const
{
	CObject::Dump(dc);
}

#endif //_DEBUG

/////////////////////////////////////////////////////////////////////////////
// Eevorg2d commands
