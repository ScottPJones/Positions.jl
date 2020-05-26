"""
Positions package

This provides the `Currency` singleton type, based on the ISO 4167 standard codes,
as well as the `FinancialInstrument` and `AbstractPosition` abstract types,
and the `Cash` and `Position` parameterized types, for dealing with all sorts of
currencies and other financial instruments in an easy fashion.

See README.md for the full documentation

Copyright 2019-2020, Eric Forgy, Scott P. Jones, and other contributors

Licensed under MIT License, see LICENSE.md
"""
module Positions

using FixedPointDecimals

export Position, Currency, Currencies, Cash, AbstractPosition, FinancialInstrument
export currency, cash, unit, code, name

"""
This is an abstract type, for dealing generically with positions of financial instruments
"""
abstract type AbstractPosition end

"""
This is an abstract type for `FinancialInstruments` such as `Cash`, `Stock`,
"""
abstract type FinancialInstrument end

"""
This is a singleton type, intended to be used as a label for dispatch purposes
"""
struct Currency{Symbol} end

# TODO: This should be an inner constructor
Currency{T}() where {T<:Symbol} =
    haskey(Currencies, T) ? Currencies[T] : (Currencies[T] = new())

include(joinpath(dirname(pathof(@__MODULE__)), "..", "deps", "currencies.jl"))

"""
Returns the currency type associated with this value or type
"""
function currency end

"""
Returns the minor unit associated with this value or type
"""
function unit end

"""
Returns the ISO 4167 code associated with this value or type
"""
function code end

"""
Returns the ISO 4167 name associated with this value or type
"""
function name end

currency(::Type{Currency{T}}) where {T} = T
unit(::Type{Currency{T}}) where {T} = Currencies[T][2]
code(::Type{Currency{T}}) where {T} = Currencies[T][3]
name(::Type{Currency{T}}) where {T} = Currencies[T][4]

currency(::Currency{T}) where {T} = T
unit(c::Currency) = unit(typeof(c))
code(c::Currency) = code(typeof(c))
name(c::Currency) = name(typeof(c))

"""
`Cash` is a `FinancialInstrument`, that represents a particular currency as well
as the number of digits in the minor units, typically 0, 2, or 3
"""
struct Cash{C<:Currency, N} <: FinancialInstrument end
Cash(::C) where {C<:Currency} = Cash{C,unit(C)}()
Cash(c::Symbol) = Cash(Currency{c}())

currency(::Type{Cash{C}}) where {C} = C
currency(::Cash{C}) where {C} = C
unit(::Type{Cash{C,N}}) where {C,N} = N
unit(::Cash{C,N}) where {C,N} = N
code(::Cash{C}) where {C} = code(C)
name(::Cash{C}) where {C} = name(C)

Base.show(io::IO, ::Cash{<:Currency{T}}) where {T} = print(io, string(T))

# Set up short names for all of the currencies (as instances of the Cash FinancialInstruments)
for (sym, ccy) in Currencies
    @eval $sym = Cash($(ccy[1]()))
end

"""
Position represents a certain quantity of a particular financial instrument
"""
struct Position{F<:FinancialInstrument,A<:Real} <: AbstractPosition
    amount::A
    function Position(::Type{FI}, a) where {C,N,FI<:Cash{C,N}}
        T = FixedDecimal{Int,N}
        new{FI,T}(T(a))
    end
end

Position(::F, a) where {F<:FinancialInstrument} = Position(F, val)
Position{F}(val) where {F<:FinancialInstrument} = Position(F, val)

"""
Returns the Cash financial instrument (as an instance) for a position
"""
cash(::Position{F}) where {F} = F()

Base.promote_rule(::Type{Position{F,A1}}, ::Type{Position{F,A2}}) where {F,A1,A2} =
    Position{F,promote_type(A1,A2)}
Base.convert(::Type{Position{F,A}}, x::Position{F,A}) where {F,A} = x
Base.convert(::Type{Position{F,A}}, x::Position{F,<:Real}) where {F,A} =
    Position{F,A}(convert(A, x.amount))

Base.:+(p1::Position{F1}, p2::Position{F2}) where {F1,F2} =
    error("Can't add Positions of different FinancialInstruments $(F1()), $(F2())")
Base.:+(p1::Position{F}, p2::Position{F}) where {F} = Position{F}(p1.amount + p2.amount)
Base.:+(p1::AbstractPosition, p2::AbstractPosition) = +(promote(p1, p2)...)

Base.:-(p1::Position{F1}, p2::Position{F2}) where {F1,F2} =
    error("Can't subtract Positions of different FinancialInstruments $(F1()), $(F2())")
Base.:-(p1::Position{F}, p2::Position{F}) where {F} = Position{F}(p1.amount - p2.amount)
Base.:-(p1::AbstractPosition, p2::AbstractPosition) = -(promote(p1, p2)...)

Base.:/(p1::Position, p2::Position) = p1.amount / p2.amount
Base.:/(p1::AbstractPosition, p2::AbstractPosition) = /(promote(p1, p2)...)

Base.:/(p::Position{F}, k::Real) where {F} = Position{F}(p.amount / k)

Base.:*(k::Real, p::Position{F}) where {F} = Position{F}(p.amount * k)
Base.:*(p::Position, k::Real) = k * p

Base.:*(val::Real, c::Cash) = Position{typeof(c)}(val)

Base.show(io::IO, p::Position) = print(io, p.amount, cash(p))
Base.show(io::IO, ::MIME"text/plain", p::Position) = print(io, p.amount, cash(p))

Base.zero(::Type{Position{F,A}}) where {F,A} = Position{F,A}(zero(A))
Base.one(::Type{Position{F,A}}) where {F,A} = Position{F,A}(one(A))

end # module Positions
