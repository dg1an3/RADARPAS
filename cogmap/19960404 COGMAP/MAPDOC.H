// mapdoc.h : interface of the MapDoc class
//
/////////////////////////////////////////////////////////////////////////////

class MapItem;
class StimResp;

class MapDoc : public COleClientDoc {
protected: // create from serialization only
	MapDoc();
	DECLARE_DYNCREATE(MapDoc)

// Attributes
public:
	// int numItems;	// number of items in COleDocument list
	MapItem *user;	// represents user
	CObArray srList;	// stimulus/response sets
	float temp;   	// temperature for annealing
	float totSqrtSpeed();	// total sqrt of speed of all objects
	int t;
	
	MapItem *getItemAt(int at);
	
// Operations
public:
    void dt(int timeSlices = 1);	// simulate time slices
    int newStim();    // generate new stimuli
	void recalcCorr();

// Implementation
public:
	virtual ~MapDoc();
	virtual void Serialize(CArchive& ar);	// overridden for document i/o
	virtual	void DeleteContents();
#ifdef _DEBUG
	virtual	void AssertValid() const;
	virtual	void Dump(CDumpContext& dc) const;
#endif
protected:
	virtual	BOOL OnNewDocument();

// Generated message map functions
protected:
	//{{AFX_MSG(MapDoc)
	afx_msg void OnInsertTxtr();
	afx_msg void OnInsertWord();
	afx_msg void OnInsertCa1d();
	afx_msg void OnViewInfo();
	//}}AFX_MSG
	DECLARE_MESSAGE_MAP()
};	// class MapDoc


class StimResp : public CObject {	// holds stimulus/response sets
public:
	StimResp(MapDoc *pDoc);
	DECLARE_DYNAMIC(StimResp)

// Attributes
	int s1, s2, s3;	// index of three stimulus objects
	int resp;		// response
	CTime when;		// when did the response occur

// Operations	
	~StimResp();
	void Serialize(CArchive& ar);
#ifdef _DEBUG
	void AssertValid() const;
    void Dump(CDumpContext& dc) const;
#endif //_DEBUG	
};	// StimResp


class MapItem : public CDocItem {
public:
	// MapItem();
	MapItem(MapDoc *pDoc);
	DECLARE_DYNAMIC(MapItem)
	
// Attributes
	float wx, wy, wz;	// position of item
	float dwx, dwy, dwz;	// dposition/dt
	float *corr;	// correlations with other items
	BOOL dirty;	// indicates item must be redrawn
	int lastUpdate;
	float sqrtSpeed(); // sqrt of the speed of the object
	float avgCorr();	// returns average correlation value for the object

// Operations
	~MapItem();    
	virtual BOOL Draw(CDC* pDC, LPCRECT lpBounds, 
		LPCRECT lpWBound = NULL, CDC *pFormatDC = NULL) { return TRUE; };
    void dt(int timeslices = 1);	// moves the object down its energy gradient

	virtual void Serialize(CArchive& ar); // for Native data
#ifdef _DEBUG
	virtual void AssertValid() const;
	virtual void Dump(CDumpContext& dc) const;
#endif //_DEBUG
};	// class MapItem


#define CLASS_WORDITEM 1

class WordItem : public MapItem {
public:
	WordItem(MapDoc *pDoc);
	WordItem(MapDoc *pDoc, CString initStr);
	DECLARE_DYNAMIC(WordItem)
	
// Attributes
	CString word;

// Operations	
	~WordItem();
	BOOL Draw(CDC* pDC, LPCRECT lpBounds,
		LPCRECT lpWBound = NULL, CDC *pFormatDC = NULL);
	void Serialize(CArchive& ar);
#ifdef _DEBUG
	void AssertValid() const;
    void Dump(CDumpContext& dc) const;
#endif //_DEBUG
};	// class WordItem

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
