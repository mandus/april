⍝⍝ Ported from http://dfns.dyalog.com/n_contents.htm into April APL


⍝⍝ Whole number processing

⍝ From http://dfns.dyalog.com/c_adic.htm

adic ← { ⎕IO←0                               ⍝ Bijective base-⍺ numeration.
  b←⍬⍴⍴a←,⍺                                  ⍝ base and alphabet

  1=⍴⍴⍵:b⊥1+a⍳⍵                              ⍝ vector: decode digs → number
                                             ⍝ scalar: encode number → digs
  1=b:⍵/⍺                                    ⍝ unary: special case
  n←⌊b⍟1+⍵×b-1                               ⍝ number of digits
  z←(¯1+b*n)÷b-1                             ⍝ smallest integer with length n
  a[(n/b)⊤⍵-z]                               ⍝ digits from alphabet ⍺.
}

⍝ From http://dfns.dyalog.com/c_apportion.htm

apportion ← {                                ⍝ Huntington-Hill apportionment.
  ⍺←435                                      ⍝ default number of seats
  ⍵{                                         ⍝ population per state
    d←(⍵×⍵+1)*0.5                            ⍝ divisor
    cs←⍺÷d                                   ⍝ priority value
    ⍵+cs=⌈/cs                                ⍝ next seat allocation
  }⍣(⍺-≢⍵),1                                 ⍝ iterated per remaining seat.
}

⍝ From http://dfns.dyalog.com/c_bsearch.htm

bsearch ← {                                  ⍝ Binary search: least n in range ⍵ with ⍺⍺ n.
  ¯1≤-/⍵:1↑⍵+2-+/⍺⍺¨⍵                        ⍝ convergence: finished.
  mid←⌈0.5×+/⍵                               ⍝ Mid point:
  ⍺⍺ mid:∇(1↑⍵),mid                          ⍝ 1: search lower half.
         ∇ mid ,1↓⍵                          ⍝ 0: search upper half.
}

⍝ From http://dfns.dyalog.com/c_cfract.htm

cfract ← {                                   ⍝ Continued fraction approximation of real ⍵.
  ⍝ ⍺←⎕CT ⋄ ⎕CT←⍺                            ⍝ default comparison tolerance.
  ,↑{                                        ⍝ cf from rational ⍺÷⍵:
    ⍵=1:⍺                                    ⍝ whole number: finished.
    n r←0 ⍵⊤⍺                                ⍝ next term and remainder.
    n,⍵∇r                                    ⍝ next term and cf of remainder.
  }/⌊⎕CT+⍵ 1÷1∨⍵                             ⍝ whole number ratio.
}

⍝ From http://dfns.dyalog.com/c_colsum.htm

colsum ← {                                   ⍝ Sum of (default decimal) columns.
  ⍺←10 ⋄ ⍺{{(0=⍬⍴⍵)↓⍵}+⌿1 0⌽0,0 ⍺⊤⍵}⍣≡+⌿⍵    ⍝ repeat while overflow.
}

⍝ From http://dfns.dyalog.com/c_efract.htm

efract ← {                                   ⍝ Egyptian fractions: Fibonacci-Sylvester algorithm
  ⍬{
    (p q)←⍵÷∨/⍵
    p=1:⍺,q

    r←p|q ⋄ s←(q-r)÷p
    (⍺,s+1)∇(p-r)(q×s+1)
  }⍺ ⍵
}

⍝ From http://dfns.dyalog.com/c_factorial.htm

factorial ← { ⍺←1 ⋄ $[⍵=0;⍺;(⍺×⍵)∇ ⍵-1] }    ⍝ Tail recursive factorial.

⍝ From http://dfns.dyalog.com/c_fibonacci.htm

fibonacci ← { ⍺←0 1                          ⍝ Tail-recursive Fibonacci.
  ⍵=0:⍬⍴⍺ ⋄ (1↓⍺,+/⍺)∇ ⍵-1
}

sulFib ← {                                   ⍝ Sullivan Fibonacci
  z←0.5×1+s←5*0.5
  ((z*⍵)-(2○○⍵)×z*-⍵)÷s
}

⍝ From http://dfns.dyalog.com/c_factors.htm

