// wlObject.h  Copyright (C) 1996, 97  DG Lane

#ifndef _wlObject_h_
#define _wlObject_h_
            
class wlObject;

class wlObjectLink : public CObject {
		wlObject *myTarget;
		float myWeight;

	public:	
		wlObjectLink(wlObject *to = (wlObject *)NULL, float weight = 1.0);

		wlObject *getTarget() { return myTarget; }
		void setTarget(wlObject *to) { myTarget = to; }
		float getWeight() { return myWeight; }
		void setWeight(float weight) { myWeight = weight; }

		void operator=(const wlObjectLink &other) {
				myTarget = other.myTarget;
				myWeight = other.myWeight;
		}
				
		DECLARE_SERIAL(wlObjectLink)
		virtual void Serialize(CArchive& ar);
		
		~wlObjectLink() { }
};

class wlObject : public CDocument {
		int numLinks;
		wlObjectLink *myLink;
		
	public:		
		wlObject();
		virtual	BOOL OnNewDocument();

		int getNumLinks() { return numLinks; }
		void addLink(wlObject *toObject, float weight);
		const wlObjectLink *getLink(int number) { 
				return (0 <= number  && number < numLinks) ? &myLink[number] : (wlObjectLink *)NULL; 
		}
		
		DECLARE_SERIAL(wlObject)
		virtual void Serialize(CArchive& ar);
		
		virtual void getAspectHint(long area, CRect *aspectRect);
		virtual BOOL Draw(CDC* pDC, LPCRECT lpBounds, int *nextScaleHint);

		virtual ~wlObject() { }

		//{{AFX_MSG(wlObject)
				// NOTE - the ClassWizard will add and remove member functions here.
		//}}AFX_MSG
		DECLARE_MESSAGE_MAP()		
};

#endif
