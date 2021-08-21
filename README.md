# Epidemic model for COVID-19

## Variables

$N$ - Population. This is set constant as we consider short term epidemic.

$I$ - Number of infected persons in the town. They are carriers of the virus and cause new infections.

$S$ - Number of persons susceptible to infection.

$V$ - Number of vaccinated persons. It is assumed that a fixed fraction, $f$, of them acquire immunity and removed from $S$.

$D$ - Cumulative number of persons diagnosed to be infected to COVID-19. They are isolated so that removed from the infected.
 
$\alpha$ - Probability of infection. This is considered to depend on the behavior of people in the town and also the infectiveness of the virus.

$p$ - Ratio of persons among the infected who are tested, diagnosed and isolated. The rest in the town and eventually self-cured. When cured, they are removed from the infected.

$C$ - Cumulative number of persons self-cured.

$m$ - Average days from infection to isolation. This is set to 10 days.

$n$ - Average days from infection to self-cure of those who are remaining in the town. This is set to 14 days.
 
## Model

The susceptible, $S$, is given with other variables as

$$
S = N - fV - D - C
$$

Simulating the current vaccination progress in Japan, $V$ is assumed to increase at constant rate from zero until June 20 to 90% of population by October 8. 

Let $I(d)$ the number of carriers in the town on day $d$. With the probability, $\alpha$, 
new infection in the day, $dI$, is given as

$$
dI(d) = \alpha I(d)S(d)/N 
$$

The following are newly diagnosed and isolated, and removed from the infected:

$$
dD(d) = pdI(d-m)
$$

Similarly, the following are self-cured and removed from the infected:

$$
dC(d) = (1-p)dI(d-n)
$$

With these, the number of infected in day $d+1$ is given as

$$
I(d+1) = I(d) + dI(d) - dD(d) - dC(d)
$$

Similarly

$$
D(d+1) = D(d) + dD(d)
$$

$$
C(d+1) = C(d) + dC(d)
$$

## Script


The script repeats the above calculation. For days 0 to 9, $dD(d) = 0$ is assumed.
A small initial number of infected, $I_0$, is assumed. For days 0 to 13, $dC(d)$ is assumed to be $I_0/n$. 

The probability of infection, $\alpha$, is manually assigned to arbitrary time spans. Values and the spans chosen to get fair fit of calculated value of $dI(d)$ to the reported value.

## Data files

infection6.txt - Reported dairy infections.

alpha6.txt - $\alpha$ values.