factors ← { ⎕IO←1                            ⍝ Prime factors of ⍵.
  ⍵{                                         ⍝ note: ⎕wa>(⍵*÷2)×2*4.
    ⍵,(⍺÷×/⍵)~1                              ⍝ append factor > sqrt(⍵).
  }∊⍵{                                       ⍝ concatenated,
    (0=(⍵*⍳⌊⍵⍟⍺)|⍺)/⍵                        ⍝ powers of each prime factor.
  }¨⍬{                                       ⍝ remove multiples:
    nxt←⊃⍵                                   ⍝ next prime, and
    msk←0≠nxt|⍵                              ⍝ ... mask of non-multiples.
    ∧/1↓msk:⍺,⍵                              ⍝ all non multiples - finished.
    (⍺,nxt)∇ msk/⍵                           ⍝ sieve remainder.
  }⍵{                                        ⍝ from,
    (0=⍵|⍺)/⍵                                ⍝ divisors of ⍵ in:
  }2,(1+2×⍳⌊0.5×⍵*÷2),⍵                      ⍝ 2,3 5 .. sqrt(⍵),⍵
}

⍝ From http://dfns.dyalog.com/c_gcd.htm

gcd ← { ⍵=0 : |⍺ ⋄ ⍵∇⍵|⍺ }                   ⍝ Greatest common divisor.

lcm ← { ⍺×⍵÷⍺ gcd ⍵ }                        ⍝ Least common multiple.

⍝ From http://dfns.dyalog.com/c_k6174.htm

