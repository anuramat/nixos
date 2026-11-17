#import "defs.typ": norm, imported
#set page(width: 14cm, height: 16cm, margin: 1.2cm)
#set math.equation(numbering: "(1)")
#let Reals = $bb(R)$
#let sq(x) = [the square $#x^2$ of #x]

= Heading with $integral_0^1 f(x) dif x$ inside

A paragraph with inline math $f: Reals -> Reals$ that uses a top-level definition, and
the imported $norm(x) <= 1$. Then #sq[a], and again #sq[b].

$ e^(i pi) + 1 = 0 $ <euler>

By @euler. A long inline equation that has to break across lines:
$a_1 + a_2 + a_3 + a_4 + a_5 + a_6 + a_7 + a_8 + a_9 + a_10 + a_11 + a_12 + a_13 + a_14 + a_15 + a_16 = S$, done.

$ x &= (-b plus.minus sqrt(b^2 - 4 a c)) / (2a) \
    &= y + z $

#imported

#figure(
  box(fill: yellow, inset: 4pt)[$ nabla times bold(E) = - (partial bold(B)) / (partial t) $],
  caption: [Caption with $alpha + beta$.],
)

Footnote#footnote[Small $gamma^2$ here.] and big #text(size: 20pt)[$Sigma_i x_i$],
rotated #box(rotate(20deg)[$a/b$]), and styled
#[#show math.equation: set text(fill: blue); $x in Reals$].

#pagebreak()

#table(columns: 2, [cell], [$ mat(1, 2; 3, 4) $])

Tight lines with descenders gjpqy above and (brackets) below $sum_(i=1)^n i$
gjpqy gjpqy gjpqy gjpqy gjpqy gjpqy gjpqy gjpqy gjpqy gjpqy gjpqy gjpqy gjpqy.
