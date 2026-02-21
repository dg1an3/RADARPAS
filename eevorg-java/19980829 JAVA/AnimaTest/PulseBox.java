package AnimaTest;

import java.awt.*;
import java.awt.event.*;
import java.util.*;

class PulseBox extends Button {

    Waver waver = new Waver();
    
    public PulseBox() {
        setSize(50,50);
        addMouseMotionListener(waver);
    }

    public static void main(String[] args) {
        Frame testFrame = new Frame();
        testFrame.setLayout(null);
        testFrame.setSize(400,400);

        PulseBox thePulse = new PulseBox();
        thePulse.setSize(50,50);
        thePulse.setLocation(100,100);
        testFrame.add(thePulse);
        testFrame.addMouseMotionListener(thePulse.waver);
        
        Random r = new Random();
        for (int c = 0; c < 10; c++) {
            PulseBox pulse2 = new PulseBox();
            pulse2.setSize(50, 50);
            int posX = 200 + (int) Math.round(200.0*r.nextGaussian());
            int posY = 200 + (int) Math.round(200.0*r.nextGaussian());
            pulse2.setLocation(posX, posY);
            testFrame.add(pulse2);
            testFrame.addMouseMotionListener(pulse2.waver);
        }
        
        testFrame.show();        
    }
    
    static final int SQUARE_TABLE_SIZE = 10000;
    static int[] square = new int[SQUARE_TABLE_SIZE];
    static {   
        for (int c = -square.length/2; c < square.length/2; c++)
            square[c + square.length/2] = c*c;
    }
    
    static final double AMPL = 0.45;
    static final double SIGMA = 300.0;
    static final int WAVEFIELD_TABLE_SIZE = 1000000;
    static double[] waveField = new double[WAVEFIELD_TABLE_SIZE];
    static {   
        for (int c = 0; c < WAVEFIELD_TABLE_SIZE; c++)
            waveField[c] = AMPL*Math.exp(((double) -c) / (SIGMA*SIGMA));
    }
    
    static double totalActivation = 0;
    double activation = 10;  { totalActivation += activation; }
    void dActivation(double delta) {
        double actDelta = ((double) delta) * totalActivation;
        activation += actDelta;
        totalActivation += actDelta;
    }
    
    Dimension normSize() {
        Dimension d = new Dimension();
        d.width = (int) (400.0 * activation / totalActivation);
        d.height = d.width;
        if (d.width <= 0) {
            System.out.println("What the fuck!!!");
        }
        return d;
    }
    
    public void paint(Graphics g) {
        g.setColor(Color.black);
        Dimension d = getSize();
        g.drawRect(0,0,d.width-1,d.height-1);
    }
    
    class Waver extends MouseMotionAdapter {
        public void mouseMoved(MouseEvent ev) {
            Point p = ev.getPoint();
            if (ev.getSource() != PulseBox.this) {                
                Point i = getLocation();
                p.x -= i.x;
                p.y -= i.y;
            }
            int oldWidth = getSize().width;
            int oldHeight = getSize().height;
            p.x += SQUARE_TABLE_SIZE/2 - oldWidth/2;
            p.y += SQUARE_TABLE_SIZE/2 - oldHeight/2;
            int distSquared = square[p.x]+square[p.y];
            if (distSquared < waveField.length) {
                double field = waveField[distSquared];
                dActivation(field);
                setSize(normSize());
                setLocation(getLocation().x+oldWidth/2 - getSize().width/2,
                            getLocation().y+oldHeight/2 - getSize().height/2);
            }
        }
    }
}