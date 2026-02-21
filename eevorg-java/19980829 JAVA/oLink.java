////////////////////////////////////////////////////////
//	oLink.java
// 	Implements the oLink class, which encapsulates a link to another object
//
//	Copyright (C) 1998, Derek Graham Lane

package theWheel;

import java.util.*;

class oLink extends Object {

    ////////////////////////////////////////////////////
    // constructors

    public oLink ( ) { }

    public oLink ( o at, float weight ) {	
        my = at;
		myWeight = weight; 	
	}


    ////////////////////////////////////////////////////
    // my: reference to the link's target node

    o my;

	public final o get ( ) {	
	        return my;		
	}

    public void	set ( o at ) {
	    my = at; 		
    }


    ////////////////////////////////////////////////////
    // myWeight: weight of the link

    float myWeight;

    public float getWeight ( ) {
	    return myWeight;	
	}

    public void	setWeight ( float weight ) {	
        myWeight = weight;	
    }


    ////////////////////////////////////////////////////
    // update is called "as often as possible"

    // public void	update ( Time t )
    //	{	Time x = t;			}


    ////////////////////////////////////////////////////
    // debugging routines

    public String toString ( ) {
	    String stringRep = new String(super.toString()+":");
    	stringRep += my.toString();
    	stringRep += Float.toString(getWeight());
    	return stringRep;
    }


    public static void main	( String args[] ) {	
        // use the testing routine for o
		o.main(args);
	}
}

///////////////////////////////////////////////////////////////////
// 	Nothing after here.

