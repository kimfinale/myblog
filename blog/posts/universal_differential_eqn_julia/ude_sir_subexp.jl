# SciML Tools
# using OrdinaryDiffEq, ModelingToolkit, DataDrivenDiffEq, SciMLSensitivity, DataDrivenSparse
using OrdinaryDiffEq, SciMLSensitivity
using Optimization, OptimizationOptimisers, OptimizationOptimJL

# Standard Libraries
using LinearAlgebra, Statistics

# External Libraries
using ComponentArrays, Lux, Zygote, Plots, StableRNGs
gr()

# Set a random seed for reproducible behaviour
rng = StableRNG(1111)

function sir_subexp!(du, u, p, t)
    α, β, γ = p 
    du[1] = - β*u[1]*u[2]^α
    du[2] = + β*u[1]*u[2]^α - γ*u[2]
    du[3] = + γ*u[2]
end

# Define the experimental parameter
tspan = (0.0, 20.0)
# u0 = 5.0f0 * rand(rng, 2)
u0 = [0.99, 0.01, 0.0]
p_ = [0.8, 0.4, 0.2]
prob = ODEProblem(sir_subexp!, u0, tspan, p_)
solution = solve(prob, Tsit5(), abstol = 1e-12, reltol = 1e-12, saveat = 1.0)

# Add noise in terms of the mean
X = Array(solution)
t = solution.t

xbar = mean(X, dims = 2)   
noise_magnitude = 5e-2
Xn = X .+ (noise_magnitude * xbar) .* randn(rng, eltype(X), size(X))

plot(solution, alpha = 0.75, color = :black, label = ["True Data" nothing])
scatter!(t, transpose(Xn), color = :red, label = ["Noisy Data" nothing])

# Let's define our Universal Differential equation
rbf(x) = exp.(-(x .^ 2))

# Multilayer FeedForward
const U = Lux.Chain(Lux.Dense(3, 5, rbf), Lux.Dense(5, 5, rbf), 
Lux.Dense(5, 5, rbf), Lux.Dense(5, 1))
# Get the initial parameters and state variables of the model
p, st = Lux.setup(rng, U)
const _st = st

# Define the hybrid model
function ude_dynamics!(du, u, p, t, p_true)
    uhat = U(u, p, _st)[1] # Network prediction
    du[1] = dS = - uhat[1]
    du[2] = dI = + uhat[1] - p_true[3]*u[2] 
    du[3] = dR = + p_true[3]*u[2] 
end

# Closure with the known parameter
nn_dynamics!(du, u, p, t) = ude_dynamics!(du, u, p, t, p_)
# Define the problem
prob_nn = ODEProblem(nn_dynamics!, Xn[:, 1], tspan, p)

function predict(θ, X = Xn[:, 1], T = t)
    _prob = remake(prob_nn, u0 = X, tspan = (T[1], T[end]), p = θ)
    Array(solve(_prob, Tsit5(), saveat = T,
                abstol = 1e-6, reltol = 1e-6,
                sensealg=QuadratureAdjoint(autojacvec=ReverseDiffVJP(true))))
end

function loss(θ)
    pred = predict(θ)
    mean(abs2, Xn .- pred)
end

losses = Float64[]

callback = function (p, l)
    push!(losses, l)
    if length(losses) % 50 == 0
        println("Current loss after $(length(losses)) iterations: $(losses[end])")
    end
    return false
end

adtype = Optimization.AutoZygote()
optf = Optimization.OptimizationFunction((x, p) -> loss(x), adtype)
optprob = Optimization.OptimizationProblem(optf, ComponentVector{Float64}(p))

res1 = Optimization.solve(optprob, ADAM(), callback = callback, maxiters = 2000)
println("Training loss after $(length(losses)) iterations: $(losses[end])")

optprob2 = Optimization.OptimizationProblem(optf, res1.u)
res2 = Optimization.solve(optprob2, Optim.LBFGS(), callback = callback, maxiters = 1000)
println("Final training loss after $(length(losses)) iterations: $(losses[end])")

# Rename the best candidate
p_trained = res2.u

# Plot the losses
pl_losses = plot(1:2000, losses[1:2000], yaxis = :log10, xaxis = :log10,
                 xlabel = "Iterations", ylabel = "Loss", label = "ADAM", color = :blue)
plot!(2001:length(losses), losses[2001:end], yaxis = :log10, xaxis = :log10,
      xlabel = "Iterations", ylabel = "Loss", label = "BFGS", color = :red)


## Analysis of the trained network
# Plot the data and the approximation
ts = first(solution.t):(mean(diff(solution.t)) / 2):last(solution.t)
Xhat = predict(p_trained, Xn[:,1], ts)
# Trained on noisy data vs real solution
pl_trajectory = plot(ts, transpose(Xhat), xlabel = "t", ylabel = "S(t), I(t), R(t)", color = :red,
                     label = ["UDE Approximation" nothing])
scatter!(solution.t, transpose(Xn), color = :black, label = ["Measurements" nothing])

# pl_trajectory = plot(ts, transpose(Xhat)[:,2], xlabel = "t", ylabel = "I(t)", color = :red,
#                      label = ["UDE Approximation" nothing])
# scatter!(solution.t, transpose(Xn)[:,2], color = :black, label = ["Measurements" nothing])

# Ideal unknown interactions of the predictor
# Ybar = [-p_[2] * (Xhat[1, :] .* Xhat[2, :])'; p_[3] * (Xhat[1, :] .* Xhat[2, :])']
# Ybar = [p_[2] .* Xhat[1,:] .* (Xhat[2,:].^p_[1])]
Ybar = transpose([p_[2] * Xhat[1,i] * (Xhat[2,i].^p_[1]) for i ∈ 1:41, j ∈ 1:1])
# Neural network guess
Yhat = U(Xhat, p_trained, st)[1]

pl_reconstruction = plot(ts, transpose(Yhat), xlabel = "t", ylabel = "U(s,i,r)", color = :red,
                         label = ["UDE Approximation" nothing])

plot!(ts, transpose(Ybar), color = :black, label = ["True Interaction" nothing])


# Plot the error
pl_reconstruction_error = plot(ts, norm.(eachcol(Ybar - Yhat)), yaxis = :log, xlabel = "t",
                               ylabel = "L2-Error", label = nothing, color = :red)
pl_missing = plot(pl_reconstruction, pl_reconstruction_error, layout = (2, 1))

pl_overall = plot(pl_trajectory, pl_missing)

