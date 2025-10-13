
data{
  int<lower=1> T;
  int<lower=0> y[T];
  real<lower=1> N;
  int<lower=1> t[T];
}
parameters{
  real<lower=1, upper=T> t_peak;
  real<lower=0> i_peak;
  real<lower=2, upper=T> D;     // total duration (>=2 weeks)
  real<lower=0> phi;
}
transformed parameters{
  vector[T] mu;
  for (tt in 1:T){
    real it;
    if (t[tt] <= t_peak){
      it = i_peak * (t[tt] / t_peak);
    } else if (t[tt] > t_peak && t[tt] <= D){
      it = i_peak * (1 - (t[tt] - t_peak) / fmax(D - t_peak, 1e-6));
    } else {
      it = 0;
    }
    mu[tt] = N * fmax(it, 1e-12);
  }
}
model{
  // priors
  t_peak ~ uniform(1, T);
  D ~ uniform(2, T);
  i_peak ~ normal(0, 0.01);
  phi ~ exponential(2);

  for (tt in 1:T){
    y[tt] ~ neg_binomial_2(mu[tt], 1.0 / phi);
  }
}
generated quantities{
  int y_rep[T];
  for (tt in 1:T){
    y_rep[tt] = neg_binomial_2_rng(mu[tt], 1.0 / phi);
  }
}

