# Modern Blue — Blogger Theme

A minimal, modern Blogger (Blogspot) theme in a blue palette. Single-column
layout focused entirely on the blog post — no sidebar, no widget clutter.

## Features

- Header with blog title + description on a blue gradient
- Full-width post "card" with serif reading typography, styled blockquotes,
  code blocks, labels, and comments
- Automatic dark mode (`prefers-color-scheme`)
- Responsive down to mobile
- Older/newer post pager
- Simple footer

## Install

1. Go to your Blogger dashboard → **Theme** → **Edit HTML** (via the dropdown
   next to "Customize").
2. Select all existing XML and delete it.
3. Paste the contents of `modern-blue.xml`.
4. Click **Save**.

Back up your current theme first (Theme → Edit HTML → **Download theme**)
in case you want to revert.

## Customizing the color

All colors are CSS variables at the top of the `<b:skin>` block in
`modern-blue.xml` (`--blue-600`, `--blue-700`, etc.). Change those hex
values to retheme the whole site.

## Sample post: crypto token page

`sample-posts/real-asset-coin-post.html` is a **mockup** post showing how
to lay out a token/project page (token details, tokenomics table, roadmap,
how-to-buy, FAQ, disclaimer) using the theme's `.stat-grid`, table, and
`.callout` styles.

**Every figure, address, and claim in it is a placeholder** — it's a
layout template, not real content. Before publishing anything based on it:

- Replace every `[bracketed placeholder]` with accurate, verifiable
  information about your actual project.
- Only claim asset-backing, audits, or partnerships you can link to
  verifiable proof of.
- Keep the risk disclaimer — most jurisdictions require clear risk
  disclosure for token marketing, and it's good practice regardless.
- If you're actually soliciting investment, get legal advice for your
  jurisdiction first.

To use it: paste the HTML into a Blogger post via the post editor's
**HTML view** (the `<>` icon in the post toolbar).
