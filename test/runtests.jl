using SimpleStructs
using Base.Test

# write your own tests here
abstract DummyType

@defstruct Struct1 DummyType (
  i1_field   :: Int = 0,
  (pos_field :: Float64 = 1, pos_field > 0),
  (i2_field  :: Int = 0, i2_field >= i1_field)
)

struct1 = Struct1()
@test isa(struct1, Struct1)
@test isa(struct1, DummyType)

struct1 = Struct1(i2_field = 2.0) # this should be fine
@test_throws InexactError Struct1(i2_field = 2.5)
@test_throws AssertionError Struct1(i2_field = 2.0, i1_field = 3)
