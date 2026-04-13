/////////////////////////////////////////////
//	oNetwork.java
// 	Implements a network of linked objects
//
//	Copyright (C) 1998, Derek Graham Lane

package theWheel.*;

class oSpacer extends o {

	//////////////////////////////////////////////
	// Constructor and pedigree

	public      oSpacer ( )
		{ 	myPosition = new float[2];
			myFraction = 100.0;
			myParent = null; 		 	
		}
  
	public	oSpacer 	( oFrame	parent, 
				    	  float[]	position, 
				    	  double	size )	
		{ 	myPosition = position;
			myParent = parent;
			myFraction = size/10000.0; 
		}

	oMapView	myParent;


	//////////////////////////////////////////////
	// Attribute: position

	float		myPosition[];

	public final double[]	
			getPosition	( )		
		{	return myPosition; }

	public void	setPosition	( double	x, 
					  double	y )	
		{ 	myPosition[0] = x;
			myPosition[1] = y; 
		}


	/////////////////////////////////////////////
	// Attribute: size

	float		myFraction;

	public double getSize 	( )		
		{ 	return mySize;	}

	public void	setSize	( double	size )	
		{ 	mySize = size; 	}


	/////////////////////////////////////////////
	// Operation: compute repositioning force

	public float spacerForce ( oLink dueTo )
		{	oSpacer sp = dueTo.get();
			float at[] = sp.getPosition();
			float sumSqared[0] = 
				(at[0] - myPosition[0])*(at[0] - myPosition[0]);
			float sumSqared[1] =
				(at[0] - myPosition[0])*(at[0] - myPosition[0]);
			dist = sumSquared[0] + sumSquared[1]; 

			return dist; 
		}


	/////////////////////////////////////////////
	// Operation: update position

	Enumeration linkEnum = getLinkEnum();

	public void	update	( Time	t  )	
		{	if (linkEnum.hasMoreElements()) {
				oLink nextLink = getNextLink(en);
				double dP[] = spacerForce(nextLink);
				myPosition[0] += dP[0];
				myPosition[1] += dP[1]; 
			} else {
				linkEnum = getLinkEnum(); 
				// include the contribution from the sink field
			}
		}


	/////////////////////////////////////////////
	// main: test routine

	public static void main	( String	args[]  )	
		{	o.main(); 
		}
}

/////////////////////////////////////////////
// 	Nothing after here.

