Model

Let N(d) the number of carriers in the town on day d. With the probability, \alpha, new infection in the day, dN, is given as

dN = \alpha N

 N decreases either by isolation or cure without isolation. A fraction, r, of the infected get tested positive and isolated. This occurs m days after infection. The rest of the infected are cured n days after infection. The decrease of carriers in the town on day d is thus given as;

dN = rdN(d-m) + (1-r)dN(d-n)

   Daily change of N is thus given as

dN = \alpha N - rdN(d-m) - (1-r)dN(d-n)

Script and data files

The script repeats this calculation;

N(d+1) = N(d) + \alpha N(d)

On each day, it prints the number of infected who is tested positive on the day, p. \alpha of each day is chosen so as to make p be close to observed value. This is done manually inputting \alpha value of intervals in a parameter file, alpha6.txt. To facilitate comparison of p between observation and calculation, Observed daily p values are input to a data file, infections6.txt.
