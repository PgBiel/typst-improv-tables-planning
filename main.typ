#import "template.typ": *

#show: project.with(
  title: "Typst Improved Tables - Planning",
  doc-authors: ("PgBiel"),
  authors: ([PgBiel \<https://github.com/PgBiel\>],),
  date: "2023-12-10",
  font: "Fira Sans",
  raw-font: "Fira Mono",
)

#outline(indent: 2em)

#pagebreak(weak: true)

= Introduction and initial details

This document is meant to coordinate efforts towards improved Typst tables. Right now, Typst's `table` elements aren't very flexible - you can't customize individual lines, merge cells, have repeated headers and/or footers, and so on. That's where the author's Tablex @tablex came by, providing a pure Typst alternative to Typst's default tables, bringing many of those very important features - including advanced per-cell customization, customization of each line, merging cells vertically and horizontally, and so on. The intention of the efforts described in this document is to provide these features in the default Typst tables as well, through Rust code instead of Typst code.

== Important definitions

- A *track* is a column or a row in the table.

= Ideas

Below, I will list all ideas that have been brought up so far, in a pretty unordered and informal manner. Then, I will collect them in the "Requirements" section once we are sure on what's going to be done. There, the ideas will be more organized, labelled and prioritized.

== Per-cell customization

1. *OK:* Use a `table.cell` element with customizable settings for each cell. It could look something like

  ```typ
  #table(
    fill: green,
    table.cell(fill: red)[Hello world! This is red],
    [This is green!]
  )
  ```

2. *OK:* It should have similar properties to tablex's implementation. In particular, regarding the most basic properties, `fill`, `align` and `inset` are desirable to override the default table setting. Additionally, a cell would have a `body` or `content` field to access its inner content.

3. *Under discussion:* It should be possible to customize cells in bulk, akin to tablex's `map-cells`.
  - In particular, while `fill: (x, y) => pick-color(x, y)` and `align: (x, y) => pick-align(x, y)` work, they can't depend on other properties the cell has; in particular, the cell's body (e.g. you might want to set the fill for all cells with the text "3" to green).
  - *Proposal 1:* We could change their signatures to `fill: cell => value` *(breaking change)*. The idea is that a `table.cell` would also have `x, y` fields to let you "locate" it, and a `body` or `content` field.
  - *Proposal 2:* We could use show rules. However, they are currently limited due to problems in the styling system:
    ```typ
    #show table.cell: it => {
      // This doesn't work
      set table.cell(fill: red)
      it
      // This doesn't work either (recursion, extra fields etc.)
      // Requires heaps of workarounds
      table.cell(..it.fields(), fill: red)
      // This also doesn't work
      it.fill = red
      // What do we do (in a sane way)?
    }
    ```
    - *Investigation needed:* Additionally, how would tablex detect changes in those fields and apply them? Can an ```rust impl Layout for TableElem``` interact properly with the style-chain post-show rules?
    - Still, this would probably be the most "Typst"-y way to customize cells, and *would be viable after a style system rework.*
  - *Proposal 3:* Bring tablex's `map-cells: cell => cell` option to tables.
    - Would be the simplest option and the easiest to implement.
    - However, the interface *wouldn't be very consistent* with the rest of Typst.

4. *To be discussed:* It should be possible to place cells arbitrarily in the table by setting their `x, y` positions manually.
  - For instance, `table.cell(x: 5, y: 2)` would place it at the 6th column, 3rd row.
    - Cells which would normally be automatically placed at such a position would just skip it.
  - If we follow tablex's system for this, we would have those properties default to `auto`, meaning they would be, by default, automatically positioned based on where they were specified in the table's parameters.
  - However, *what if one of the coordinates is omitted* (e.g. `table.cell(x: 5)` or `table.cell(y: 3)`)? The other one would likely be `auto` as well, but then how would we calculate it?
    - *Proposal 1 (Laurenz#footnote[See discussion on Discord: https://discord.com/channels/1054443721975922748/1117839829191901286/1118120012968894475]):* We could use the first available position in the selected track. For instance, if we specify `table.cell(y: 3)`, and the 4th row only has a single cell to the left, then we would pick `x: 1` as that's the first free position in the row. Similarly, for `table.cell(x: 3)`,  we would pick the first available position, from bottom to top, in the fourth column.
      - Likely more expected in general.
    - *Proposal 2 (Tablex's approach):* The missing coordinate should be determined without change from the `table.cell(x: auto, y: auto)` case. That is, if the cell `table.cell(y: 3)` is specified right after `table.cell(x: 1, y: 1)`, then the former cell's missing `x` coordinate will be calculated to be `x: 2` (the previous plus one). With a missing `y` coordinate, the cell would stay in the same row as the previous cell unless the row is entirely filled, in which case the cell would go to the next row.
      - It works, but might be a bit surprising. Would be nice to have more opinions here.

== Merging cells

*TBD*

== Line customization

1. *OK:* It should be possible to control the appearance of every single line in the table. Among the fundamental customization properties, you have the `stroke` of the line.
  - This should allow removing all vertical lines, for instance, or all horizontal lines easily.

2. *Under discussion:* How to specify these lines?
  - *Proposal 1*: Perhaps use some sort of `lines: (list, of, lines, ...)` or `lines: (x, y) => line-properties` property on the table, similar to `fill` and `align`.
  - *Proposal 2 (Tablex's approach):* Rely fully on special `table.hline` and `table.vline` elements which are placed alongside cells in the table. This would allow for some degree of automatic positioning (e.g. place an `hline` under a row by just creating it right next to the cells of the desired row).
  - *Proposal 3 (Laurenz):* Allow `stroke` to take a function with cells as input where you'd specify the stroke for each border of the cell.
  - *Proposal 4:* Perhaps allow multiple of the specification methods above simultaneously.

3. *To be discussed:* Should we use special `table.hline` and `table.vline` elements for table lines? Should we just use built-in `line` elements instead somehow?
  - Noting that reusing the `line` element could perhaps restrict the available customization options, or not integrate too well with the table's coordinate system, which might make such an option less viable.

4. *Under discussion:* When a cell spans a pagebreak, which lines should appear right before the pagebreak, and which lines should appear right after?
  - Currently, all lines are identical, so this doesn't matter.
  - *Proposal 1 (Pg):* Lines right before the pagebreak (in the current page) should be copies of the lines which come right under the cell. Lines right after the pagebreak (in the new page) should be copies of the lines which come right above the cell.

== Grid and table unification

1. `grid` and `table` should be much closer to each other in terms of available settings. Maybe even have the same API!
  - You'd have, for instance, a `grid.cell` element. However, *that'd be different from* `table.cell`. Show rules applying to one shouldn't apply to the other.
  - Similarly to tablex, the main difference between the two - other than the semantical difference - would be that a `grid` has `stroke: none` (or, rather, no lines at all) by default, while `table` has all lines (horizontal and vertical) by default.
  - *Investigation needed:* We will probably need to have some sort of "Cell-like" trait so that both a `GridCellElem` and a `TableCellElem` can be specified for the `GridLayouter`.
  - *Investigation needed:* How would this affect other elements which depend on `GridLayouter`, such as `list`, `enum` and the like?

== Repeatable headers

1. *OK:* It should be possible to specify a set of rows as the *header rows* of a table. These header rows *would be repeated across pages*, that is, every time the table is broken across pages, the header's cells would be repeated right at the top.
2. *To be discussed:* What's the best way to specify the header rows of a table?
  - *Proposal 1 (Tablex approach):* Specify `header-rows: n`, and the first `n` rows will be considered the header rows of the table. Thus, the cells in the header are integrated with the rest (their coordinates indicate they belong to the first `n` rows), but their laid out contents are repeated on each pagebreak.
  - *Proposal 2:* Specify `header: (list, of, cells, ...)` separately, as an option to the table. This would make it less clear whether the cells would be integrated with the table and have proper coordinates.
    - Without proper coordinates, we would have to rethink how `table.cell.x` and `table.cell.y` work.
    - *Proposal 2A:* `table.cell.x = table.cell.y = none` for cells in the header.
      - Would likely make it weird for show rules and whatnot.
    - *Proposal 2B:* The coordinates of cells in the header would be relative to the top left cell in the header (the "relative" `(0, 0)` cell), but would be detached to the coordinates in the table; that is, there would be two cells in the table with coordinates `(0, 0)` (and possibly others with the same coordinates).
      - Could be pretty awkward to work with in general.
    - *Proposal 2C:* Automatically integrate header cells with the rest of the table, such that the top left cell of the header is also the top left cell of the whole table, and thus coordinates are automatically adjusted.
      - While this seems more sensible, this would potentially interfere with arbitrary cell positioning.
  - *Proposal 3:* A mix of proposals 1 and 2 (perhaps tending more towards 2C), we could specify a `table.header` element above cells (but among them), making it clearer that it could affect their coordinates.
    - Maybe a bit overkill?

== Repeatable footers

*TBD*

= Requirements

Formalized and consolidated ideas. *This section is WIP* (don't take its contents seriously for now).

The requirement labels have some prefixes. "F" indicates a functional requirement (related to adding functionality), while "NF" is non-functional (specifying some desired characteristic, or something more general). This allows us to refer to those requirements with precision in discussions.

== Per-cell customization

#require("FPC")[We should create a `table.cell` element, which will contain settings customizing the cell's appearance and other properties.]
// #require("FPC")[It should be possible to customize and style table cells, through a mechanism similar to tablex's `map-cells`. One possibility is to use show rules.]

== Merging cells

#require("FMC")[It should be possible to *merge cells horizontally*, through a mechanism called `colspan`.]
#require("FMC")[It should be possible to *merge cells vertically*, through a mechanism called `rowspan`.]

= Increments / Waves

The idea here is to assign features to separate "waves" of table features.

== MVP

- *ETA:* TBD

- TODO

- Initial possibilities:
  - `table.cell`
  - Merging cells
  - Line customization
  - Repeatable headers?

== First  increment

- *ETA:* TBD

- TODO

== Second increment

- *ETA:* TBD

- TODO

#pagebreak(weak: true)

#bibliography("bib.yml", full: true)