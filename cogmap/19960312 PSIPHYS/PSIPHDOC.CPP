// psiphdoc.cpp : implementation of the CPsiphysDoc class
//

#include "stdafx.h"
#include "psiphys.h"
#include <math.h>

#include "psiphdoc.h"

#ifdef _DEBUG
#undef THIS_FILE
static char BASED_CODE THIS_FILE[] = __FILE__;
#endif
 
/////////////////////////////////////////////////////////////////////////////
// Stim1 

double Rnd(double minmax)
{
	return (double)rand()*minmax/(double)RAND_MAX;
}

#define pi 3.141593
         
IMPLEMENT_SERIAL(Stim1, CObject, 2)

Stim1::Stim1()
{
	kx = Rnd(6.0); ky = Rnd(6.0); phi = Rnd(pi*2); 
	A1 = Rnd(6.0)-3.0; kx1 = Rnd(6.0); ky1 = Rnd(6.0); phi1 = Rnd(pi*2);
	A11 = Rnd(6.0)-3.0; kx11 = Rnd(6.0); ky11 = Rnd(6.0); phi11 = Rnd(pi*2);
	A12 = Rnd(6.0)-3.0; kx12 = Rnd(6.0); ky12 = Rnd(6.0); phi12 = Rnd(pi*2);
	A2 = Rnd(6.0)-3.0; kx2 = Rnd(6.0); ky2 = Rnd(6.0); phi2 = Rnd(pi*2);
	A21 = Rnd(6.0)-3.0; kx21 = Rnd(6.0); ky21 = Rnd(6.0); phi21 = Rnd(pi*2);
	A22 = Rnd(6.0)-3.0; kx22 = Rnd(6.0); ky22 = Rnd(6.0); phi22 = Rnd(pi*2);
	data = NULL;
}	// Stim1::Stim1

Stim1::~Stim1()
{
	delete [] data;
}	// Stim1::~Stim1
 
int Stim1::operator!=(Stim1& toStim)
{	// NEED TO UPDATE FOR NEW STIMULI
	return ((kx != toStim.kx) || (ky != toStim.ky) || (phi != toStim.phi) ||
		(A1 != toStim.A1) || (kx1 != toStim.kx1) || (ky1 != toStim.ky1) || 
			(phi1 != toStim.phi1) ||
		(A2 != toStim.A2) || (kx2 != toStim.kx2) || (ky2 != toStim.ky2) || 
			(phi2 != toStim.phi2));
}	// Stim1::operator!=
		
double Stim1::Dist(Stim1& toStim)
{	// NEED TO UPDATE FOR NEW STIMULI
	return 	(sqrt(kx*toStim.kx + ky*toStim.ky + phi*toStim.phi +
		A1*toStim.A1 + kx1*toStim.kx1 + ky1*toStim.ky1 + phi1*toStim.phi1 +
		A2*toStim.A2 + kx2*toStim.kx2 + ky2*toStim.ky2 + phi2*toStim.phi2));
}	// Stim1::Dist

void Stim1::Gen()
{
	// generate stimulus
	data = new char[10000];
	ASSERT(data != NULL);
	int atx, aty;
	double x, y;
	for (atx = 0; atx < 100; atx++)
		for (aty = 0; aty < 100; aty++)
		{         
			x = ((double)atx-50.0)*(pi/50.0);
			y = ((double)aty-50.0)*(pi/50.0);
			data[atx+aty*100] = (char)(128.0+
				128.0*exp(-(x*x+y*y)/2.0)*
				cos(kx*x + ky*y + phi +
					A1*cos(kx1*x + ky1*y + phi1 +
						A11*cos(kx11*x + ky11*y + phi11) +
						A12*cos(kx12*x + ky12*y + phi12)) +
					A2*cos(kx2*x + ky2*y + phi2 +
						A21*cos(kx21*x + ky21*y + phi21) +
						A22*cos(kx22*x + ky22*y + phi22))));
		}	// for
}	// Stim1::Gen

void Stim1::Draw(CDC *pDC, int cx, int cy, int size)
{   
	// ASSERT(data != NULL);
	if (data == NULL)
		Gen();
	int atx, aty;
	for (atx = 0; atx < 100; atx++)
		for (aty = 0; aty < 100; aty++)
		{
			pDC->SetPixel(atx+cx-50, aty+cy-50, 
				RGB(0, data[atx+aty*100], 0));
		}
}	// Stim1::Draw

