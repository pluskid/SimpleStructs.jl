# SimpleStructs

[![Build Status](https://travis-ci.org/pluskid/SimpleStructs.jl.svg?branch=master)](https://travis-ci.org/pluskid/SimpleStructs.jl)

This is a simple utility of defining structs by specifying types, default values and value constraints for fields, with
an automatically defined user-friendly constructor. This code is extracted from [Mocha.jl](https://github.com/pluskid/Mocha.jl)
and [MXNet.jl](https://github.com/dmlc/MXNet.jl).

This utility is useful to define structs holding specifications or hyperparameters. The following is an example of specifications
of a stochastic gradient descent optimizer used in MXNet.jl:

```julia
@defstruct SGDOptions <: AbstractOptimizerOptions (
  (lr                :: Real = 0.01, lr > 0),
  (momentum          :: Real = 0.0, momentum >= 0),
  (grad_clip         :: Real = 0, grad_clip >= 0),
  (weight_decay      :: Real = 0.0001, weight_decay >= 0),
  lr_scheduler       :: Any  = nothing,
  momentum_scheduler :: Any  = nothing
)
```
And this is an example of the definition of a Dropout layer in Mocha.jl:

```julia
@defstruct DropoutLayer <: Layer (
  name       :: AbstractString = "dropout",
  auto_scale :: Bool = true,
  (ratio     :: AbstractFloat = 0.5, 0 < ratio < 1),
  (bottoms   :: Vector{Symbol} = Symbol[], length(bottoms) == 1),
)
```
