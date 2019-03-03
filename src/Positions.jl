module Positions

using Reexport
@reexport using FinancialInstruments, FixedPointDecimals
export Position

abstract type AbstractPosition end

struct Position{F<:FinancialInstrument,A<:Real} <: AbstractPosition
    amount::A
end
Position(p::F,a::A) where {F,A} = Position{typeof(p),typeof(a)}(a)
Position(c::Cash{C},a::A) where {C,A} = Position{typeof(c),FixedDecimal{Int,Currencies.unit(C())}}(FixedDecimal{Int,Currencies.unit(C())}(a))

Base.promote_rule(::Type{Position{F1,A1}}, ::Type{Position{F2,A2}}) where {F1,F2,A1,A2} = Position{promote_type(F1,F2),promote_type(A1,A2)}
Base.convert(::Type{Position{F1,A1}}, x::Position{F2,A2}) where {F1,F2,A1,A2} = Position{F1,A1}(convert(A1,x.amount))

Base.:+(p1::Position{F,A},p2::Position{F,A}) where {F,A} = Position{F,A}(p1.amount+p2.amount)
Base.:+(p1::AbstractPosition,p2::AbstractPosition) = +(promote(p1,p2)...)

Base.:-(p1::Position{F,A},p2::Position{F,A}) where {F,A} = Position{F,A}(p1.amount-p2.amount)
Base.:-(p1::AbstractPosition,p2::AbstractPosition) = -(promote(p1,p2)...)

Base.:/(p1::Position{F,A},p2::Position{F,A}) where {F,A} = p1.amount/p2.amount
Base.:/(p1::AbstractPosition,p2::AbstractPosition) = /(promote(p1,p2)...)

# TODO: Should scalar multiplication and division respect the Position type or do normal promotion?

# Base.:/(p::Position{F,A},k::R) where {F,A,R<:Real} = Position{F,promote_type(A,R)}(p.amount/k)
Base.:/(p::Position{F,A},k::R) where {F,A,R<:Real} = Position{F,A}(p.amount/k)

# Base.:*(k::R,p::Position{F,A}) where {F,A,R<:Real} = Position{F,promote_type(A,R)}(p.amount*k)
Base.:*(k::R,p::Position{F,A}) where {F,A,R<:Real} = Position{F,A}(p.amount*k)
Base.:*(p::Position{F,A},k::R) where {F,A,R<:Real} = k*p

Base.show(io::IO,c::Position{Cash{C}}) where C = print(io,c.amount," ",C())
Base.show(io::IO,::MIME"text/plain",c::Position{Cash{C}}) where C = print(io,c.amount," ",C())

end # module
