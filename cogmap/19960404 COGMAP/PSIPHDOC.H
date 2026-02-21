// psiphdoc.h : interface of the CPsiphysDoc class
//
/////////////////////////////////////////////////////////////////////////////
    
#define RESP_PER_TRIAL 100

class Stim1 : public CObject
{	// Initial stimulus class of the form
	// cos(kx*x + ky*y + phi + A1*cos(kx1*x+ky1*y+phi2) + A2*cos(kx2*x+ky2*y+phi3))
	
public:
	Stim1();	// generate a random stimulus
	DECLARE_SERIAL(Stim1)

	double kx, ky, phi, A1, kx1, ky1, phi1, A2, kx2, ky2, phi2;
	double A11, kx11, ky11, phi11, A12, kx12, ky12, phi12;
	double A21, kx21, ky21, phi21, A22, kx22, ky22, phi22;
	char *data;
	
	double Dist(Stim1& toStim); 
	int operator!=(Stim1& toStim1);
	
	void Gen();	// generate the stimulus pattern
	void Draw(CDC *pDC, int atX, int atY, int size);

	virtual ~Stim1();
	virtual void Serialize(CArchive& ar);	// overridden for document i/o
};	// class Stim1

class CPsiphysDoc : public CDocument
{
protected: // create from serialization only
	CPsiphysDoc();
	DECLARE_DYNCREATE(CPsiphysDoc)

// Attributes
public:
	int randseed;	// random number generator seed
	Stim1 *stims[RESP_PER_TRIAL][3];
	int resp[RESP_PER_TRIAL];
	int nextResp;

// Operations
public:
	void GenNextStim();
	double EuclPredFit();
	
// Implementation
public:
	virtual ~CPsiphysDoc();
	virtual void Serialize(CArchive& ar);	// overridden for document i/o
#ifdef _DEBUG
	virtual	void AssertValid() const;
	virtual	void Dump(CDumpContext& dc) const;
#endif
protected:
	virtual	BOOL	OnNewDocument();

// Generated message map functions
protected:
	//{{AFX_MSG(CPsiphysDoc)
	afx_msg void OnFileComp();
	//}}AFX_MSG
	DECLARE_MESSAGE_MAP()
};

/////////////////////////////////////////////////////////////////////////////
