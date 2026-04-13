// wlObject.h : header file
//
            
#include "MapDoc.h"

/////////////////////////////////////////////////////////////////////////////
// wlDoc document

class wlObject;

class wlObjectLink {
		wlObject *myTarget;
		float myWeight;

public:	
		wlObjectLink(wlObject *to, float weight = 1.0) {
				myTarget = to;
				myWeight = weight;
		}

		wlObject *getTarget() { return myTarget; }
		float getWeight() { return myWeight; }
		void setWeight(float weight) { myWeight = weight; }
		
		~wlObjectLink() { }
};
		
class wlObject : public CDocument {
public:
		char *rules;
		char *body;
    	int girth;

		CA1DItem it;	       
		
		DECLARE_SERIAL(wlDoc)
		
// protected:
		wlDoc();			// protected constructor used by dynamic creation

// Operations
public:
		void grow();
		BOOL Draw(CDC* pDC, LPCRECT lpBounds, LPCRECT lpWBound, CDC *pFormatDC);

// Implementation
// protected:
		virtual ~wlDoc();
		virtual void Serialize(CArchive& ar);	// overridden for document i/o
		virtual	BOOL OnNewDocument();

	// Generated message map functions
protected:
		//{{AFX_MSG(wlDoc)
				// NOTE - the ClassWizard will add and remove member functions here.
		//}}AFX_MSG
		DECLARE_MESSAGE_MAP()
};

