-- program.lua
--
-- One source of truth for the workshop program. This filter reads
--   data/program.yml            the days, their notes, and breaks
--   sessions/posts/*/index.qmd  one folder per session (front matter only)
-- and uses them to build:
--   ::: {.program-mat}        the at-a-glance grid on the home page
--   ::: {.program-full}       the full running order on the Program page
--   ::: {.presenter-roster}   the presenter list on Who's coming
--   ::: {.session-count}      not a div: see Span below, [x]{.session-count}
-- On a session page it also adds the when/who strip under the title and the
-- previous/next links at the bottom.
--
-- Session front matter fields: title, description, presenter, role (optional),
-- affiliation, day (must match a day in program.yml), time ("8:00 AM"), topics.

local stringify = pandoc.utils.stringify
local SESSION_MINUTES = 50
local SLOT_MINUTES = 60
local UTC_OFFSET = "-06:00" -- Central Standard Time, in effect in December

local MONTHS = { "January", "February", "March", "April", "May", "June", "July",
  "August", "September", "October", "November", "December" }
local NUMBER_WORDS = { "one", "two", "three", "four", "five", "six", "seven",
  "eight", "nine", "ten", "eleven", "twelve", "thirteen", "fourteen", "fifteen",
  "sixteen", "seventeen", "eighteen", "nineteen", "twenty" }

-- ---------- small helpers ----------

local function esc(s)
  s = tostring(s or "")
  s = s:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"):gsub('"', "&quot;")
  return s
end

local function read_file(path)
  local f = io.open(path, "r")
  if not f then return nil end
  local s = f:read("a")
  f:close()
  s = s:gsub("^\239\187\191", "")
  s = s:gsub("\r\n", "\n")
  return s
end

local function read_yaml(yaml)
  return pandoc.read("---\n" .. yaml .. "\n---\n", "markdown").meta
end

-- Inline markdown in a metadata value (italics, smart quotes) as HTML
local function to_html(v)
  if v == nil then return "" end
  if pandoc.utils.type(v) == "Inlines" then
    local html = pandoc.write(pandoc.Pandoc({ pandoc.Plain(v) }), "html")
    return (html:gsub("%s+$", ""))
  end
  return esc(stringify(v))
end

local function text(v)
  if v == nil then return "" end
  return stringify(v)
end

local function slugify(s)
  s = s:lower():gsub("[^%w]+", "-"):gsub("^%-+", ""):gsub("%-+$", "")
  return s
end

local function parse_time(s)
  local h, m, ap = s:match("^%s*(%d+):(%d+)%s*([AaPp])")
  if not h then return nil end
  h, m = tonumber(h), tonumber(m)
  ap = ap:lower()
  if ap == "p" and h ~= 12 then h = h + 12 end
  if ap == "a" and h == 12 then h = 0 end
  return h * 60 + m
end

local function clock(mins)
  local h, m = math.floor(mins / 60), mins % 60
  local h12 = h % 12
  if h12 == 0 then h12 = 12 end
  return string.format("%d:%02d", h12, m), (h < 12) and "AM" or "PM"
end

local function clock_full(mins)
  local t, ap = clock(mins)
  return t .. " " .. ap
end

local function iso(date, mins)
  return string.format("%sT%02d:%02d:00%s", date, math.floor(mins / 60), mins % 60, UTC_OFFSET)
end

local function long_date(date)
  local _, mo, d = date:match("^(%d+)-(%d+)-(%d+)$")
  if not mo then return date end
  return MONTHS[tonumber(mo)] .. " " .. tonumber(d)
end

local function short_date(date)
  local _, mo, d = date:match("^(%d+)-(%d+)-(%d+)$")
  if not mo then return date end
  return MONTHS[tonumber(mo)]:sub(1, 3) .. " " .. tonumber(d)
end

local function root()
  local off = quarto.project.offset
  if off == nil or off == "" then off = "." end
  return off
end

-- ---------- load the program ----------

local cache = nil

local function load_program()
  if cache then return cache end
  local dir = quarto.project.directory
  local prog = { days = {}, sessions = {}, by_slug = {}, topics = {}, topic_order = {} }

  local raw = read_file(dir .. "/data/program.yml")
  if not raw then error("program.lua: data/program.yml not found") end
  local meta = read_yaml(raw)
  prog.year = text(meta.year)

  local day_index = {}
  for i, d in ipairs(meta.days or {}) do
    local day = {
      name = text(d.day), date = text(d.date), title = text(d.title),
      note_html = to_html(d.note), breaks = {}, sessions = {},
    }
    for _, b in ipairs(d.breaks or {}) do
      local mins = parse_time(text(b.time))
      if mins then table.insert(day.breaks, { mins = mins, label = text(b.label) }) end
    end
    prog.days[i] = day
    day_index[day.name:lower()] = i
  end

  local posts = dir .. "/sessions/posts"
  local names = pandoc.system.list_directory(posts)
  table.sort(names)
  for _, name in ipairs(names) do
    if name:sub(1, 1) ~= "_" and name:sub(1, 1) ~= "." then
      local src = read_file(posts .. "/" .. name .. "/index.qmd")
      local fm = src and src:match("^%-%-%-\n(.-)\n%-%-%-")
      if fm then
        local m = read_yaml(fm)
        local day_name = text(m.day)
        local di = day_index[day_name:lower()]
        local mins = parse_time(text(m.time))
        if not di or not mins then
          error("program.lua: sessions/posts/" .. name ..
            " needs a `day` that matches data/program.yml and a `time` like \"8:00 AM\"")
        end
        local s = {
          slug = name,
          title_html = to_html(m.title), title = text(m.title),
          desc_html = to_html(m.description),
          presenter = text(m.presenter), role = text(m.role),
          affiliation = text(m.affiliation),
          day = prog.days[di], day_i = di, mins = mins, topics = {},
        }
        for _, t in ipairs(m.topics or {}) do
          local label = text(t)
          table.insert(s.topics, label)
          if not prog.topics[label] then
            prog.topics[label] = 0
            table.insert(prog.topic_order, label)
          end
          prog.topics[label] = prog.topics[label] + 1
        end
        s.start_iso = iso(s.day.date, mins)
        s.end_iso = iso(s.day.date, mins + SLOT_MINUTES)
        s.when = s.day.name .. " " .. clock_full(mins)
        table.insert(prog.sessions, s)
        prog.by_slug[name] = s
      end
    end
  end

  table.sort(prog.sessions, function(a, b)
    if a.day_i ~= b.day_i then return a.day_i < b.day_i end
    return a.mins < b.mins
  end)
  for i, s in ipairs(prog.sessions) do
    s.index = i
    table.insert(s.day.sessions, s)
  end
  table.sort(prog.topic_order)

  cache = prog
  return prog
end

local function session_url(s)
  return root() .. "/sessions/posts/" .. s.slug .. "/index.html"
end

local function who_line(s)
  local parts = {}
  if s.role ~= "" then table.insert(parts, s.role) end
  if s.affiliation ~= "" then table.insert(parts, s.affiliation) end
  return table.concat(parts, ", ")
end

local function split_name(name)
  local first, last = name:match("^(.*)%s+(%S+)$")
  if not first then return "", name end
  return first, last
end

-- ---------- home page: the mat ----------

local function mat_html(prog)
  local out = {}
  local first_date, last_date = prog.days[1].date, prog.days[#prog.days].date
  table.insert(out, '<div class="mat">')
  for _, day in ipairs(prog.days) do
    if #day.sessions > 0 then
      table.insert(out, '<div class="mat-day">')
      table.insert(out, string.format(
        '<div class="mat-daylabel"><strong>%s</strong><span>%s</span></div>',
        esc(day.name), esc(short_date(day.date))))
      table.insert(out, '<div class="mat-tiles">')
      local last_mins = day.sessions[#day.sessions].mins
      local bi = 1
      for _, s in ipairs(day.sessions) do
        -- a break that falls between sessions shows as a gap in the mat
        while day.breaks[bi] and day.breaks[bi].mins <= s.mins do
          if day.breaks[bi].mins > day.sessions[1].mins and day.breaks[bi].mins < last_mins then
            table.insert(out, string.format('<span class="tile-gap"><span>%s</span></span>',
              esc(day.breaks[bi].label)))
          end
          bi = bi + 1
        end
        local first, last = split_name(s.presenter)
        local t = clock(s.mins)
        table.insert(out, string.format(
          '<a class="tile" href="%s" data-start="%s" data-end="%s" data-when="%s" data-title="%s" ' ..
          'aria-label="%s, %s: %s">' ..
          '<span class="tile-time">%s</span><span class="tile-name"><span>%s</span> <strong>%s</strong></span></a>',
          session_url(s), s.start_iso, s.end_iso, esc(s.when), esc(s.title),
          esc(s.when), esc(s.presenter), esc(s.title),
          t, esc(first), esc(last)))
      end
      table.insert(out, '</div></div>')
    end
  end
  table.insert(out, string.format(
    '<p class="mat-line" id="mat-line" data-first="%s" data-last="%s" data-first-label="%s, %s" data-year="%s">' ..
    '<span class="mat-line-text">Every session, in running order. Pick one to read about it.</span></p>',
    first_date, last_date, esc(prog.days[1].name), esc(long_date(first_date)), esc(prog.year)))
  table.insert(out, '</div>')
  return table.concat(out, "\n")
end

-- ---------- program page: the full running order ----------

local function full_html(prog)
  local out = {}

  -- jump links
  table.insert(out, '<nav class="prog-days" aria-label="Jump to a day"><ul>')
  for _, day in ipairs(prog.days) do
    table.insert(out, string.format('<li><a href="#%s"><strong>%s</strong><span>%s</span></a></li>',
      slugify(day.name), esc(day.name), esc(short_date(day.date))))
  end
  table.insert(out, '</ul></nav>')

  -- topic filter
  table.insert(out, '<div class="prog-filter" role="group" aria-label="Show sessions by topic">')
  table.insert(out, string.format(
    '<button type="button" class="chip" data-topic="" aria-pressed="true">All %d sessions</button>',
    #prog.sessions))
  for _, label in ipairs(prog.topic_order) do
    table.insert(out, string.format(
      '<button type="button" class="chip" data-topic="%s" data-label="%s" aria-pressed="false">%s <span>%d</span></button>',
      slugify(label), esc(label:lower()), esc(label), prog.topics[label]))
  end
  table.insert(out, '</div>')
  table.insert(out, '<p class="prog-count" id="prog-count" aria-live="polite" hidden></p>')

  for _, day in ipairs(prog.days) do
    table.insert(out, string.format('<section class="prog-day" id="%s">', slugify(day.name)))
    table.insert(out, string.format(
      '<header class="prog-day-head"><h2>%s <span>%s</span></h2><p><strong>%s.</strong> %s</p></header>',
      esc(day.name), esc(long_date(day.date)), esc(day.title), day.note_html))

    if #day.sessions > 0 then
      -- merge sessions and breaks into one running order
      local rows = {}
      for _, s in ipairs(day.sessions) do table.insert(rows, { mins = s.mins, s = s }) end
      for _, b in ipairs(day.breaks) do table.insert(rows, { mins = b.mins, b = b }) end
      table.sort(rows, function(a, b) return a.mins < b.mins end)

      table.insert(out, '<ol class="prog-list">')
      for _, r in ipairs(rows) do
        local t, ap = clock(r.mins)
        local time = string.format('<span class="prog-time">%s <small>%s</small></span>', t, ap)
        if r.b then
          table.insert(out, string.format(
            '<li class="prog-row prog-break">%s<span class="prog-break-label">%s</span></li>',
            time, esc(r.b.label)))
        else
          local s = r.s
          local slugs, labels = {}, {}
          for _, tp in ipairs(s.topics) do
            table.insert(slugs, slugify(tp))
            table.insert(labels, esc(tp))
          end
          local who = esc(s.presenter)
          if who_line(s) ~= "" then who = who .. '<span>, ' .. esc(who_line(s)) .. '</span>' end
          table.insert(out, string.format(
            '<li class="prog-row prog-session" data-topics="%s" data-start="%s" data-end="%s">%s' ..
            '<div class="prog-body"><h3><a href="%s">%s</a></h3>' ..
            '<p class="prog-who">%s</p><p class="prog-desc">%s</p><p class="prog-topics">%s</p></div></li>',
            table.concat(slugs, " "), s.start_iso, s.end_iso, time,
            session_url(s), s.title_html, who, s.desc_html, table.concat(labels, ", ")))
        end
      end
      table.insert(out, '</ol>')
    end
    table.insert(out, '</section>')
  end
  return table.concat(out, "\n")
end

-- ---------- who's coming: presenter roster ----------

local function roster_html(prog)
  local list = {}
  for _, s in ipairs(prog.sessions) do table.insert(list, s) end
  table.sort(list, function(a, b)
    local _, la = split_name(a.presenter)
    local _, lb = split_name(b.presenter)
    return la:lower() < lb:lower()
  end)
  local out = { '<ul class="roster">' }
  for _, s in ipairs(list) do
    table.insert(out, string.format(
      '<li><a href="%s"><strong>%s</strong><span class="roster-org">%s</span>' ..
      '<span class="roster-session">%s, %s</span></a></li>',
      session_url(s), esc(s.presenter), esc(s.affiliation), s.title_html, esc(s.when)))
  end
  table.insert(out, '</ul>')
  return table.concat(out, "\n")
end

-- ---------- session pages ----------

local function current_session(prog_loader)
  local input = quarto.doc.input_file
  if not input then return nil end
  input = input:gsub("\\", "/")
  local slug = input:match("/sessions/posts/([^/]+)/[^/]+$")
  if not slug or slug:sub(1, 1) == "_" then return nil end
  local prog = prog_loader()
  return prog.by_slug[slug], prog
end

local function session_meta_html(s)
  local t1 = clock_full(s.mins)
  local t2 = clock_full(s.mins + SESSION_MINUTES)
  local who = '<strong>' .. esc(s.presenter) .. '</strong>'
  if who_line(s) ~= "" then who = who .. '<span>' .. esc(who_line(s)) .. '</span>' end
  local topics = {}
  for _, tp in ipairs(s.topics) do table.insert(topics, esc(tp)) end
  local out = {
    '<div class="session-meta">',
    string.format('<p class="session-when"><strong>%s, %s</strong><span>%s to %s</span></p>',
      esc(s.day.name), esc(long_date(s.day.date)), t1, t2),
    '<p class="session-who">' .. who .. '</p>',
  }
  if #topics > 0 then
    table.insert(out, '<p class="session-topics">' .. table.concat(topics, ", ") .. '</p>')
  end
  table.insert(out, '</div>')
  return table.concat(out, "\n")
end

local function session_nav_html(s, prog)
  local prev, nxt = prog.sessions[s.index - 1], prog.sessions[s.index + 1]
  local out = { '<nav class="session-nav" aria-label="Other sessions">' }
  local function link(cls, lead, o)
    table.insert(out, string.format(
      '<a class="%s" href="%s"><span>%s, %s</span><strong>%s</strong></a>',
      cls, session_url(o), lead, esc(o.when), o.title_html))
  end
  if prev then link("session-prev", "Before this", prev) else table.insert(out, '<span></span>') end
  if nxt then link("session-next", "After this", nxt) else table.insert(out, '<span></span>') end
  table.insert(out, string.format(
    '<a class="session-all" href="%s/program.html#%s">See the full program</a>',
    root(), slugify(s.day.name)))
  table.insert(out, '</nav>')
  return table.concat(out, "\n")
end

-- ---------- filter entry point ----------

function Pandoc(doc)
  local function raw(html) return pandoc.RawBlock("html", html) end

  doc.blocks = doc.blocks:walk({
    Div = function(div)
      if div.classes:includes("program-mat") then return raw(mat_html(load_program())) end
      if div.classes:includes("program-full") then return raw(full_html(load_program())) end
      if div.classes:includes("presenter-roster") then return raw(roster_html(load_program())) end
      return nil
    end,
    -- [x]{.session-count} becomes the number of sessions as a word ("sixteen");
    -- add .cap for a capital ("Sixteen"), .digits for the numeral ("16").
    Span = function(span)
      if span.classes:includes("session-count") then
        local n = #load_program().sessions
        local word = NUMBER_WORDS[n] or tostring(n)
        if span.classes:includes("digits") then word = tostring(n) end
        if span.classes:includes("cap") then word = word:sub(1, 1):upper() .. word:sub(2) end
        return pandoc.Str(word)
      end
      return nil
    end,
  })

  local s, prog = current_session(load_program)
  if s then
    table.insert(doc.blocks, 1, raw(session_meta_html(s)))
    table.insert(doc.blocks, raw(session_nav_html(s, prog)))
  end
  return doc
end
