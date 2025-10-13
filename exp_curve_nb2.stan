
data{
  int<lower=1> T;
  int<lower=0> y[T];
  real<lower=1> N;
  int<lower=1> t[T];
}
parameters{
  real<lower=1, upper=T> t_peak;
  real<lower=0> i_peak;
  real<lower=0> r;
  real<lower=0> d;
  real<lower=0> phi;  // NB2 overdispersion (phi = 1/size)
}
transformed parameters{
  vector[T] mu;
  for (tt in 1:T){
    real it;
    if (t[tt] <= t_peak)
      it = i_peak * exp(r * (t[tt] - t_peak));
    else
      it = i_peak * exp(-d * (t[tt] - t_peak));
    mu[tt] = N * fmax(it, 1e-12);  // guard against underflow
  }
}
model{
  // priors (weakly informative; tune as needed)
  t_peak ~ uniform(1, T);
  i_peak ~ normal(0, 0.01);     // per-person weekly peak (mean ~ a few per 1e3-1e5)
  r ~ normal(0, 1);
  d ~ normal(0, 1);
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

