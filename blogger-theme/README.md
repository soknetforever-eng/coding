# REAL ASSET COIN — Blogger crypto landing theme

**`real-asset-coin-theme.xml`** is a single self-contained Blogger theme:
a modern, dark, blue/indigo crypto landing page — not a blog layout. Upload
this one file and the whole page renders immediately (sticky nav, hero,
about, tokenomics donut chart, utility grid, roadmap timeline, how-to-buy,
FAQ accordion, disclaimer, footer). There's no post feed — it's a one-page
site.

## Features

- Dark, glassy, gradient-glow crypto aesthetic (Space Grotesk + Inter)
- Sticky nav with a pure-CSS mobile hamburger menu (no JS)
- Hero with gradient headline, CTA buttons, and token stat pills
- CSS-only tokenomics donut chart + legend
- Icon feature grid, vertical roadmap timeline, numbered "how to buy" steps
- Native `<details>` FAQ accordion (no JS)
- Fully responsive: fluid type via `clamp()`, grid `auto-fit` cards, stacks
  cleanly down to small phones
- Persistent demo/mockup banner + risk disclaimer

## Install

1. Go to your Blogger dashboard → **Theme** → the dropdown next to
   "Customize" → **Edit HTML**.
2. (Recommended) Back up your current theme first: same dropdown →
   **Download theme**.
3. Select all existing XML in the code box, delete it.
4. Paste the entire contents of `real-asset-coin-theme.xml`.
5. Click **Save**, then visit your blog's public URL to see it.

## Customizing

- **Colors**: CSS variables at the top of the `<b:skin>` block
  (`--blue-500`, `--indigo-500`, `--bg`, etc.).
- **Copy**: everything is static HTML in the `<body>` — edit the text
  directly in the sections named `hero`, `about`, `tokenomics`, `utility`,
  `roadmap`, `buy`, `faq`.
- **Site title**: set via Blogger's own Title/Description settings — it
  feeds the nav brand and footer through `data:blog.title`.

## Before you publish anything based on this

**Every `[bracketed]` value, the tokenomics percentages, and the contract
address are placeholders** — none of it describes a real token. Before
this goes live anywhere:

- Replace every placeholder with accurate, verifiable information about
  your actual project.
- Only claim asset-backing, audits, or partnerships you can link to
  verifiable proof of.
- Keep the risk disclaimer — most jurisdictions require clear risk
  disclosure for token marketing, and it's good practice regardless.
- If you're actually soliciting investment, get legal advice for your
  jurisdiction first.

## Older variants

- `modern-blue.xml` — the original light, blue, blog-post-focused theme
  (single-column posts, comments, pager). Use this if you actually want a
  blog rather than a one-page project site.
- `sample-posts/real-asset-coin-post.html` — the same mockup content laid
  out as a single blog post (for pasting into a post body on
  `modern-blue.xml` instead of using the standalone landing page above).