k6174 ← {                                    ⍝ Kaprekar's operation.
  enco←(4/10)∘⊤                              ⍝ 4-digit encode.
  deco←enco⍣¯1                               ⍝   and decode.
  1=⍴∪enco ⍵:'error'                         ⍝ all digits the same: no go.
  ⍬{                                         ⍝ starting with null sequence.
    ⍵=⊃⌽⍺:⍺                                  ⍝ repeated items: done.
    v←{⍵[⍒⍵]}enco ⍵                          ⍝ digits in descending order.
    (⍺,⍵)∇(deco v)-deco⌽v                    ⍝ smaller to larger difference.
  }⍵                                         ⍝ :: [#] ∇ # → [#]
}

⍝ From http://dfns.dyalog.com/c_hex.htm

hex ← { ⎕CT ⎕IO←0                            ⍝ Hexadecimal from decimal.
  ⍺←⊢                                        ⍝ no width specification.
  1≠≡,⍵:⍺ ∇¨⍵                                ⍝ simple-array-wise:
  1∊⍵=1+⍵:'Too big'                          ⍝ loss of precision.
  n←⍬⍴⍺,2*⌈2⍟2⌈16⍟1+⌈/|⍵                     ⍝ default width.
  ↓[0]'0123456789abcdef'[(n/16)⊤⍵]           ⍝ character hex numbers.
}

⍝ From http://dfns.dyalog.com/c_dec.htm

dec ← { ⎕IO←0                                ⍝ Decimal from hexadecimal
  ⍺←0                                        ⍝ unsigned by default.
  1<⍴⍴⍵:⍺∘∇⍤1⊢⍵                              ⍝ vector-wise:
  0≡≢⍵:0                                     ⍝ dec'' → 0.
  1≠≡,⍵:⍺ ∇¨⍵                                ⍝ simple-array-wise:
  ws←∊∘(⎕UCS 9 10 13 32 133 160)             ⍝ white-space?
  ws⊃⍵:⍺ ∇ 1↓⍵                               ⍝ ignoring leading and
  ws⊃⌽⍵:⍺ ∇ ¯1↓⍵                             ⍝ ... trailing blanks.
  ∨/ws ⍵:⍺ ∇¨(1+ws ⍵)⊆⍵                      ⍝ white-space-separated:
  v←16|'0123456789abcdef0123456789ABCDEF'⍳⍵  ⍝ hex digits.
  ⍝ 11::'Too big'⎕SIGNAL 11                  ⍝ number too big.
  (16⊥v)-⍺×(8≤⊃v)×16*≢v                      ⍝ (signed) decimal number.
}

⍝ From http://dfns.dyalog.com/c_int.htm

int ← { ↑⍵{(⍺|⍶+⍵)-⍵}/2*⍺-0 1 }              ⍝ Signed from unsigned integer.

⍝ From http://dfns.dyalog.com/c_uns.htm

uns ← { (2*⍺)|⍵ }                            ⍝ Unsigned from signed integer.

⍝ From http://dfns.dyalog.com/c_nicediv.htm

nicediv ← {                                  ⍝ ⍵ similar integers with sum ⍺.
  q←⍵⍴⌊⍺÷⍵                                   ⍝ quotient.
  d←+\(⍵|⍺)÷⍵⍴⍵                              ⍝ residue spread in ⍵ decimal steps.
  i←2</0,⌊0.5+d                              ⍝ residue spread in ⍵ integer steps.
  q+i
}

⍝ From http://dfns.dyalog.com/s_nicediv.htm

stack ← { ⍉↑( ⍺ nicediv ⍵)/¨'⎕' }

osc ← { 1=⍵ : 1 ⋄ 2|⍵ : ∇ 1+3×⍵ ⋄ ∇ ⍵÷2 }    ⍝ Oscillate - probably returns 1.

⍝ From http://dfns.dyalog.com/c_range.htm

range ← { (⍴⍵)⍴((⍴⍺)↓⍋⍋⍺,,⍵)-⍋⍋,⍵ }          ⍝ Numeric range classification.

⍝ From http://dfns.dyalog.com/c_rational.htm

rational ← {                                 ⍝ Rational approximation to real ⍵.
  ⍺←⎕CT ⋄ ⎕CT←⍺                              ⍝ default comparison tolerance.
  ↑⍵ 1÷⊂1∨⍵                                  ⍝ rational pair: ⍵≡÷⌿rational ⍵.
}

⍝ From http://dfns.dyalog.com/c_roman.htm

roman ← {                                    ⍝ Roman numeral arithmetic.

  num←{⎕IO←0 ⋄ {⍵+.××0.5+×⍵-1↓⍵,0}(,⍉1 5∘.×10*⍳4)[7|'IVXLCDMivxlcdm'⍳⍵]}
  fmt←{⎕IO←0 ⋄ ~∘' ',1 0 0⍉(' '⍪3 4⍴'MCXI DLV ')[(0 4 2 2⊤0 16 20 22 24 32 36 38 39 28)[;⍵⊤⍨4⍴10];]}

  depth←{⍹≥|≡⍵ : ⍺⍺ ⍵ ⋄ ∇¨⍵}                 ⍝ apply function ⍺⍺ at depth ⍵⍵.

  nums←num depth 1                           ⍝ arabic from roman.
  fmts←fmt depth 0                           ⍝ roman from arabic.

  ⍬≡⍺←⍬:fmts ⍺⍺ ⌊nums ⍵                      ⍝ monadic operand function.
  fmts(⌊nums ⍺)⍺⍺ ⌊nums ⍵                    ⍝ dyadic operand function.
}

⍝ From http://dfns.dyalog.com/n_path.htm

path ← {                                     ⍝ Shortest path from/to ⍵ in graph ⍺.
  graph(fm tto)←⍺ ⍵                          ⍝ graph and entry/exit vertex vectors
  fm{                                        ⍝ fm is the starting-from vertex
    ⍺≡⍬:⍬                                    ⍝ no vertices left: no path
    ∨/tto∊⍺:⍬(⊃∘⍵){                          ⍝ found target: path from tree:
      ⍵<0:⍺                                  ⍝ root: finished
      (⍵,⍺)∇ ⍺⍺ ⍵                            ⍝ accumulated path to next vertex
    }1↑⍺∩tto                                 ⍝ found vertex ⍺
    next←graph[⍺]∩¨⊂⍸⍵=¯2                    ⍝ next vertices to visit
    back←⊃,/⍺+0×next                         ⍝ back links
    wave←⊃,/next                             ⍝ vertex wave front
    (∪wave)∇ back@wave⊢⍵                     ⍝ advanced wave front
  }¯2+(⍳⍴⍺)∊fm                               ⍝ null spanning tree
}

⍝ From http://dfns.dyalog.com/c_stamps.htm

stamps ← {                                   ⍝ Postage stamps to the value of ⍵.
  ⍺←1 5 6 10 26 39 43                        ⍝ Default UK stamp denominations.
  graph←⍺{⍵∘∩¨⍵+⊂⍺}⍳⍵+|⌊/⍺                   ⍝ values: 0 ·· ⍵.
  spath←graph path ⎕IO+0 ⍵                   ⍝ shortest path 0→⍵.
  ¯2-/spath                                  ⍝ best-fit stamps.
}

⍝ From http://dfns.dyalog.com/c_sieve.htm

sieve ← {                                    ⍝ Sieve of Eratosthenes.
  ⍺←⍬                                        ⍝ Default no primes yet.
  nxt←1↑⍵                                    ⍝ Next prime, and
  msk←0≠nxt|⍵                                ⍝ ... mask of non-multiples.
  ∧/1↓msk:⍺,⍵                                ⍝ All non multiples - finished.
  (⍺,nxt)∇ msk/⍵                             ⍝ Sieve remainder.
}

⍝ From http://dfns.dyalog.com/c_to.htm

to ← { ⎕IO←0                                 ⍝ Sequence ⍺ .. ⍵
  from step←1 ¯1×-\2↑⍺,⍺+×⍵-⍺                ⍝ step default is +/- 1.
  from+step×⍳0⌈1+⌊(⍵-from)÷step+step=0       ⍝ ⍺ thru ⍵ inclusive.
}

⍝ From http://dfns.dyalog.com/s_to.htm

xTo ← {                                      ⍝ Sequence ⍺ .. ⍵
  from step←⊂¨1 ¯1×-\2↑⍺,⍺+×⍵-⍺              ⍝ step default is +/- 1.
  size←0⌈1+⌊⊃(⍵-from)÷step+step=0            ⍝ shape of result
  from+step×(⍳size)-⎕IO                      ⍝ ⍺ thru ⍵ inclusive.
}


⍝⍝ Real number processing

⍝ From http://dfns.dyalog.com/n_abc.htm

bp ← {⊃(⍺<⍵)(⍺>⍵)}                           ⍝ Boolean pair (2-vector)

xd ← {×⍺-⍵}                                  ⍝ Signum difference

bd ← {(⍺>⍵)-(⍺<⍵)}                           ⍝ Boolean difference

rg ← {(⍺[1]⍺⍺ ⍵)∧⍺[2]⍵⍵ ⍵}                   ⍝ Range operator

xp ← {×/×⍵∘.-⍺}                              ⍝ Signum product

xs ← {+/×⍵∘.-⍺}                              ⍝ Signum sum

xm ← {⌈/↑×⌿×⍺,.-⍉⍵}                          ⍝ Max signum

xr ← {d←⍉↑+/×⍵,.-⍉⍺ ⋄ ((2∨.=|d)/d)←2 ⋄ 3⊥d}  ⍝ Outside location

⍝ From http://dfns.dyalog.com/c_alt.htm

alt ← {                                      ⍝ Alternant.
  r c←⍴⍵                                     ⍝ matrix ⍵
  0=r:⍵⍵⌿,⍵                                  ⍝ zero-row case
  1≥c:⍺⍺⌿,⍵                                  ⍝ zero/one-column case
  M←~⍤1 0⍨⍳r                                 ⍝ minors
  ⍵[;⎕IO]⍺⍺.⍵⍵(∇⍤2)⍵[M;1↓⍳c]
}

bayes ← { ⍺(×÷+.×)⍵ }                        ⍝ Bayes' formula. (implemented as a fork)

⍝ From http://dfns.dyalog.com/c_Cholesky.htm

Cholesky ← {                                 ⍝ decomposition of a Hermitian positive-definite matrix.
  1≥n←≢⍵:⍵*0.5
  p←⌈n÷2
  q←⌊n÷2
  X←(p,p)↑⍵⊣Y←(p,-q)↑⍵⊣Z←(-q,q)↑⍵
  L0←∇ X
  L1←∇ Z-(TT←(+⍉Y)+.×⌹X)+.×Y
  ((p,n)↑L0)⍪(TT+.×L0),L1
}

⍝ From http://dfns.dyalog.com/c_det.htm

det ← { ⎕IO←0                                ⍝ Determinant of square matrix.
  ⍺←1                                        ⍝ product of co-factor coefficients so far
  0=n←≢⍵:⍺                                   ⍝ result for 0-by-0
  i j←(⍴⍵)⊤{⍵⍳⌈/⍵}|,⍵                        ⍝ row and column index of maximal element
  k←⍳n
  (⍺×⍵[i;j]×¯1*i+j)∇ ⍵[k~i;k~j]-⍵[k~i;j]∘.×⍵[i;k~j]÷⍵[i;j]
}

⍝ From http://dfns.dyalog.com/c_gauss_jordan.htm

gauss_jordan ← { ⎕IO←0                       ⍝ Gauss-Jordan elimination.
  elim←{                                     ⍝ elimination of row/col ⍺
    p←⍺+{⍵⍳⌈/⍵}|⍺↓⍵[;⍺]                      ⍝ index of pivot row
    swap←⊖@⍺ p⊢⍵                             ⍝ ⍺th and pth rows exchanged
    mat←swap[⍺;⍺]÷⍨@⍺⊢swap                   ⍝ col diagonal reduced to 1
    mat-(mat[;⍺]×⍺≠⍳≢⍵)∘.×mat[⍺;]            ⍝ col off-diagonals reduced to 0
  }

  ⍺←=/↑⍳⍴⍵                                   ⍝ id matrix for monadic case
  (⍴⍺)⍴(0 1×⍴⍵)↓↑elim/(⌽⍳⌊/⍴⍵),⊂⍵,⍺          ⍝ elimination/ ··· 2 1 0 (⍵,⍺)
}

⍝ From http://dfns.dyalog.com/s_gauss_jordan.htm

tryGJ ← { ⍺←⊢                                ⍝ gauss_jordan vs primitive ⌹.
  ⎕CT←1e¯13                                  ⍝ slightly more tolerant comparison.
  fuzz0←{↑⍺⍺/⍺ ⍵+⎕CT>|⍺ ⍵}                   ⍝ 0-fuzzy comparison.
  (⍺⌹⍵)≡fuzz0 ⍺ gauss_jordan ⍵
}

⍝ From http://dfns.dyalog.com/s_gauss_jordan.htm

hil ← {÷1+∘.+⍨(⍳⍵)-⎕IO}                      ⍝ order ⍵ Hilbert matrix.

⍝ From http://dfns.dyalog.com/c_kcell.htm

kcell ← {                                    ⍝ Relationship between point and k-cell.
  ⍺←(≢⍵)/2 1⍴0 1                             ⍝ Default is unit k-cell.
  b←,[(2=⍴⍴⍺)/⎕IO]⍺                          ⍝ Bounds of k-cell.
  p←((2⌊⍴⍴⍺)↓1 1,⍴⍵)⍴⍵                       ⍝ Points to evaluate.
  d←↑,¨⍺⍺⌿×-b,.-p                            ⍝ Apply operand to signum difference.
  ⍺⍺/⍬:⌈/d ⋄ 5⊥⍉d                            ⍝ Result is {¯1,0,1} or integer.
}

⍝ From http://dfns.dyalog.com/c_kball.htm

kball ← {                                    ⍝ Relationship between point and k-ball.
  ⍺←1
  r←⊃⍺ ⋄ p←1/⍵                               ⍝ Default is ball w/radius 1 at origin.
  c←(≢p)↑1↓⍺                                 ⍝ Remaining coordinates are center.
  ×↑-/(⍉p-[⎕IO]c)r+.*¨2                      ⍝ Perform signum difference.
}

⍝ ⍝ From http://dfns.dyalog.com/c_ksphere.htm

ksphere ← {                                  ⍝ Surface area of k-sphere.
  n←⍺+1                                      ⍝ dimension of enclosed k-ball.
  pi←(○1)*n÷2                                ⍝ power of pi.
  n×(⍵*⍺)×pi÷!n÷2                            ⍝ k-sphere surface area.
}

⍝ From http://dfns.dyalog.com/s_ksphere.htm

kvol ← { ⍵×((⍺-1) ksphere ⍵)÷⍺ }

⍝ From http://dfns.dyalog.com/c_mean.htm

mean ← { sum←+/⍵ ⋄ num←⍴⍵ ⋄ sum÷num }        ⍝ Arithmetic mean.

⍝ From http://dfns.dyalog.com/s_mean.htm

stdev ← {
  square←*∘2 ⋄ sqrt←*∘0.5
  sqrt(mean square ⍵)-square mean ⍵
}

⍝ From http://dfns.dyalog.com/c_NormRand.htm

NormRand ← {                                 ⍝ Random numbers with a normal distribution
  depth←10*9                                 ⍝ randomness depth - can be larger from v14.0
  (x y)←⊂[1+⍳⍴,⍵](?(2,⍵)⍴depth)÷depth        ⍝ two random variables within ]0;1]
  ((¯2×⍟x)*0.5)×1○○2×y                       ⍝ Box-Muller distribution
}

