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

struct1 = Struct1(i2_field = 2.0) # this should be fine
@test_throws InexactError Struct1(i2_field = 2.5)
@test_throws AssertionError Struct1(i2_field = 2.0, i1_field = 3)

@test_throws MethodError Struct1(i1_field = "foo")

################################################################################
# convert is called on parameters, more user-friendly than type matching
################################################################################
@defstruct Struct2 (
  field1 :: AbstractString = "",
  field2 :: Vector{AbstractString} = []
)

struct2 = Struct2(field1 = "ascii string")
struct2 = Struct2(field1 = "unicode α-β")
struct2 = Struct2(field2 = ["vector", "of", "ASCII", "string"])

################################################################################
# immutable structs
################################################################################
@defimmutable Struct3 (
  field :: Int = 0
)

struct3 = Struct3()
@test_throws ErrorException (struct3.field = 2)
