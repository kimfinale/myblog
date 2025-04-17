# using Flux, Distributions, Random
using Lux, Distributions, Random
# create the data
# true parameter values are 4 and 2
linear_model(x) = rand(Normal(4x+2,1))[1]

x_train, x_test = hcat(0:5...), hcat(6:10...)
y_train, y_test = linear_model.(x_train), linear_model.(x_test)

### Build a model to make predictions

# model = Flux.Dense(1 => 1) # 2 parameters
model = Lux.Dense(1 => 1) # 2 parameters
# let's see the prediction based on the untrained baseline model 
model(x_train)

using Statistics
# define the loss function to use it for training
loss(m, x, y) = mean(abs2.(m(x) .- y))

loss(model, x_train, y_train)


using Flux: train!

opt = Descent()
Descent(0.1)

data = [(x_train, y_train)]

train!(loss, model, data, opt)
loss(model, x_train, y_train2)
model.weight, model.bias

for epoch in 1:200
    train!(loss, model, data, opt)
end

loss(model, x_train, y_train)
model(x_test)
y_test