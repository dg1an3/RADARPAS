#ifndef _Mathutil_h_
#define _Mathutil_h_

typedef double (* LookupProc)( double );

class Lookup {        
        double min, max, step;
        long tableSize;
        double *table;
        
public:
		Lookup( double Min, double Max, double Step, LookupProc proc) {
				min = Min;
				max = Max;
				step = Step;
				tableSize = (long)((max - min)/step);
				table = new double[tableSize];
				
				double y = min;
				for (long count = 0; count < tableSize; count++)  {
						table[count] = (*proc)(y);
						y += step;
				}
		}
		
		~Lookup()  {
				delete [] table;
		}
		
		double value(double at) {
				if ((at >= min) && (at <= max))
						return table[(long)((at - min)/step)];
				else
						return 0.0;
		}
};

#endif
