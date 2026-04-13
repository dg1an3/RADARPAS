// wlObject.h  Copyright (C) 1996, 97  DG Lane

#ifndef _wlObject_h_
#define _wlObject_h_

class wlObjectLink;
            
class wlObject : 
	public CDocument 
	{
		CMapPtrToPtr myLinks;
		
	public:		
		wlObject();
		virtual ~wlObject();
		
		DECLARE_SERIAL(wlObject)
		virtual void Serialize(CArchive& ar);
		virtual	BOOL OnNewDocument();

		int getLinkCount() { return myLinks.GetCount(); }
		virtual POSITION getLinkStartPos();
		wlObjectLink *getNextLink(POSITION &pos);
		wlObjectLink *getLinkByTarget(wlObject *to);
		void addLink(wlObjectLink *newLink);
		BOOL delLink(wlObject *toObject);

		virtual void getAspectHint(long area, CRect *aspectRect);
		virtual BOOL Draw(CDC* pDC, LPCRECT lpBounds, int *nextScaleHint);

		//{{AFX_MSG(wlObject)
				// NOTE - the ClassWizard will add and remove member functions here.
		//}}AFX_MSG
		DECLARE_MESSAGE_MAP()		
	};

class wlObjectLink : 
	public CObject 
	{
		wlObject *myTarget;
		float myWeight;

	public:	
		wlObjectLink();
		wlObjectLink(wlObject *to, float weight = 1.0);
		void operator=(const wlObjectLink &other) ;
             
		DECLARE_SERIAL(wlObjectLink)
		virtual void Serialize(CArchive& ar);

		~wlObjectLink() { }
		
		wlObject *getTarget() { return myTarget; }
		void setTarget(wlObject *to) { myTarget = to; }
		float getWeight() { return myWeight; }
		void setWeight(float weight) { myWeight = weight; }
	};

#endif
