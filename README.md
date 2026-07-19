# invariantd-site

[![Tip my tokens](https://tokentip.to/badge/copyleftdev.svg?logo=1)](https://tokentip.to/@copyleftdev)

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

**DigitalOcean App Platform — static site.** No server to run: managed TLS, a
global CDN (Cloudflare-fronted), and DO manages the apex + `www` DNS for
`invariantd.com` automatically. Spec: [`deploy/app.yaml`](deploy/app.yaml).

```sh
# one-time: create the app from the spec (clones this public repo, source_dir /site)
doctl apps create --spec deploy/app.yaml

# after pushing site changes: trigger a rebuild (git source is not auto-deploy)
doctl apps create-deployment <app-id>

# inspect
doctl apps get <app-id>
doctl apps list-deployments <app-id>
```

Live app: `invariantd-site` · <https://invariantd.com> (and `www`). Deploys from
a public `git` clone URL, so no GitHub OAuth is required. To get
auto-deploy-on-push, switch the spec's `git:` block to a `github:` source with
`deploy_on_push: true` (needs the DigitalOcean GitHub app authorized on the repo).

Cost: static-site tier (~$3/mo on this account — the 3 free static slots are
already used by other sites). Bandwidth beyond the included allowance is billed
per-GiB; if the film ever gets heavy traffic, move just `site/media/` to a Spaces
CDN bucket and point the `<video>`/`poster` at it.

## Rebuilding the film

The film source and its reproducible pipeline (Playwright render → ElevenLabs v3
narration → cue-locked ffmpeg mux) live with the console in the `invariantd-web`
repo under `site/console/` (`FILM.md`). This repo carries only the rendered MP4.
