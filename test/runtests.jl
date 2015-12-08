using SimpleStructs
using Base.Test

# write your own tests here
abstract DummyType

################################################################################
# default values, type assert, value constraints
################################################################################
@defstruct Struct1 <: DummyType (
  i1_field   :: Int = 0,
  (pos_field :: Float64 = 1, pos_field > 0),
  (i2_field  :: Int = 0, i2_field >= i1_field)
)

struct1 = Struct1()
@test isa(struct1, Struct1)
@test isa(struct1, DummyType)

@test struct1.i1_field == 0

@test isa(Struct1(i2_field = 2.0), Struct1)
@test_throws InexactError Struct1(i2_field = 2.5)
@test_throws AssertionError Struct1(i2_field = 2.0, i1_field = 3)

@test_throws MethodError Struct1(i1_field = "foo")

################################################################################
# required fields
################################################################################
@defstruct Struct2 (
  i_field   :: Int,
  (i_field2 :: Int, i_field2 > 0),
  i_field3  :: Int = -1
)

@test_throws AssertionError Struct2()
@test_throws AssertionError Struct2(i_field=0)
@test_throws AssertionError Struct2(i_field=0, i_field2=0)
@test isa(Struct2(i_field=0, i_field2=1), Struct2)

################################################################################
# convert is called on parameters, more user-friendly than type matching
################################################################################
@defstruct Struct3 (
  field1 :: AbstractString = "",
  field2 :: Vector{AbstractString} = []
)

struct3 = Struct3(field1 = "ascii string")
struct3 = Struct3(field1 = "unicode α-β")
struct3 = Struct3(field2 = ["vector", "of", "ASCII", "string"])

################################################################################
# immutable structs
################################################################################
@defimmutable Struct4 (
  field :: Int = 0
)

struct4 = Struct4()
@test_throws ErrorException (struct4.field = 2)

################################################################################
# type parameters
################################################################################
@defimmutable Struct5{R<:Real, T<:Real} (
  field  :: Vector{R},
  field2 :: Vector{T} = zeros(5),
)
@test_throws MethodError struct5 = Struct5()
struct5 = Struct5(field = [1,2,3])
@test typeof(struct5.field) <: Vector{Int}
@test typeof(struct5.field2) <: Vector{Float64}
