class wlLink {
		wlLink *prev, *next;
		wlDoc *targetDoc;
		float weight;

public:
		wlLink(wlDoc *to, float initWeight) {
				targetDoc = to;
				weight = initWeight;
				prev = next = (wlLink *)NULL;
		}
		
		~wlLink() { unlink(); }
    
    	wlDoc *getTarget()		{ return (this) ? targetDoc : (wlDoc *)NULL }
    	
    	float getWeight()		{ return (this) ? weight : 0 }
    	void setWeight(float toWeight)	{ if (this) weight = toWeight }
    
		wlLink *getNext()	{ return (this) ? next : (wlLink *)NULL }
		void setNext(wlLink *nextLink)	{ if (this) next = nextLink }
		
		wlLink *getPrev()	{ return (this) ? prev : (wlLink *)NULL }
		void setPrev(wlLink *prevLink)	{ if (this) prev = prevLink }
	
		void insertAfter(wlLink *prevLink) {
				if (this) {
						setPrev(prevLink);
						setNext(getPrev()->getNext());
						getPrev->setNext(this);
						getNext->setPrev(this);
				}
		}
	
		void unlink() {
				if (this) {
						getPrev()->setNext(getNext());
						getNext()->setPrev(getPrev());
						prev = next = (wlLink *)NULL;
				}
		}
};