⍝ From http://dfns.dyalog.com/c_phinary.htm
⍝ TODO: Loose comparison tolerance is needed here, why?
phinary ← { ⎕IO ⎕CT←0 0.001                  ⍝ Phinary representation of numbers ⍵.
  ⍺←1                                        ⍝ result formatted by default.
  P←(1+5*÷2)÷2                               ⍝ Phi.
  $[''≡0/∊⍵;{                                ⍝ char array: inverse: phinary → decimal.
      1<|≡⍵:∇¨⍵                              ⍝ nested: decode each.
      '¯'=⊃⍵:-∇ 1↓⍵                          ⍝ -ive: negation of inverse of +ive.
      a←P⊥⎕D⍳⍵~'.'                           ⍝ phi decode of ⍵.
      a÷P*(≢⍵∪'.')-1+(,⍵)⍳'.'                ⍝ adjusted by posn of phinary point.
    }⍵;                                      ⍝ ⍵ is char vect phinary number.
    0≠≡⍵;⍺ ∇¨⍵;                              ⍝ higher rank, depth: encode each.
    ⍵<0;'¯',⍺ ∇-⍵;                           ⍝ negative.
    num←⍵                                    ⍝ target number.
    ⍺{                                       ⍝ format of powers of phi.
      ⍺=0:⍵                                  ⍝ no formatting: raw powers.
      ⍵≡⍬:,'0'                               ⍝ '0' better than '.'.
      fmt←⌷∘'01'∘⊂                           ⍝ format '1010...'
      lft←(⌽⍳0⌈1+⌈/⍵)∊⍵                      ⍝ digits to the left of '.'
      rgt←(¯1-⍳0⌈|⌊/⍵)∊⍵                     ⍝   ..      ..  right   ..
      $[rgt∧.=0;fmt lft;                     ⍝ all +ive: no phinary point.
        lft∧.=0;'0.',fmt rgt;                ⍝ all -ive: leading '0.'
        (fmt lft),'.',fmt rgt                ⍝ both: point-separated digits.
       ]
    }⍬{                                      ⍝ accumulated powers of phi.
      num=P+.*⍺:⍺                            ⍝ convergence: done.
      ∆←(-⍴⍺)↑1                              ⍝ delta (1 in least sig place)
      num=P+.*⍺+∆:⍺+∆                        ⍝ (⍺+∆) convergence: done.
      k←⌊P⍟⍵                                 ⍝ next power of phi.
      (⍺,k)∇ ⍵-P*k                           ⍝ accumlated powers of phi.
    }⍵
   ]
}

