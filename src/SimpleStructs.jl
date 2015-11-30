__precompile__()

module SimpleStructs

export @defstruct, @defimmutable

"""A convenient macro copied from Mocha.jl that could be used to define structs
with default values and type checks. For example
```julia
@defstruct MyStruct (
  field1 :: Int = 0,
  (field2 :: AbstractString = "", !isempty(field2))
)
```
where each field could be either
```julia
field_name :: field_type = default_value
```
or put within a tuple, with the second element
specifying a validation check on the field value.
In the example above, the default value for
field2 does not satisfy the assertion, this
could be used to force user to provide a
valid value when no meaningful default value
is available.
The macro will define a constructor that could accept
the keyword arguments.
"""
macro defstruct(name, fields)
  _defstruct_impl(false, name, fields)
end

"""A convenient macro to define immutable structs. The same as
`@defstruct` except that the defined type is immutable.
"""
macro defimmutable(name, fields)
  _defstruct_impl(true, name, fields)
end

"""Internal use only, this value is used to indicate a required value
is not specified.
"""
immutable __Undefined
end

function _defstruct_impl(is_immutable, name, fields)
  if isa(fields, Expr) && fields.head == :tuple
    fields = fields.args
  else
    fields = [fields]
  end
  @assert length(fields) > 0

  if isa(name, Symbol)
    name       = esc(name)
    super_name = :Any
  else
    @assert(isa(name, Expr) && name.head == :comparison && length(name.args) == 3 && name.args[2] == :(<:),
            "name must be of form 'Name <: SuperType'")
    @assert(isa(name.args[1], Symbol) && isa(name.args[3], Symbol))
    super_name = esc(name.args[3])
    name       = esc(name.args[1])
  end

  field_defs     = Array(Expr, length(fields))        # :(field2 :: Int)
  field_names    = Array(Expr, length(fields))        # :field2
  field_defaults = Array(Expr, length(fields))        # :(field2 = 0)
  field_types    = Array(Expr, length(fields))        # Int
  field_asserts  = Array(Expr, length(fields))        # :(field2 >= 0)
  required_field = Symbol[]

  for i = 1:length(fields)
    field = fields[i]
    if field.head == :tuple
      field_asserts[i] = esc(field.args[2])
      field = field.args[1]
    end
    if field.head == :(=)
      fname             = field.args[1].args[1]
      field_defs[i]     = esc(field.args[1])
      field_names[i]    = esc(fname)
      field_types[i]    = esc(field.args[1].args[2])
      field_defaults[i] = Expr(:kw, fname, esc(field.args[2]))
    else
      # no default value provided, required field
      fname             = field.args[1]
      field_defs[i]     = esc(field)
      field_names[i]    = esc(fname)
      field_types[i]    = esc(field.args[2])
      field_defaults[i] = Expr(:kw, fname, __Undefined())
      push!(required_field, fname)
    end
  end

  # body of layer type, defining fields
  type_body = Expr(:block, field_defs...)

  # constructor
  requires = map(required_field) do fname
    :(@assert(!isa($fname, __Undefined), "value for " * string($fname) * " is required"))
  end
  converts = map(zip(field_names, field_types)) do param
    f_name, f_type = param
    :($f_name = convert($f_type, $f_name))
  end
  asserts = map(filter(i -> isdefined(field_asserts,i), 1:length(fields))) do i
    :(@assert($(field_asserts[i])))
  end
  construct = Expr(:call, name, field_names...)
  ctor_body = Expr(:block, requires..., converts..., asserts..., construct)
  ctor_def = Expr(:call, name, Expr(:parameters, field_defaults...))
  ctor = Expr(:(=), ctor_def, ctor_body)

  if is_immutable
    quote
      immutable $(name) <: $(super_name)
        $type_body
      end

      $ctor
    end
  else
    quote
      type $(name) <: $(super_name)
        $type_body
      end

      $ctor
    end
  end
end

end # module
