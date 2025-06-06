# SciML Tools
using Pkg; Pkg.add.(["OrdinaryDiffEq", "ModelingToolkit", "DataDrivenDiffEq","SciMLSensitivity","DataDrivenSparse"])
using OrdinaryDiffEq, ModelingToolkit, DataDrivenDiffEq, SciMLSensitivity, DataDrivenSparse
using Pkg; Pkg.add.(["Optimization", "OptimizationOptimisers","OptimizationOptimJL"])
using Optimization, OptimizationOptimisers, OptimizationOptimJL

# Standard Libraries
using Pkg; Pkg.add.(["LinearAlgebra", "Statistics"])
using LinearAlgebra, Statistics

# External Libraries
using Pkg; Pkg.add.(["ComponentArrays", "Lux", "Zygote", "StableRNGs"])
using ComponentArrays, Lux, Zygote, Plots, StableRNGs
gr()

# Set a random seed for reproducible behaviour
rng = StableRNG(1111)

function lotka!(du, u, p, t)
    α, β, γ, δ = p 
    du[1] = α * u[1] - β * u[2] * u[1]
    du[2] = γ * u[1] * u[2] - δ * u[2]
end

# Define the experimental parameter
tspan = (0.0, 5.0)
u0 = 5.0f0 * rand(rng, 2)
p_ = [1.3, 0.9, 0.8, 1.8]
prob = ODEProblem(lotka!, u0, tspan, p_)
solution = solve(prob, Vern7(), abstol = 1e-12, reltol = 1e-12, saveat = 0.25)

# Add noise in terms of the mean
X = Array(solution)
t = solution.t

x̄ = mean(X, dims = 2)
noise_magnitude = 5e-3
Xₙ = X .+ (noise_magnitude * x̄) .* randn(rng, eltype(X), size(X))

plot(solution, alpha = 0.75, color = :black, label = ["True Data" nothing])
scatter!(t, transpose(Xₙ), color = :red, label = ["Noisy Data" nothing])