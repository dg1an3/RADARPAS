import * as fs from 'fs';
import * as readline from 'readline';

const numOfGen = 100; // number of generations to store
const size = 40;

class Organism {
    // member variables
    age: number; // number of generations since spawn
    terminal: number; // set to 1 if all of the children are null
    child: (Organism | null)[]; // offspring of organism
    parent: Organism | null; // parent organism
    cells: number[][]; // pointer to cell bodies
    maxState: number; // maximum cell state in the cell body
    temporalEntropy: number; // stores organisms average TE
    spatialEntropy: number; // stores organisms average SE
    rules: number[]; // points to rules -- maxState = 7

    constructor();
    constructor(parent: Organism | null);
    constructor(parent?: Organism | null) {
        this.age = 0;
        this.terminal = 1;
        this.child = new Array(5).fill(null);
        this.parent = parent || null;

        this.cells = Array.from({ length: size }, () => new Array(size).fill(0));
        this.cells[Math.floor(size / 2)][Math.floor(size / 2)] = 1; // set initial cell value in center

        this.temporalEntropy = 0;
        this.spatialEntropy = 0;
        this.maxState = 1;
        this.rules = new Array(7 * 9 + 1).fill(0);
        this.rules[0] = 0;
        this.rules[1] = 1;
        this.rules[2] = 0;
        this.rules[3] = 1;

        if (parent) {
            this.age = parent.age;
            this.maxState = parent.maxState;
            this.rules = parent.rules.slice();
        }
    }

    // Destructor logic
    destructor() {
        for (let i = 0; i < 5; i++) {
            if (this.child[i] !== null) {
                this.child[i]!.destructor();
            }
        }
        // No need to explicitly delete cells and rules in TypeScript
    }

    evolve(): string {
        let key = '';
        let childCount: number;
        do {
            this.plotAt(vc.numxpixels / 2, (vc.numypixels * 3) / 4);
            this.nextGen();

            for (childCount = 0; childCount < 5; childCount++) {
                if (this.child[childCount] === null) {
                    this.child[childCount] = this.spawnChild(); // make new child
                } else {
                    this.child[childCount]!.plotAt(
                        (vc.numxpixels * (childCount + 1)) / 6,
                        vc.numypixels / 3
                    );
                }
                this.child[childCount]!.nextGen();
            }

            this.terminal = 0; // if the node was terminal before, it's not now

            if (this.kbhit()) {
                key = this.getch();
            } else {
                key = '';
            }
        } while (key === '');
        return key;
    }

    // abstract functions--need to be supplied by derived classes
    plotAt(X: number, Y: number): void {    // display the organism
        for (let atX = 0; atX < size; atX++) {
            for (let atY = 0; atY < size; atY++) {
                this.setColor((vc.numcolors - 1) * this.cells[atX][atY] / this.maxState);
                this.setPixel(X - Math.floor(size / 2) + atX, Y + Math.floor(size / 2) - atY);
            }
        }
    }

    nextGen(): void {   // calculate the next generation
        let te = 0;
        let se = 0;
        let maxval = 0;
        const newCells: number[][] = Array.from({ length: size }, () => new Array(size).fill(0));

        for (let atX = 1; atX < size - 1; atX++) {
            for (let atY = 1; atY < size - 1; atY++) {
                newCells[atX][atY] = this.rules[
                    this.cells[atX - 1][atY - 1] +
                    this.cells[atX][atY - 1] +
                    this.cells[atX + 1][atY - 1] +
                    this.cells[atX - 1][atY] +
                    this.cells[atX][atY] +
                    this.cells[atX + 1][atY] +
                    this.cells[atX - 1][atY + 1] +
                    this.cells[atX][atY + 1] +
                    this.cells[atX + 1][atY + 1]
                ];
                se += Math.abs(newCells[atX - 1][atY] - newCells[atX][atY]) +
                    Math.abs(newCells[atX][atY - 1] - newCells[atX][atY]);
                te += Math.abs(newCells[atX][atY] - this.cells[atX][atY]);
                maxval = Math.max(maxval, newCells[atX][atY]);
            }
        }

        for (let atX = 0; atX < size; atX++) {
            for (let atY = 0; atY < size; atY++) {
                this.cells[atX][atY] = newCells[atX][atY];
            }
        }

        if (maxval > 0) {
            this.temporalEntropy = (this.temporalEntropy * 5 + te / ((size - 2) * maxval)) / 6;
            this.spatialEntropy = (this.spatialEntropy * 5 + se / ((size - 2) * maxval)) / 6;
        } else {
            this.temporalEntropy = this.temporalEntropy * 5 / 6;
            this.spatialEntropy = this.spatialEntropy * 5 / 6;
        }

        this.age++;
    }

    spawnChild(): Organism {    // create copy with one mutation
        const tempAge = this.age;
        this.age = 0;
        const newChild = new (this.constructor as any)(this) as Organism;
        this.age = tempAge;

        const ruleAt = Math.floor(Math.random() * (newChild.maxState * 3 + 1));
        if (newChild.rules[ruleAt] > 0 && Math.random() < 0.5) {
            newChild.rules[ruleAt]--;
        } else {
            newChild.rules[ruleAt]++;
            if (newChild.rules[ruleAt] > newChild.maxState) {
                const newRules = new Array(newChild.rules[ruleAt] * 3 + 1).fill(0);
                for (let i = 0; i < newChild.maxState * 3 + 1; i++) {
                    newRules[i] = newChild.rules[i];
                }
                newChild.rules = newRules;
                newChild.maxState = newChild.rules[ruleAt];
            }
        }

        return newChild;
    }

    fitness(): number {     // returns fitness (0 == not viable, 1 == maximally viable)
        const fit = this.temporalEntropy * (1 - this.temporalEntropy) *
            this.spatialEntropy * (1 - this.spatialEntropy) * 16;
        return fit;
    }

    freeMemory(sz: number): number {
        let memFreed = 0;
        for (let count = 0; count < this.cells.length; count++) {
            if (this.cells[count]) {
                memFreed += this.cells[count].length;
                this.cells[count].fill(0);
            }
        }
        return memFreed;
    }

    // Placeholder methods for kbhit() and getch()
    kbhit(): boolean {
        return false;
    }
    getch(): string {
        return ' ';
    }
    // Placeholder methods for setColor and setPixel
    setColor(color: number): void {
    }
    setPixel(x: number, y: number): void {
    }
}

// Placeholder vc object with numxpixels, numypixels, and numcolors properties
const vc = {
    numxpixels: 800,
    numypixels: 600,
    numcolors: 256
};

async function readHexFile(filePath: string): Promise<string[]> {
    const hexValues: string[] = [];
    
    const fileStream = fs.createReadStream(filePath);
    
    const rl = readline.createInterface({
        input: fileStream,
        crlfDelay: Infinity
    });
    
    for await (const line of rl) {
        if (line.length === 64 && /^[0-9a-fA-F]+$/.test(line)) {
            hexValues.push(line);
        } else {
            console.error(`Invalid line: ${line}`);
        }
    }
    
    return hexValues;
}

const filePath = 'path/to/your/file.txt';

readHexFile(filePath).then(hexValues => {
    console.log('Hexadecimal values:', hexValues);
}).catch(error => {
    console.error('Error reading file:', error);
});
