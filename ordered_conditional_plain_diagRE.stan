
data {
  int<lower=1> N;
  int<lower=1> R;
  int<lower=1> C;
  int<lower=1, upper=R> region_id[N];
  int<lower=1, upper=C> country_id[N];

  vector[N] y_logN;
  vector[N] y_logt;
  vector[N] y_logD;
  vector[N] y_logiti;

  int<lower=1> pN; matrix[N, pN] XN;
  int<lower=1> pt; matrix[N, pt] Xt;
  int<lower=1> pD; matrix[N, pD] XD;
  int<lower=1> pI; matrix[N, pI] XI;
}
parameters {
  vector[pN] beta_N;
  vector[pt] beta_t;
  vector[pD] beta_D;
  vector[pI] beta_I;

  real<lower=0> sigma_N;
  real<lower=0> sigma_t;
  real<lower=0> sigma_D;
  real<lower=0> sigma_I;

  vector<lower=0>[4] tau_reg;
  cholesky_factor_corr[4] Lcorr_reg;
  matrix[4, R] z_reg;

  vector<lower=0>[4] tau_cty;
  cholesky_factor_corr[4] Lcorr_cty;
  matrix[4, C] z_cty;
}
transformed parameters {
  matrix[4, R] u_reg;
  matrix[4, C] u_cty;

  matrix[4,4] L_reg = diag_pre_multiply(tau_reg, Lcorr_reg);
  matrix[4,4] L_cty = diag_pre_multiply(tau_cty, Lcorr_cty);

  u_reg = L_reg * z_reg;
  u_cty = L_cty * z_cty;
}
model {
  beta_N ~ normal(0, 1.5);
  beta_t ~ normal(0, 1.5);
  beta_D ~ normal(0, 1.5);
  beta_I ~ normal(0, 1.5);

  sigma_N ~ normal(0, 1);
  sigma_t ~ normal(0, 1);
  sigma_D ~ normal(0, 1);
  sigma_I ~ normal(0, 1);

  tau_reg ~ normal(0, 1);
  tau_cty ~ normal(0, 1);
  Lcorr_reg ~ lkj_corr_cholesky(2);
  Lcorr_cty ~ lkj_corr_cholesky(2);

  to_vector(z_reg) ~ normal(0, 1);
  to_vector(z_cty) ~ normal(0, 1);

  for (n in 1:N) {
    int r = region_id[n];
    int c = country_id[n];
    real aN = u_reg[1, r] + u_cty[1, c];
    real at = u_reg[2, r] + u_cty[2, c];
    real aD = u_reg[3, r] + u_cty[3, c];
    real aI = u_reg[4, r] + u_cty[4, c];

    y_logN[n]   ~ normal( XN[n] * beta_N + aN, sigma_N );
    y_logt[n]   ~ normal( Xt[n] * beta_t + at, sigma_t );
    y_logD[n]   ~ normal( XD[n] * beta_D + aD, sigma_D );
    y_logiti[n] ~ normal( XI[n] * beta_I + aI, sigma_I );
  }
}
generated quantities {
  vector[N] y_logN_rep;
  vector[N] y_logt_rep;
  vector[N] y_logD_rep;
  vector[N] y_logiti_rep;

  corr_matrix[4] Omega_reg = multiply_lower_tri_self_transpose(Lcorr_reg);
  corr_matrix[4] Omega_cty = multiply_lower_tri_self_transpose(Lcorr_cty);

  for (n in 1:N) {
    int r = region_id[n];
    int c = country_id[n];
    real aN = u_reg[1, r] + u_cty[1, c];
    real at = u_reg[2, r] + u_cty[2, c];
    real aD = u_reg[3, r] + u_cty[3, c];
    real aI = u_reg[4, r] + u_cty[4, c];

    y_logN_rep[n]   = normal_rng( XN[n] * beta_N + aN, sigma_N );
    y_logt_rep[n]   = normal_rng( Xt[n] * beta_t + at, sigma_t );
    y_logD_rep[n]   = normal_rng( XD[n] * beta_D + aD, sigma_D );
    y_logiti_rep[n] = normal_rng( XI[n] * beta_I + aI, sigma_I );
  }
}