⍝ From http://dfns.dyalog.com/s_phinary.htm

align←⌽∘↑⍨∘(-∘(⌈/)⍨∘('.'∘(⍳¨⍨)))⍨  

⍝ From http://dfns.dyalog.com/c_root.htm

root ← { ⍺←2 ⋄ ⍵*÷⍺ }                        ⍝ ⍺'th root, default to sqrt.

⍝ From http://dfns.dyalog.com/c_roots.htm

realroots ← {                                ⍝ Real roots of quadratic.
  a b c←⍵                                    ⍝ Coefficients.
  d←(b*2)-4×a×c                              ⍝ Discriminant.

  d<0:⍬                                      ⍝ No roots
  d=0:-b÷2×a                                 ⍝ One root
  d>0:(-b+¯1 1×d*0.5)÷2×a                    ⍝ Two roots
}

⍝ From http://dfns.dyalog.com/s_roots.htm

roots ← {                                    ⍝ Roots of quadratic.
  a b c←⍵                                    ⍝ coefficients.
  d←(b*2)-4×a×c                              ⍝ discriminant.
  (-b+¯1 1×d*0.5)÷2×a                        ⍝ both roots.
}


⍝⍝ Complex number processing

⍝ From http://dfns.dyalog.com/c_polar.htm

polar ← {                                    ⍝ Polar from/to cartesian coordinates.

  pol_car←{                                  ⍝ polar from cartesian (default).
    radius←{(+⌿⍵*2)*0.5}                     ⍝ radius (pythagorus).

    angle←{                                  ⍝ phase angle.
      x y←⊂⍤¯1⊢⍵                             ⍝ x and y coordinates.
      x0 xn←1 0=⊂0=x                         ⍝ points on/off y axis.
      atan←¯3○y÷x+x0                         ⍝ arctan y÷x (avoiding y÷0).
      qne←(xn×atan)+x0×○0.5×2-×y             ⍝ NE quadrant.
      nsw←○x<0                               ⍝ NW and SW quadrants.
      qse←○2×(x>0)∧y<0                       ⍝ SE quadrant.
      nsw+qse+qne                            ⍝ all quadrants.
    }

    (radius ⍵)lam angle ⍵                    ⍝ (2,···) array of polar coordinates.
  }

  car_pol←{                                  ⍝ cartesian from polar.
    r o←⊂⍤¯1⊢⍵                               ⍝ radius and phase angle.
    (r×2○o)lam r×1○o                         ⍝ r×cos(ø), r×sin(ø).
  }

  lam←,[⎕IO-÷2]                              ⍝ laminate along new first axis.

  ⍺←1                                        ⍝ default polar from cartesian.
  ⍺=+1:pol_car ⍵                             ⍝ polar from cartesian.
  ⍺=-1:car_pol ⍵                             ⍝ cartesian from polar.
}

