////////////////////////////////////////////////////////
//	o.java
// 	Implements the o class, which is a linked object
//
//	Copyright (C) 1998, Derek Graham Lane

package theWheel;

import java.util.*;

class o 
	extends Object {

	////////////////////////////////////////////////////
	// constructors

	public o ( )  {	}

	public o ( String initLabel ) 
		{	setLabel( initLabel );	}


	////////////////////////////////////////////////////
	// tableOfLinks: contains the object's peers

	Hashtable tableOfLinks = new Hashtable();

	public oLink getLink ( o oTo ) {	
		return (oLink)tableOfLinks.get((Object)oTo);
	}

	public void	setLink ( o oTo, float weight ) {	
		oLink newLink = new oLink( oTo, weight );
		tableOfLinks.put(oTo, newLink); 
	}

	////////////////////////////////////////////////////
	// myLabel: the objects moniker

	String myLabel;

	public String getLabel ( ) {	
		return myLabel;	
	}

	public void setLabel ( String toLabel ) { 	
		myLabel = toLabel;	
	}


	////////////////////////////////////////////////////
	// debugging routines

	public String toString ( ) {
		String stringRep = new String(super.toString()+"{");
		Enumeration en = tableOfLinks.elements();
		while (en.hasMoreElements()) {
			oLink nextLink = (oLink)en.nextElement();
			stringRep += nextLink.toString(); 
		}
		stringRep += "}";
		return stringRep;
	}  

	public static void main	( String args[] )	{	
		// create a set of objects, then link them together and unlink them while creating and
		// destroying the objects
		System.out.println( "Creating 2 o objects..." );
		o thisO = new o("thisO");
		System.out.println( thisO.getLabel() + " = " + thisO );
		o thatO = new o("thatO");
		System.out.println( thatO.getLabel() + " = " + thatO );
		thisO.setLink( thatO, 0.5f );
		System.out.println( "thisO->thatO wgt = " + 
					thisO.getLink(thatO).getWeight() );
		thatO.setLink( thisO, 0.75f );
		System.out.println( "thatO->thisO wgt = " +
						thatO.getLink(thisO).getWeight() );

		o theOthero = new o("theOthero");
		theOthero.setLink( thisO, 0.45f );
		thisO.setLink( theOthero, 0.35f );
		theOthero.setLink( thatO, 0.65f );
		thatO.setLink( theOthero, 0.75f );

		System.out.println( "=====================================" );
		System.out.println( "thisO = " + thisO );
		System.out.println( );
		System.out.println( "thatO = " + thisO );
		System.out.println( );
		System.out.println( "theOthero = " + theOthero );
	}
}

////////////////////////////////////////////////////////
// 	Nothing after here.


