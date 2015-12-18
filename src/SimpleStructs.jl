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


function _contains_type_param(expr, tp::AbstractVector)
  for t in tp
    if _contains_type_param(expr, t)
      return true
    end
  end
  return false
end

function _contains_type_param(expr, tp::Symbol)
  if isa(expr, Symbol)
    return expr == tp
  else
    for t in expr.args
      if _contains_type_param(t, tp)
        return true
      end
    end
  end
  return false
end

function _type_param_name(expr)
  if isa(expr, Symbol)
    expr
  else
    @assert isa(expr, Expr) && expr.head == :<:
    expr.args[1]
  end
end

function _name_to_call(name; func_name=nothing)
    if isa(name, Expr) && name.head == :curly
        type_param_names = map(_type_param_name, name.args[2:end])
        Expr(:curly, isa(func_name, Void)? name.args[1] : func_name, type_param_names...)
    else
        isa(func_name, Void)? name : func_name
    end
end

# from Foo{T,T2<:Real} to Foo{T,T2}
function _name_to_type(name)
  if isa(name, Expr) && name.head == :curly
    Expr(:curly, name.args[1], map(x -> isa(x,Symbol)?x:x.args[1], name.args[2:end])...)
  else
    name
  end
end

function _defstruct_impl(is_immutable, name, fields)
  if isa(fields, Expr) && fields.head == :tuple
    fields = fields.args
  else
    fields = [fields]
  end
  @assert length(fields) > 0

  type_param_names = Array(Symbol, 0)

  if isa(name, Symbol)
    super_name = :Any
    name       = name
  elseif isa(name, Expr) && name.head == :curly
    type_param_names = map(_type_param_name, name.args[2:end]) # :T
    super_name = :Any
    name       = name
  else
    @assert(isa(name, Expr) && name.head == :comparison && length(name.args) == 3 && name.args[2] == :(<:),
            "name must be of form 'Name <: SuperType'")
    #@assert(isa(name.args[1], Symbol) && isa(name.args[3], Symbol))
    if isa(name.args[1], Expr) && name.args[1].head == :curly
        type_param_names = map(_type_param_name, name.args[1].args[2:end]) # :T
    end
    super_name = name.args[3]
    name       = name.args[1]
  end

  field_defs     = Array(Expr, length(fields))        # :(field2 :: Int)
  field_names    = Array(Symbol, length(fields))      # :field2
  field_defaults = Array(Expr, length(fields))        # :(field2 = 0)
  field_types    = Array(Any, length(fields))         # Int
  field_asserts  = Array(Expr, length(fields))        # :(field2 >= 0)
  required_field = Symbol[]

  for i = 1:length(fields)
    field = fields[i]
    if field.head == :tuple
      field_asserts[i] = field.args[2]
      field = field.args[1]
    end
    if field.head == :(=)
      fname             = field.args[1].args[1]
      field_defs[i]     = field.args[1]
      field_names[i]    = fname
      field_types[i]    = field.args[1].args[2]
      if _contains_type_param(field.args[1].args[2], type_param_names)
        field_defaults[i] = Expr(:kw, Expr(:(::), fname, field.args[1].args[2]), field.args[2])
      else
        field_defaults[i] = Expr(:kw, fname, field.args[2])
      end
    else
      # no default value provided, required field
      fname             = field.args[1]
      field_defs[i]     = field
      field_names[i]    = fname
      field_types[i]    = field.args[2]
      if _contains_type_param(field.args[2], type_param_names)
        field_defaults[i] = Expr(:kw, Expr(:(::), fname, field.args[2]), __Undefined())
      else
        field_defaults[i] = Expr(:kw, fname, __Undefined())
      end
      push!(required_field, fname)
    end
  end

  # body of layer type, defining fields
  type_body = Expr(:block, field_defs...)

  # constructor
  requires = map(required_field) do fname
    :(@assert(!isa($fname, SimpleStructs.__Undefined), "value for " * $(string(fname)) * " is required"))
  end
  converts = map(zip(field_names, field_types)) do param
    f_name, f_type = param
    :($f_name = convert($f_type, $f_name))
  end
  asserts = map(filter(i -> isdefined(field_asserts,i), 1:length(fields))) do i
    :(@assert($(field_asserts[i])))
  end
  construct = Expr(:call, _name_to_call(name), field_names...)
  ctor_body = Expr(:block, requires..., converts..., asserts..., construct)
  ctor_def = Expr(:call, name, Expr(:parameters, field_defaults...))
  ctor = Expr(:(=), ctor_def, ctor_body)

  # Base.show function
  show_fields = map(enumerate(field_names)) do i_fname
    i, fname = i_fname
    sep = i == 1 ? :() : :(print(io, ", "))
    quote
      $sep
      print(io, $(string(fname)), "=")
      show(io, obj.$fname)
    end
  end
  show_fields = Expr(:block, show_fields...)
  defshow = quote
    function $(_name_to_call(name, func_name=:show))(io::IO, obj::$(_name_to_type(name)))
      print(io, typeof(obj))
      print(io, "(")
      $show_fields
      print(io, ")")
    end
  end

  if is_immutable
    s_def =  quote
      immutable $(name) <: $(super_name)
        $type_body
      end
    end
  else
    s_def = quote
      type $(name) <: $(super_name)
        $type_body
      end
    end
  end

  return esc(quote
    $s_def
    $ctor

    import Base.show
    $defshow
  end)
end

end # module
