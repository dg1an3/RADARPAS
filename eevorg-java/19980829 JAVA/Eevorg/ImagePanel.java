/**  @(#)ImageCanvas.java	1.0 98/05/07
  * 
  *  Copyright (c) 1998, Computerized Medical Systems, Inc. 
  *  All Rights Reserved.
  * 
  *  @version	1.0 05/05/98
  *  @author 	Derek Graham Lane
  *  CopyrightVersion 1.0_beta
  */

package Eevorg;

import java.awt.*;

public class ImagePanel
  extends Panel {
    
    /**  Constructs a default image canvas with black
      *  background.
      */
    
    public ImagePanel ( ) { 
      setBackground(Color.black); 
      setLayout(null);
    }

    /**  Constructs an image canvas with black
      *  background and sets img as the image.
      */

    public ImagePanel ( Image img ) { 
      this();
      setImage(img); 
    }


    /**  Accessors for the image itself
      */
    
    Image img;
    public Image getImage ( ) { 
      return img; 
    }

    public void setImage ( Image img ) {
      this.img = img; 
      prepareImage(img, this);
    }
    

    /**  Accessor for the image's dimensions
      */
    
    Dimension size = new Dimension();
    public Dimension getImageSize() {
      return size;
    }


    /**  Accessors for the panel's preferred size
      */

    Dimension preferred = new Dimension(256, 256);
    public Dimension getPreferredSize() {
      return preferred;
    }
    
    public synchronized void setPreferredSize ( int width, int height ) {
      preferred.width = width;
      preferred.height = height;
    }
    public synchronized void setPreferredSize ( Dimension pref ) {
      preferred = pref;
    }
    

    /**  Accessors for the image offset
      */

    Point offset = new Point();
    public Point getOffset() { 
      return offset;
    }
    
    public synchronized void setOffset ( int x, int y ) {
      offset.x = x;
      offset.y = y;
    }
    public synchronized void setOffset ( Point offset ) {
      this.offset = offset;
    }
    

    /**  Accessors for the image scale 
      */

    double scale = 1.0;          // Current Image Scale 
    public double getScale() { 
      return scale; 
    }
    public int getScaledWidth() { 
      return (int)(scale*size.width + 0.5);
    }
    public int getScaledHeight() { 
      return (int)(scale*size.height + 0.5);
    }
    
    public synchronized void setScale ( double scale ) {
      this.scale = scale;
    }
    
    
    /**  Image drawing
      */

    static final public int depth = 2;

    public void paint ( Graphics g ) {
      update(g);
    }

    public void update ( Graphics g ) {
      if (g != null) {
	Graphics cg = g; //.create;
	// draw the 3D border
	cg.setColor(Color.gray);
	cg.draw3DRect( 0, 0, getSize().width, 
		      getSize().height, true );
	cg.setColor(getBackground());
	
	// setting the clipping rectangle
	int w = getSize().width - (2*depth);
	int h = getSize().height - (2*depth);
	cg.clipRect( depth, depth, w, h );

	// draw the image 
	int sw = getScaledWidth();
	int sh = getScaledHeight();
	if ((img != null) && (sw > 0) && (sh > 0)) {
	  int ulx = depth - offset.x;
	  int uly = depth - offset.y;
	  cg.drawImage(img, ulx, uly, sw, sh, this);
	  fillExtra(cg, offset, new Dimension(sw,sh));
	}
	paintComponents(g);
      }
    }

    public void fillExtra ( Graphics g, 
			    Point offset, Dimension dim ) {
      int w = getSize().width - (2*depth);
      int h = getSize().height - (2*depth);
      g.setColor(getBackground());
      if ( offset.x < 0 )
	g.fillRect( depth, depth, -offset.x, h );
      if ( offset.y < 0 )
	g.fillRect( depth, depth, w, -offset.y );
      if ( dim.width - offset.x < w )
	g.fillRect( dim.width + depth - offset.x, depth, 
		    w - dim.width + offset.x, dim.height );
      if ( dim.height - offset.y < h )
	g.fillRect( depth, dim.height + depth - offset.y, 
		    w, h - dim.height + offset.y );
    }

    /**  Image observer interface
      */

    public boolean imageUpdate ( Image img, int infoFlags,
			         int x, int y, 
				 int width, int height ) {
      boolean ret = true;
      if (img == this.img ) {
	if ((infoFlags & WIDTH) != 0)
	  size.width = width;
	if ((infoFlags & HEIGHT) != 0)
	  size.height = height;
	if ((infoFlags & (FRAMEBITS | ALLBITS | SOMEBITS)) != 0) {
	  Graphics g = getGraphics();
	  if (g != null)
	    update(g);
	}
	if ((infoFlags & ERROR) != 0)
	  ret = false;
      }
      return ret;
    }
}

////////////////////////////////////////////////////////////
//  Nothing after here.
