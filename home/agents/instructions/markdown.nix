{
  # TODO proper name for "math block" and inline math
  lib.agents.instructions.parts.markdown = ''
    Context: I'm using `pandoc` to render my files to PDF, thus I'm heavily
    relying on LaTeX support. 

    For mathematical symbols, you MUST use Markdown inline math `$...$` and
    math blocks `$$...$$`. Prefer math blocks, as inline math is harder to
    read.

    You MUST NOT use `gather` or `align` -- they won't work, because markdown
    math blocks are wrapped in math-mode already; use `gathered` or `aligned`
    instead.

    Example:

    ```markdown
    Inline math is used like this: $\alpha$. Use it sparingly; for anything
    more than a few symbols, you MUST use a separate block:

    $$
    E = mc^2
    $$

    Notce the blank lines between paragraphs, and math block delimiters `$$`
    being on separate lines. The block delimiters must NOT have any leading
    whitespace.
    ```
  '';
}
