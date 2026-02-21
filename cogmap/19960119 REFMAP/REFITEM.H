// refitem.h : header file
//

/////////////////////////////////////////////////////////////////////////////
// CRefItem document

class CRefItem : public CObject
{
	DECLARE_SERIAL(CRefItem)
public:
	CRefItem();

// Attributes
public:
	CRect rect;
	int fontSize;
	CString id;
	CString authors;
	CString institution;
	CString title;
	CString source;
	CString MeSH;
	CString abstract;
	CString reg_num;
	CObList ref;

	CString url;	// source of HTML
	CString fileName;	// local copy of HTML file

// Operations
public:
    double corr(CRefItem *withItem);
    
// Implementation
protected:
	virtual ~CRefItem();
	virtual void Serialize(CArchive& ar);	// overridden for document i/o
	
public:
	BOOL OnDraw(CDC *pDC, BOOL bSelected);
};

