// ca2d.h  interface of the CA2DItem class
//
/////////////////////////////////////////////////////////////////////////////

#include "eevorg2d.h"
#define CLASS_CA2DITEM 4

class CA2DItem : public MapItem
{	// 1 dimensional cellular automaton item
	
public:
	CA2DItem(MapDoc *pDoc);	// generate a random stimulus
	CA2DItem(MapDoc *pDoc, CA2DItem *fromParent);
	DECLARE_DYNAMIC(CA2DItem)

// Attributes
	Eevorg2d *eev;	// encapsulated eevorg
	CDC *compDC;	
	CBitmap *compBitmap;    // contains memory image of the object

	double Dist(CA2DItem& toItem); 
	int operator!=(CA2DItem& toItem);
	
	void genBitmap(CDC *pDC);	// generate the stimulus pattern
	
// Operations
	~CA2DItem();
	BOOL Draw(CDC* pDC, LPCRECT lpBounds,
		LPCRECT lpWBound = NULL, CDC *pFormatDC = NULL);
	void Serialize(CArchive& ar);
#ifdef _DEBUG
	void AssertValid() const;
    void Dump(CDumpContext& dc) const;
#endif //_DEBUG
};	// class CA2DItem
