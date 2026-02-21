import copy

numOfGen = 100   # number of generations to store
size = 40
vc_numxpixels = 640
vc_numypixels = 480
vc_numcolors = 16

def kbhit():
    return True

def getch():
    return ' '

def _setcolor():
    return

def _setpixel():
    return

class Organism(object):
    def __init__(self, fromParent=None):
        self.age = fromParent.age if fromParent else 0
        self.terminal = 1

        self.child = [None] * 5
        self.parent = fromParent

        self.cells = [[0] * size] * size
        self.cells[size/2][size/2] = 1	 # set initial cell value in center

        self.temporalEntropy = 0
        self.spatialEntropy = 0 			   
        assert self.cells != None

        if fromParent:
            self.maxState = fromParent.maxState
            self.rules = copy.deepcopy(fromParent.rules)
        else:
            self.maxState = 1
            self.rules = [0] * 7*9+1
            self.rules[0] = 0
            self.rules[1] = 1
            self.rules[2] = 0
            self.rules[3] = 1		   
        assert self.rules != None

    def evolve(self):
        # user-mediated evolution procedure
        key = 0
        while key == 0:
            # repeat this loop until any key is pressed
            self.plotAt(vc_numxpixels/2, vc_numypixels*3/4)
            self.nextGen()

            for child in self.child:
                # for each child
                if (child == None):
                    child = self.spawnChild()    # make new child
                else:
                    child.plotAt(vc_numxpixels*(len(self.child)+1)/6, vc_numypixels/3)
                assert child != None
                child.nextGen()

            self.terminal = 0;    # if the node was terminal before, its not now

            if (kbhit()):
                # read the key and see what needs to be done
                key = getch()
            else:
                key = 0
        return key

    def nextGen(self):
        at:int = 0

        te:int = 0 
        se:int = 0
        maxval:int = 0
        atX:int = 0
        atY:int = 0
        newCells = [[0] * size] * size
        # newCells = new char[size[0]];
        # newCells[0] = rules[cells[0][0]+cells[0][1]+cells[0][2]];
        for atX in range(1, size):
            for atY in range(1, size):
                newCells[at] = self.rules[self.cells[atX-1][atY-1]+
                        self.cells[atX  ][atY-1]+
                        self.cells[atX+1][atY-1]+
                        self.cells[atX-1][atY  ]+
                        self.cells[atX  ][atY  ]+
                        self.cells[atX+1][atY  ]+
                        self.cells[atX-1][atY+1]+
                        self.cells[atX  ][atY+1]+
                        self.cells[atX+1][atY+1]]
                se += (abs(newCells[atX-1][atY]-newCells[atX][atY])+
                    abs(newCells[atX][atY-1]-newCells[atX][atY]))
                te += abs(newCells[atX][atY]-self.cells[atX][atY])
                maxval = max(maxval, newCells[atX][atY])

        # memmove(&newCells, &cells, size*size)

        if (maxval > 0):
            # add the amounts to the temporal and spatial entropy averages
            temporalEntropy = (temporalEntropy*5+float(te)/(size[0]-2)/maxval)/6
            spatialEntropy = (spatialEntropy*5+float(se)/(size[0]-2)/maxval)/6
        else:
            # otherwise, add zero to the averages
            temporalEntropy = temporalEntropy*5/6
            spatialEntropy = spatialEntropy*5/6

        self.age = self.age+1    # increment age counter

    def plotat(self, X, Y):
        for atX in range(0, size):
            # draw 2 lines for each generation
            for atY in range(0, size):
                # draw the indicated pixel
                _setcolor((vc_numcolors-1)*self.cells[atX][atY]/self.maxState)
                _setpixel(X-size/2+atX, Y+size/2-atY)