⍝ From http://dfns.dyalog.com/s_polar.htm

rnd ← { (10*-⍺)×⌊0.5+⍵×10*⍺ }

poly ← { 2 1∘.○(○2÷⍵)×(⍳⍵)-⍳1 }

⍝ From http://dfns.dyalog.com/c_xtimes.htm

xtimes ← { ⎕IO←0                             ⍝ Fast multi-digit product using FFT.
  m←0
  xroots    ← {×\1,1↓(⍵÷2)⍴¯1*2÷⍵}
  cube      ← {⍵⍴⍨2⍴⍨⌊2⍟⍴⍵}
  extend    ← {(2*⌈2⍟¯1+(⍴⍺)+⍴⍵)↑¨⍺ ⍵}
  floop     ← {(⊣/⍺)∇⍣(×m)⊢(+⌿⍵),[m-0.5]⍺×[⍳m←≢⍴⍺]-⌿⍵}
  FFT       ← {,(cube xroots⍴⍵)floop cube ⍵}
  iFFT      ← {(⍴⍵)÷⍨,(cube+xroots⍴⍵)floop cube ⍵}
  rconvolve ← {(¯1+(⍴⍺)+⍴⍵)↑iFFT⊃×/FFT¨⍺ extend ⍵}
  carry     ← {1↓+⌿1 0⌽0,0 10⊤⍵}
  (+/∧\0=t)↓t←carry⍣≡0,⌊0.5+9○⍺ rconvolve ⍵
}

convolve ← { ⎕IO←0 ⋄ +⌿(-⍳⍴⍺)⌽⍺∘.×⍵,0×1↓⍺ }

⍝ From http://dfns.dyalog.com/c_xpower.htm

xpower ← {                                   ⍝ Fast multi-digit power using FFT.
  xt←{(0,⍺)xtimes 0,⍵} ⋄ b←⌽2⊥⍣¯1+10⊥⍵       ⍝ boolean showing which powers needed
  ↑,/xt/b/{xt⍨⍵}\(⊂,10⊥⍣¯1+⍺)⍴⍨⍴b
}
