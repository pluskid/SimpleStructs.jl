# SimpleStructs

[![Build Status](https://travis-ci.org/pluskid/SimpleStructs.jl.svg?branch=master)](https://travis-ci.org/pluskid/SimpleStructs.jl)
[![Windows Build status](https://ci.appveyor.com/api/projects/status/u6ew8y036f68i4cs?svg=true)](https://ci.appveyor.com/project/pluskid/simplestructs-jl)
[![SimpleStructs](http://pkg.julialang.org/badges/SimpleStructs_0.4.svg)](http://pkg.julialang.org/?pkg=SimpleStructs)
[![SimpleStructs](http://pkg.julialang.org/badges/SimpleStructs_0.5.svg)](http://pkg.julialang.org/?pkg=SimpleStructs)
[![GitHub license](https://img.shields.io/github/license/pluskid/SimpleStructs.jl.svg)](LICENSE.md)

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

## API

The main utilities provided by this package are two macros: `@defstruct` and `@defimmutable`.
They are almost the same, except that the latter defines a type that is
[immutable](http://docs.julialang.org/en/latest/manual/types/#immutable-composite-types).
The macros can be called in the following way

```julia
@defstruct StructName (
  field_name :: field_type,
  (fname2    :: ftype2 = default_val2, fname2 > 0 && fname2 < 5),
  (fname3    :: ftype3 = default_val3, fname3 <= fname2),
)
```

The `StructName` can be `StructName <: SuperTypeName` if the struct needs to be a subtype of
`SuperTypeName`. Each field should have

* field name: the name of the field.
* field type: the type used to store the field value. Note the constructor accept any value type, and calls `convert` explicitly on the user supplied values. So there is no frustration about Julia types being not [covariant](https://en.wikipedia.org/wiki/Covariance_and_contravariance_(computer_science)). For example, for a field of type `Vector{AbstractString}`, it is OK if user call with `["foo", "bar"]`, which will be of type `Vector{ASCIIString}`.
* field default value: this is optional. When a default value is not presented, it means the field is *required*. An `AssertionError` will be thrown if the user does not provide a value for this field.
* field value constraints: this is optional. Value constraints can be used to ensure the user supplied values are reasonable. Note the constraints are asserted in the order as the fields are defined. So in the example above, the constraint for `fname3` can use the value for `fname2` and safely assume the constraints for `fname2` is already satisfied.

A constructor will be automatically defined, where each argument should be provided as keyword arguments:

```julia
struct = StructName(field_name=7, fname3=8)
```

Please see [the unit tests](test/runtests.jl) for more examples.
