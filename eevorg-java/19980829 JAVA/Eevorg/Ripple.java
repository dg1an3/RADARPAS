package Eevorg;

import java.awt.*;
import java.awt.image.*;

public class Ripple extends MemoryImageSource 
        implements Runnable {

    int width, height;
    public int[] pixels;

    public Ripple(int width, int height) {
        super(width, height, null, 0, width);
        this.width = width;
        this.height = height;
        setAnimated(true);
        pixels = new int[width*height];
        newPixels(pixels, ColorModel.getRGBdefault(), 0, width);
        Thread theThread = new Thread(this);
        theThread.start();
    }

    void computePixels() {
        for (int y = 0; y < height; y++)
            for (int x = 0; x < width; x++) {
                pixels[x+y*width] = (255 << 24) 
                    | (((int) redField.value(x,y)) << 16) 
                    | (((int) grnField.value(x,y)) << 8) 
                    | (((int) bluField.value(x,y)));
            }
        newPixels();
    }
    
    ScalarField2D timeBase1 = new ScalarField2D();
    ScalarField2D timeBase2 = new ScalarField2D();
    
    SineGrating redMod1 = 
            new SineGrating(0.41, 1.24, timeBase1, timeBase2, 0.0);
    SineGrating redMod2 = 
            new SineGrating(0.3, 0.41, timeBase2, timeBase1, 0.0);
    SineGrating redField = 
            new SineGrating(128.0, 128.0, redMod1, redMod2, 0.0);
    
    SineGrating grnMod1 = 
            new SineGrating(0.40, 1.21, timeBase1, timeBase2, 0.0);
    SineGrating grnMod2 = 
            new SineGrating(0.27, 0.41, timeBase2, timeBase1, 0.0);
    ScalarField2D grnField = 
            new SineGrating(128.0, 128.0, grnMod1, grnMod2, 0.0);

    SineGrating bluMod1 = 
            new SineGrating(0.41, 1.21, timeBase1, timeBase2, 0.0);
    SineGrating bluMod2 = 
            new SineGrating(0.3, 0.41, timeBase2, timeBase1, 0.0);
    ScalarField2D bluField = 
            new SineGrating(128.0, 128.0, bluMod1, bluMod2, 0.0);
            
    public void run() {
        double t = 0.0;
        while (true) {
            timeBase1.v = 0.07 + 0.05*Math.sin(t);
            timeBase2.v = 0.08 + 0.04*Math.cos(t);
            computePixels();
            t += 0.1;
        }
    }
    
    public static void main(String[] args) {
        Frame testFrame = new Frame("Test Ripple");
        testFrame.setSize(150,150);
        Ripple theRipple = new Ripple(100,100);
        ImagePanel thePanel = new ImagePanel();
        thePanel.setImage(thePanel.createImage(theRipple));
        testFrame.add(thePanel);
        testFrame.show();
    }
    
    class ScalarField2D {
        double v = 0.0;
        ScalarField2D() { }
        ScalarField2D(double v) {
            this.v = v;
        }
        double value(double x, double y) {
            return v;
        }
    }
    
    class SineGrating extends ScalarField2D {
        
        double a = 1.0;
        double c = 0.0;
        ScalarField2D fx = new ScalarField2D(0.5);
        ScalarField2D fy = new ScalarField2D(0.5);
        double phi;
        
        SineGrating(double a, double c, 
                ScalarField2D fx, ScalarField2D fy, double phi) {
            this.a = a;
            this.c = c;
            this.fx = fx;
            this.fy = fy;
            this.phi = phi;            
        }
        
        SineGrating(double a, double c, 
                double xFreq, double yFreq, double phi) {
            this(a,c,new ScalarField2D(xFreq),
                    new ScalarField2D(yFreq),phi);
        }        
        
        void setPolar(double freq, double orient) {
            fx = new ScalarField2D(freq*Math.cos(orient));
            fy = new ScalarField2D(freq*Math.sin(orient));
        }
        
        double value(double x, double y) {
            return c + a*Math.sin(fx.value(x,y)*x + 
                                    fy.value(x,y)*y + phi);
        }
    }
}