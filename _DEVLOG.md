# Site Dev Log

The leading underscore in this filename keeps Quarto from rendering it into the public site. It is a working log for the site maintainers.

## 2026-07-24: Initial site build

Replaced the placeholder Quarto site with the full Training Design Workshop 2026 website (built with Claude Code).

**Naming decision:** the flyer says "The Training Design Workshop," so that is the official site title, with the ALERRT Center as host. Swap in "ALERRT Training Workshop" later if preferred.

**Pages created:**

- Home (`index.qmd`): dark hero, mono data strip (dates, venue, seats, format), 25/15/10 session-format bar, key dates with status chips, quick-link cards
- Attend (`attend.qmd`): $695 cost, what it covers, how to register (email Sarah Drennan), TBarM venue and travel notes
- Present (`call-for-presentations.qmd`): full RFP content, note that the 2026 window closed June 5, link to the original PDF (`assets/2026-RFP.pdf`)
- Schedule (`schedule.qmd`): Dec 3-6 day-by-day outline
- Who's Coming (`map.qmd`): Leaflet attendee map
- Photos (`photos.qmd`): auto-generated lightbox gallery
- Resources (`resources/`): listing page for white papers, slides, readings
- About (`about.qmd`): workshop, ALERRT Center, venue, contact

**Design system** (`theme.scss` on top of cosmo): "range card / ops order" look. Barlow Condensed display, Source Sans 3 body, IBM Plex Mono for data labels. Ink #20262B, paper #FAFAF7, training-blue accent #2456C4 (the color of designated training gear). Map marker palette validated for colorblind safety: presenter #2456C4, attendee #C05621, staff #009186.

**Content mechanisms (edit data, not code):**

- Map reads `data/attendees.csv` (name,role,affiliation,city,state,lat,lng); one row per registrant, commit, done. Get coordinates by right-clicking in Google Maps.
- Gallery rebuilds from whatever images are in `images/gallery/`
- Resources entries are folders under `resources/posts/`

**Housekeeping:** untracked the stale `_site/` build output and `.quarto/` cache; gitignored `docs/`, `_site/`. CI (`.github/workflows/publish.yml`) renders with R 4.2 + renv and publishes to the gh-pages branch on every push to main.

**Local dev quirk:** local R is 4.6.1 but the lockfile targets 4.2, so a full `renv::restore()` fails. knitr and rmarkdown were installed with `renv::install()` (no snapshot) so `quarto render` and `quarto preview` work locally. CI is unaffected.

## 2026-07-27: Archive, FAQ, sessions, testimonials; first deploy

- FAQ page (`faq.qmd`): attending, presenting, materials questions, all grounded in the flyer
- Sessions section (`sessions/`): listing page in the navbar; copy `sessions/_template/` to `sessions/posts/<name>/` per session once the 2026 program is set. Underscore folders never render.
- Past Workshops archive (`past/`): listing page under the Archive navbar menu; copy `past/_template/` to `past/<year>/` after each workshop. No fabricated history; page says the archive is being assembled.
- Testimonials: home page renders "What attendees say" quote cards from `data/quotes.csv` (columns: quote,attribution). Section is invisible while the CSV has only its header row. Add rows after December.
- First deploy: pushed to main, Quarto Publish action went green, site live at https://alerrt-research.github.io/PROJ_ecod_website.github.io/

## 2026-07-27: Refinements after review

- Resources moved out of the Archive menu back to a top-level navbar item; Archive keeps Photos and Past Workshops. Navbar type tightened to fit one line at laptop widths.
- Map: presenters are now named on hover and click (name plus affiliation); attendee and staff dots stay anonymous counts. Fill in name and affiliation columns for presenter rows in `data/attendees.csv`.
- "Single track" wording removed everywhere except the home page.

## Open items

- `data/attendees.csv` still holds three sample rows marked "delete me"; remove when real registrations start
- Post the 2026 session lineup when the program is final (use `sessions/_template/`)
- Add quotes to `data/quotes.csv` after the workshop
- Archive 2026 into `past/2026/` after December
- Update the Present page when the 2027 call opens
- Consider bumping `actions/checkout@v4` to `@v5` in the publish workflow (deprecation warning, not a failure)
- If an online registration form is created, swap it into the marked spot in `attend.qmd`
