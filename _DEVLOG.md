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

## 2026-09-18: 2026 program populated from Pete's conference folder

Source: `E:\Texas State University\Blair, J Pete - Training Conference`. The public
copy came from `build/sessions_data.py`, which Pete keeps as distribution-ready
program text; `schedule_draft.md` was used only for the running order and day
themes, since it also carries internal scheduling notes that do not belong on the
site.

**Name change.** The current flyer (Aug 2026) says "The Advanced Training Design
Workshop" with the tagline "Designing Training That Transfers". Site title,
hero, and About now match. The navbar brand stays the shorter "Training Design
Workshop" so it still fits on one line; change `website.navbar.title` in
`_quarto.yml` to revert.

**Sessions.** Sixteen pages under `sessions/posts/<slug>/`, one per slot,
generated from the program copy: title, one-line blurb, full description,
co-presenters where applicable, and the presenter bio. Front-matter `date` is a
full datetime (`2026-12-04T13:00:00`), which is what makes the listing sort in
running order within each day; the listing renders it as "Friday 4 Dec, 1:00 PM"
via `date-format`. Categories are a small controlled vocabulary (Keynote,
Control tactics, Weapons, Active attacker, Scenario design, Tactical medicine,
Instructor development, Decision-making, Skill acquisition) and the listing shows
filter chips.

**Schedule.** Real grid for Friday and Saturday: time, session (linked to its
page), presenter, with lunch and adjourn rows. Raw HTML tables styled by
`table.sched` in `theme.scss`.

**Home page.** Tagline under the hero, a featured-presenter block for Rob Gray's
opening keynote, the flyer's eight session themes, the presenting-agencies strip,
a Sessions quick-link card, and a "draft program posted" key date. Hero CTA now
leads with the program.

**Map.** `data/attendees.csv` carries the fifteen presenters (named, with
affiliation) plus sixteen ALERRT staff rows. New `country` column: leave blank for
US rows. Rows with no coordinates still count in the headline number and report as
"not yet placed", so someone can be added before their city is known. The opening
view frames the Americas only, so the Brno dot does not shrink everyone else;
a note under the summary names anyone off-frame.

**Not fabricated.** Nothing was invented to fill a gap. Presenter coordinates come
from the agency city named in the proposal, not from a guess at where someone
lives.

### Needs Pete or the presenter to confirm

- **Chris Butler (Raptor Public Safety Coaching)** and **Dan Fraser (RCMP,
  Alberta)** have no city in the proposals, so they have no map dot yet. Add a
  city and coordinates to `data/attendees.csv` and they appear.
- **ALERRT staff count** on the map is 16, taken from `Attendee list.docx`, which
  includes "New kid?" and "Me". Adjust the number of staff rows if that is off.
- **Titles still unconfirmed** with the presenter per `schedule_draft.md`:
  Barawed, Pospíšil, Campion. They are published as written.
- **Rob Gray's session description** is still a placeholder ("Full session
  description to come").
- **Saturday 4:00 ALERRT session** is published as "To be announced".
- Randy Wark's one-line bio is deliberate; he asked that nothing more be printed.

## 2026-09-18 (later): public-facing cleanup and the last two map dots

Removed both "For the workshop team" note panels (map, photos) now that the site is
going out publicly. Those instructions are recorded here instead:

**Attendee map** reads `data/attendees.csv`. One row per registrant:
`name,role,affiliation,city,state,country,lat,lng`. Role is presenter, attendee, or
staff. Leave `country` blank for United States rows and fill it in for everyone
else, because the state count and the map's opening frame both key off it.
Presenters are named on the map, so fill in name and affiliation for presenter
rows; attendee and staff names are never shown and those dots display counts only.
Coordinates: right-click the spot in Google Maps and copy the numbers. A row with
no coordinates still counts in the headline and reports as "not yet placed".

**Photo gallery** rebuilds itself from whatever is in `images/gallery/`. Drop image
files in and commit; no editing required.

**Chris Butler and Dan Fraser are placed.** Both are Calgary, Alberta
(51.0447, -114.0719), confirmed online rather than guessed:

- Butler is a retired Calgary Police Service Inspector and runs Raptor Public
  Safety Coaching / Raptor Protection and Safety Services out of Calgary.
- Fraser Training Solutions is a Calgary business, and Fraser's own author page
  says he spent over 20 years with the **Calgary Police Service**, retiring in
  2020. The proposal in `sessions_data.py` lists him as **RCMP**, so the site still
  says RCMP. There is also a LinkedIn profile for a Dan Fraser at the RCMP, so he
  may well have moved agencies. Worth one glance from Pete before this is printed.

The attendee list was re-read after Pete's 2026-09-18 update: still 16 ALERRT
staff, so the map count is unchanged. Scott Seivewright and David Gilbert are
still off the map pending locations.

## Open items

- Add attendee rows to `data/attendees.csv` as registrations come in (presenters and staff are in)
- Confirm Dan Fraser's agency (proposal says RCMP; his public bio says Calgary Police Service)
- Add Scott Seivewright and David Gilbert to the map once their attendance and locations are settled
- Fill in Rob Gray's session description and the ALERRT Saturday 4:00 slot once they land
- Add quotes to `data/quotes.csv` after the workshop
- Archive 2026 into `past/2026/` after December
- Update the Present page when the 2027 call opens
- Consider bumping `actions/checkout@v4` to `@v5` in the publish workflow (deprecation warning, not a failure)
- If an online registration form is created, swap it into the marked spot in `attend.qmd`