void Stim1::Serialize(CArchive& ar)
{
	if (ar.IsStoring())
	{
		ar << kx << ky << phi;
		ar << A1 << kx1 << ky1 << phi1;
		ar << A11 << kx11 << ky11 << phi11;
		ar << A12 << kx12 << ky12 << phi12;
		ar << A2 << kx2 << ky2 << phi2;
		ar << A21 << kx21 << ky21 << phi21;
		ar << A22 << kx22 << ky22 << phi22;
	}
	else
	{
		ar >> kx >> ky >> phi;
		ar >> A1 >> kx1 >> ky1 >> phi1;
		ar >> A11 >> kx11 >> ky11 >> phi11;
		ar >> A12 >> kx12 >> ky12 >> phi12;
		ar >> A2 >> kx2 >> ky2 >> phi2;
		ar >> A21 >> kx21 >> ky21 >> phi21;
		ar >> A22 >> kx22 >> ky22 >> phi22;
	}
}


/////////////////////////////////////////////////////////////////////////////
// CPsiphysDoc

IMPLEMENT_DYNCREATE(CPsiphysDoc, CDocument)

BEGIN_MESSAGE_MAP(CPsiphysDoc, CDocument)
	//{{AFX_MSG_MAP(CPsiphysDoc)
	ON_COMMAND(ID_FILE_COMP, OnFileComp)
	//}}AFX_MSG_MAP
END_MESSAGE_MAP()

/////////////////////////////////////////////////////////////////////////////
// CPsiphysDoc construction/destruction

CPsiphysDoc::CPsiphysDoc()
{
	// nextResp = -1;
	// GenNextStim();
}	// CPsiphysDoc::CPsiphysDoc

CPsiphysDoc::~CPsiphysDoc()
{
}	// CPsiphysDoc::~CPsiphysDoc

void CPsiphysDoc::GenNextStim()
{	
	if (nextResp < RESP_PER_TRIAL-1)
	{
		if (nextResp >= 0)
		{                                      
		    ASSERT(stims[nextResp][0]->data != NULL);
		    delete [] (stims[nextResp][0]->data);
		    ASSERT(stims[nextResp][1]->data != NULL);
		    delete [] (stims[nextResp][1]->data);
	 		ASSERT(stims[nextResp][2]->data != NULL);
			delete [] (stims[nextResp][2]->data);
		}	// if
		nextResp++;
		stims[nextResp][0] = new Stim1(); 
		ASSERT(stims[nextResp][0] != NULL);
		stims[nextResp][0]->Gen();
		stims[nextResp][1] = new Stim1();
		ASSERT(stims[nextResp][1] != NULL);
		stims[nextResp][1]->Gen();
		stims[nextResp][2] = new Stim1();
		ASSERT(stims[nextResp][2] != NULL);
		stims[nextResp][2]->Gen();
		resp[nextResp] = -1;
		UpdateAllViews(NULL);
	} else
	{
		char result[100];
		sprintf(result, "Trial completed. Euclidean predictor %4.0lf", 
			EuclPredFit());
		AfxMessageBox(result);
	}	// if
}	// CPsiphysDoc::GenNextStim

double CPsiphysDoc::EuclPredFit()
{	// returns goodness of fit of Euclidean predictor = % correct
	int count;
	double dist01, dist12, dist02;
	double score = 0.0;
	for (count = 0; count < RESP_PER_TRIAL; count++)
	{
		dist01 = stims[count][0]->Dist(*stims[count][1]);
		dist12 = stims[count][1]->Dist(*stims[count][2]);
		dist02 = stims[count][0]->Dist(*stims[count][2]);
		switch (resp[count])
		{
			case 0:
				if ((dist01 > dist12) && (dist02 > dist12))
					score += 1.0;
				break;
			case 1:
				if ((dist01 > dist02) && (dist12 > dist02))
					score += 1.0;
				break;
			case 2:
				if ((dist02 > dist01) && (dist12 > dist01))
					score += 1.0;
				break;
		}	// switch
	}   // for
	return score*100.0/(double)RESP_PER_TRIAL;
}	// CPsiphysDoc

BOOL CPsiphysDoc::OnNewDocument()
{
	if (!CDocument::OnNewDocument())
		return FALSE;

	randseed = 4043;
	srand(randseed);
	nextResp = -1;
	GenNextStim();
	return TRUE;
}

