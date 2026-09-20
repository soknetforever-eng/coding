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
