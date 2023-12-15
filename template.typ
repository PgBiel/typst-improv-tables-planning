#import "@preview/ctheorems:0.1.0": thmbox, thmplain, thmref
// #import "@preview/codly:0.1.0" as codly: codly-init, codly as codly-func
#import "pkg/codly.typ" as codly: codly-init, codly as codly-func

#let obs = thmplain("obs", [*Obs.*]).with(numbering: none)

#let note = thmbox("note", "Note", inset: 10pt, /*inset: (x: 1.2em, top: 1em),*/ fill: yellow.darken(6%))

#let n-color-box(..parts, columns: auto, height: auto, text-color: white, bg: green) = {
  if columns == auto {
    columns = (auto,) * parts.pos().len()
  }
  let result = table(
    columns: columns,
    rows: (height,),
    stroke: none,
    align: start + horizon,
    fill: (x, y) => if x == 0 { bg.darken(50%) } else { bg.darken(30%) },
    ..parts
  )
  if text-color not in (auto, none) {
    set text(fill: text-color)
    result
  } else {
    result
  }
}
#let top-level-heading(h, bg: green, columns: (auto, 1fr), text-color: white, height: auto, custom-numbering: none, number-styler: n => n) = locate(loc => block(breakable: false, {
  let actual-numbering = if custom-numbering == none { h.numbering } else { custom-numbering }
  let number = if actual-numbering == none { none } else { numbering(actual-numbering, ..counter(heading).at(loc)) }
  let number = number-styler(number)
  n-color-box(number, h.body, columns: columns, height: height, bg: bg, text-color: text-color)
}))

#let outline-heading(h) = {
  top-level-heading(
    h,
    height: 1.75em,
    bg: blue.lighten(50%)
  )
}
#let rotated-top-level-heading(h) = {
  top-level-heading(
    h,
    height: 1.75em,
    bg: green,
    custom-numbering: "1",
    number-styler: n => {
      move(dx: -5pt, dy: -1.1pt, box(clip: true, width: 1.3em, height: 2em)[
        #set text(2.5em)
        #rotate(11deg, n)
      ])
    }
  )
}

// Draws a white sideways triangle at the beginning of the line
#let arrowed(body, inset: 5pt) = style(styles => {
  let height = measure(body, styles).height + 2 * inset
  place(
    top+left,
    dx: -inset,
    dy: -inset,
    polygon(
      fill: white,
      (-1pt, 0pt - inset),
      (4pt, 0.5 * height),
      (-1pt, 1 * height + inset)
    )
  )
  h(4pt)
  body
})

#let arrowed-heading(h, bg: red.lighten(35%), columns: (2.7em, 1fr)) = {
  top-level-heading(h, bg: bg, columns: columns, number-styler: arrowed)
}

// ---

// Creates a requirement, and assigns a label.
#let require(prefix, body, label: none) = {
  let count = counter("requirement-" + prefix)
  count.step()
  // let label-metadata = if label == none {
  //   none
  // } else {
  //   [#metadata((requirement-prefix: prefix)) #label]
  // }
  // [FC3]: body (metadata optional when a label is used)
  [/ [#prefix#count.display()]: #body]
  let label-metadata = metadata((requirement-prefix: prefix))
  label-metadata
}

#let display-requirement-refs(doc) = {
  show ref: it => {
    let sequence = [*a* _a_].func()
    if it.element != none and it.element.func() == sequence {
      // metadata will be last in the sequence
      let last-in-seq = it.element.children.last()
      if last-in-seq.func() != metadata {
        return it
      }
      let value = last-in-seq.value
      if type(value) == dictionary and "requirement-prefix" in value {
        // get the sequence's location
        let loc = it.element.location()
        let prefix = value.requirement-prefix
        // the value of the counter at the sequence is 1 less than it actually is,
        // as the counter.step() is inside the sequence, so we add 1 to the counter's
        // value.
        let number = numbering("1", counter("requirement-" + prefix).at(loc).first() + 1)
        // display e.g. [FC3]
        let body = [[#prefix#number]]
        link(loc, body)
      }
    } else {
      it
    }
  }
  doc
}

// ---

// The project function defines how your document looks.
// It takes your content and some metadata and formats it.
// Go ahead and customize it to your liking!
#let project(title: "", doc-authors: (), authors: (), middle: none, date: none, font: "Linux Libertine", raw-font: none, lang: "en", body) = {
  // Set the document's basic properties.
  set document(author: doc-authors, title: title)
  set page(numbering: "1", number-align: center)
  set text(font: font, lang: lang)
  show heading.where(level: 2): arrowed-heading
  show heading.where(level: 3): arrowed-heading.with(bg: blue.lighten(35%), columns: (auto, auto))
  show ref: set text(blue.darken(10%))
  show link: set text(blue.darken(10%))
  show raw: it => {
    if raw-font != none {
      set text(font: raw-font)
      it
    } else {
      it
    }
  }
  show raw: set text(1.15em)
  show math.equation: set text(1.15em)
  show: display-requirement-refs

  show: codly-init
  codly-func(
    languages: (
      typ: (name: "Typst", icon: none, color: eastern)
    ),
    numbers-format: it => move(dx: 1pt, text(it, luma(110)))
  )

  // Title row.
  align(center)[
    #block(text(weight: 700, 1.75em, title))
    #v(1em, weak: true)
  ]

  // Author information.
  pad(
    top: 0.5em,
    bottom: 0.5em,
    x: 2em,
    grid(
      columns: (1fr,) * calc.min(3, authors.len()),
      gutter: 1em,
      ..authors.map(author => align(center, strong(author))),
    ),
  )

  align(center)[
    #middle
    #v(1em, weak: true)
    #date
  ]

  set list(marker: ($circle.filled.small$, $circle.small$, $square.filled.small$, $circle.filled.small$))

  // Main body.
  set par(justify: true)

  set heading(numbering: "1.")
  show heading.where(level: 1): it => {
    if it.numbering == none {
      outline-heading(it)
    } else {
      rotated-top-level-heading(it)
    }
  }

  show outline.entry.where(level: 1): strong
  show footnote.entry: set par(justify: false)

  body
}