/////////////////////////////////////////////////////////////////////////////
// CPsiphysDoc serialization

void CPsiphysDoc::Serialize(CArchive& ar)
{
	if (ar.IsStoring())
	{           
		ar << (WORD)randseed;
		ar << (WORD)RESP_PER_TRIAL;
		int count;
		for (count = 0; count < RESP_PER_TRIAL; count++)
		{
			ar << stims[count][0];
			ar << stims[count][1];
			ar << stims[count][2];
			ar << (WORD)resp[count];
		}	// for
	} else
	{         
		WORD c;
		ar >> c;
		randseed = c;
		ar >> c; 	// RESP_PER_TRIAL
		int count;
		for (count= 0; count < RESP_PER_TRIAL; count++)
		{
			ar >> stims[count][0];
			ar >> stims[count][1];
			ar >> stims[count][2];
			ar >> c;
			resp[count] = c;
		}	// for
		char result[100];
		sprintf(result, "Euclidean predictor %4.0lf", 
		EuclPredFit());
		AfxMessageBox(result);
		nextResp = RESP_PER_TRIAL-1;
	}	// if
}	// CPsiphysDoc::Serialize


/////////////////////////////////////////////////////////////////////////////
// CPsiphysDoc diagnostics

#ifdef _DEBUG
void CPsiphysDoc::AssertValid() const
{
	CDocument::AssertValid();
}

void CPsiphysDoc::Dump(CDumpContext& dc) const
{
	CDocument::Dump(dc);
}

#endif //_DEBUG

/////////////////////////////////////////////////////////////////////////////
// CPsiphysDoc commands


void CPsiphysDoc::OnFileComp()
{
	CPsiphysDoc *toDoc = new CPsiphysDoc();
	CFileDialog fileDia(TRUE, "*.psi", NULL, OFN_HIDEREADONLY | OFN_OVERWRITEPROMPT,
		"Psiphys Document (*.psi) ||");
	CFile aFile;
	if (fileDia.DoModal() != IDOK)
		return;

	if (!aFile.Open(fileDia.GetPathName(), CFile::modeRead | CFile::typeBinary))
		return;
	CArchive arc(&aFile, CArchive::load);
	toDoc->Serialize(arc);
	arc.Close();
	aFile.Close();
	
	// now compare the document with the current document
	if (toDoc->randseed != randseed)
	{
		AfxMessageBox("Random number seeds differ!");
		return;
	}	// if

	int count;
	double score = 0.0;
	for (count = 0; count < RESP_PER_TRIAL; count++)
	{
		if ((*(toDoc->stims[count][0]) != *(stims[count][0])) ||
			(*(toDoc->stims[count][1]) != *(stims[count][1])) ||
			(*(toDoc->stims[count][2]) != *(stims[count][2])))
		{
			AfxMessageBox("Stimuli not identical!");
			return;
		}	// if
		if (toDoc->resp[count] == resp[count])
			score += 1.0;
	}	// for	
	// calculate % differences in responses
	double dist01, dist12, dist02;
	double score2 = 0.0;
	for (count = 0; count < RESP_PER_TRIAL; count++)
	{
		dist01 = stims[count][0]->Dist(*stims[count][1]);
		dist12 = stims[count][1]->Dist(*stims[count][2]);
		dist02 = stims[count][0]->Dist(*stims[count][2]);
		switch (resp[count])
		{
			case 0:
				if (((dist01 < dist12) || (dist02 < dist12)) && 
					(resp[count] == toDoc->resp[count]))
					score2 += 1.0;
				break;
			case 1:
				if (((dist01 < dist02) || (dist12 < dist02)) &&
					(resp[count] == toDoc->resp[count]))
					score2 += 1.0;
				break;
			case 2:
				if (((dist02 < dist01) || (dist12 < dist01)) &&
					(resp[count] == toDoc->resp[count]))
					score2 += 1.0;
				break;
		}	// switch
	}   // for
	char result[100];
	sprintf(result, "Correlated responses: %4.0lf  Unpred: %4.0lf", 
	    score*100.0/(double)RESP_PER_TRIAL,
	    score2*100.0/(double)RESP_PER_TRIAL);
	AfxMessageBox(result);
	delete toDoc;
}	// CPsiphysDoc::OnFileComp
