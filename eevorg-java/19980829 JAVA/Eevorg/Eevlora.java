/**  Eevlora -- Two-dimensional cellular automaton
  *
  *  Copyright (C) 1998,  D. G. Lane
  */
  
package Eevorg;

import java.awt.*;
import java.awt.image.MemoryImageSource;
import java.util.Vector;

/**
  *
  */
public class Eevlora 
    extends Canvas {

        ///////////////////////////////////////////////////////////////////
        //
        
        /**  Constructor
          *
          */
    	public Eevlora() {
    	}

        ///////////////////////////////////////////////////////////////////
        // 
        
        /**  Rule array.
          *
          */
	    protected int[] rules;

        /**  Get accessor for rule array.
          *
          */
    	public int[] getRules() {
    		return this.rules;
    	}

        /**  Get accessor for single rule.
          *
          */
    	public int getRule(int nIndex) {
	    	return this.rules[nIndex];
    	}

        /**  Set accessor for rule array.
          *
          *  @see setRule(int nIndex, int rule)
          *  @see getRules()
          */
    	public void setRules(int[] rules) {
			this.rules = rules;
    	}

        /**  Set accessor for single rule.
          *
          *  @see setRules(int[] rules)
          *  @see getRule(int nIndex)
          */
	    public void setRule(int nIndex, int rule) {
			this.rules[nIndex] = rule;
    	}

        ///////////////////////////////////////////////////////////////////
        // Generation computation
        
        Vector gen = new Vector();
        
        int[][] computeNextGen ( int prev[][] ) {
            int next[][] = new int[prev.length+1][];
            for (int c = 0; c < next.length; c++)
                next[c] = new int[c+1];
            next[0][0] = 
                prev[1][1] + prev[1][0] + prev[1][1] +
                prev[1][1] + prev[0][0] + prev[1][1] +
                prev[1][1] + prev[1][0] + prev[1][1];
            for (int y = 0; y < next.length; y++)
                for (int x = 0; x <= y; x++) {
                    int sum = 
                        prev[y-1][x-1] + prev[y-1][x] + prev[y-1][x+1] +
                        prev[y  ][x-1] + prev[y  ][x] + prev[y  ][x+1] +
                        prev[y+1][x-1] + prev[y+1][x] + prev[y+1][x+1];
                    next[y][x] = getRule(sum);
                }
            return next;
        }
        
        ///////////////////////////////////////////////////////////////////
        // Image rendering
        
        int colorMap[];
        
        final int getColor ( int value ) {
            return colorMap[value];
        }
        
        int[] preparePixels ( int gen[][], int width, int height ) {
            int pix[] = new int[width*height];
            for (int y = 0; y < height; y++)
                for (int x = 0; x < width; x++) {
                    pix[y*width + x] = getColor(gen[y][x]);
                }
            return pix;
        }

        final static int NUM_GEN = 32;
        
        int pixels[] = new int[NUM_GEN*NUM_GEN];
        MemoryImageSource mySource =
            new MemoryImageSource(NUM_GEN, NUM_GEN, pixels, 0, NUM_GEN);
            

        ///////////////////////////////////////////////////////////////////
        // Painting
   
        public void paint ( Graphics g ) {
            g.setColor(Color.red);
            g.drawLine(0,0,100,100);
        }
        
        ///////////////////////////////////////////////////////////////////
        // main -- Test code.
        
        /**
          *
          */
    	static public void main(String args[]) {
    		class DriverFrame extends java.awt.Frame {
	    		public DriverFrame() {
    				addWindowListener(new java.awt.event.WindowAdapter() {
    					public void windowClosing(java.awt.event.WindowEvent event)
    					{
    						dispose();	  // free the system resources
    						System.exit(0); // close the application
    					}
    				});
    				this.setLayout(new java.awt.BorderLayout());
    				this.setSize(300,300);
    				this.add(new Eevlora());
    			}
    		}

	    	new DriverFrame().show();
    	}
}

///////////////////////////////////////////////////////////////////
// Nothing after here.