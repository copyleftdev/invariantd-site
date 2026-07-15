# invariantd-site

Marketing site for [invariantd.com](https://invariantd.com) — the runtime
verification engine for Linux infrastructure.

A single static page, video-first: the landing opens on the **command center
film** (a global fleet under one live attack campaign, every step verified and —
where the rule is unambiguous — neutralized on the host), then the spec-sheet
sections that explain how it works, how it responds, and how it compares.

Dedicated repo for the site only. The `invariantd` product repo carries the
engine; `invariantd-web` was the earlier combined site + interactive demo. This
repo supersedes that for what serves invariantd.com.

## Layout

```
site/
  index.html          the page
  css/main.css        metrology light theme — Archivo · Source Serif 4 · Fragment Mono
  js/main.js          film player, violation-readout reveal, contact form
  media/
    invariantd-demo.mp4   the ~3:12 film (faststart, click-to-play with sound)
    poster.jpg            hero poster frame
  og.jpg              social share image (1200×630)
  robots.txt · sitemap.xml
deploy/               Caddy + Docker on a DigitalOcean droplet
```

## Design

Light, instrument-panel aesthetic tinted toward teal. One teal accent; signal
red reserved for the violation readout and the `critical` response tier. Type is
Archivo (headings/labels, semi-expanded), Source Serif 4 (prose), Fragment Mono
(data). Numbered document sections with a margin rail. Fully functional without
JavaScript; the film is `preload="none"` so the landing stays light and only
fetches on play.

## Contact form

Web3Forms (`site/index.html`, hidden `access_key`). Public by design for a static
form; rotate in the Web3Forms dashboard and update the input if needed.

## Deploy

Caddy (automatic HTTPS) in Docker on a DigitalOcean droplet. The scripts rsync
`site/` to the droplet — no git pull on the server.

```sh
deploy/setup.sh    # one-time: create + provision the droplet (droplet "invariantd-web")
deploy/update.sh   # push site changes to the live droplet, rebuild Caddy
deploy/status.sh   # droplet + DNS + HTTPS health check
```

Requires `doctl` authenticated and an SSH key registered with DigitalOcean.
`update.sh` targets the existing `invariantd-web` droplet at `/opt/invariantd`,
so it is a drop-in replacement for whatever serves invariantd.com today.

## Rebuilding the film

The film source and its reproducible pipeline (Playwright render → ElevenLabs v3
narration → cue-locked ffmpeg mux) live with the console in the `invariantd-web`
repo under `site/console/` (`FILM.md`). This repo carries only the rendered MP4.
