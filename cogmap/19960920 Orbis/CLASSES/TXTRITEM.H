// txtritem.h : interface of the TxtrItem class
//
/////////////////////////////////////////////////////////////////////////////

#define CLASS_TXTRITEM 2

class TxtrItem : public MapItem
{	// Initial texture stimulus class of the form
	// cos(kx*x + ky*y + phi + A1*cos(kx1*x+ky1*y+phi2) + A2*cos(kx2*x+ky2*y+phi3))
	
public:
	TxtrItem(MapDoc *pDoc);	// generate a random stimulus
	DECLARE_DYNAMIC(TxtrItem)

// Attributes
	double kx, ky, phi, A1, kx1, ky1, phi1, A2, kx2, ky2, phi2;
	double A11, kx11, ky11, phi11, A12, kx12, ky12, phi12;
	double A21, kx21, ky21, phi21, A22, kx22, ky22, phi22;
	CDC *compDC;	
	CBitmap *compBitmap;    // contains memory image of the object

	double Dist(TxtrItem& toTxtrItem); 
	int operator!=(TxtrItem& toTxtrItem);
	
	void genBitmap(CDC *pDC);	// generate the stimulus pattern

// Operations
	~TxtrItem();
	BOOL Draw(CDC* pDC, LPCRECT lpBounds,
		LPCRECT lpWBound = NULL, CDC *pFormatDC = NULL);
	void Serialize(CArchive& ar);
#ifdef _DEBUG
	void AssertValid() const;
    void Dump(CDumpContext& dc) const;
#endif //_DEBUG
};	// class TxtrItem


