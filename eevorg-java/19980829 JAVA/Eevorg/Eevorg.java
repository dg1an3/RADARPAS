/* Eevorg.java
 *
 * Copyright (C) 1998 DGLane
 */

package Eevorg;

/**
 * base class for Electronic Evolutionary Organisms.
 */
public class Eevorg implements Cloneable {

    /**
     * Create an empty Eevorg.
     */
    public Eevorg() { }

    /**
     * create an Eevorg with the given parent.
     */
    public Eevorg(Eevorg parent) {
        setParent(parent);
        this.width = parent.width;
        this.height = parent.height;
    }

    /**
     * the parent of this Eevorg.
     */
    Eevorg parent;

    /**
     * @return the parent of this Eevorg
     */
    public Eevorg getParent() {
        return parent;
    }

    /**
     * @param parent new parent of this Eevorg
     */
    public void setParent(Eevorg parent) {
        this.parent = parent;
    }

    /**
     * the width and height of this Eevorg's
     * representational image.
     */
    int height, width;

    /**
     * the pixels of this Eevorg's representational
     * image.
     */
    transient int[] pixels;

    /**
     * method to compute the representation.
     */
    void computePixels() { }

    /**
     * @return the representational Image of this
     *      Eevorg
     */
    public Image getImage() {
        ImageProducer ip = new MemoryImageSource(height, width,
                pixels, width, 0);
        Toolkit tk = Toolkit.getDefaultToolkit();
        return tk.createImage(ip);
    }

    /**
     * @return a clone of this Eevorg
     */
    public Eevorg clone() {
        return new Eevorg(this);
    }

    /**
     * changes the genome by "one"
     */
    void mutate() { }

    /**
     * @return cloned and mutated
     */
    public Eevorg spawn() {
        Eevorg offspring = this.clone();
        offspring.mutate();
        return offspring;
    }
}
