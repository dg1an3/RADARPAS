// ca1d.h  interface of the CA1DItem class
//
/////////////////////////////////////////////////////////////////////////////

#include "eevorg.h"
#define CLASS_CA1DITEM 3

class CA1DItem : public MapItem
{	// 1 dimensional cellular automaton item
	
public:
	CA1DItem(MapDoc *pDoc);	// generate a random stimulus
	CA1DItem(MapDoc *pDoc, CA1DItem *fromParent);
	DECLARE_DYNAMIC(CA1DItem)

// Attributes
	Eevorg *eev;	// encapsulated eevorg
	CDC *compDC;	
	CBitmap *compBitmap;    // contains memory image of the object

	double Dist(CA1DItem& toItem); 
	int operator!=(CA1DItem& toItem);
	
	void genBitmap(CDC *pDC);	// generate the stimulus pattern
	
// Operations
	~CA1DItem();
	BOOL Draw(CDC* pDC, LPCRECT lpBounds,
		LPCRECT lpWBound = NULL, CDC *pFormatDC = NULL);
	void Serialize(CArchive& ar);
#ifdef _DEBUG
	void AssertValid() const;
    void Dump(CDumpContext& dc) const;
#endif //_DEBUG
};	// class CA1DItem


