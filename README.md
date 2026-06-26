# Claude Usage — Plasma 6 widget

Shows your remaining **Claude subscription** usage (5-hour session + weekly) on
the KDE Plasma 6 panel or desktop. Same data as Claude Code's status bar / the
[claude.ai usage page](https://claude.ai/new#settings/usage).

## How it works

A bundled script (`contents/scripts/claude-usage`) calls the undocumented
`https://api.anthropic.com/api/oauth/usage` endpoint using the OAuth token that
**Claude Code** already stores at `~/.claude/.credentials.json`. No API key, no
cookie scraping. The token is kept fresh by `claude` itself.

> Requires [Claude Code](https://claude.com/claude-code) installed and logged in
> on the same machine, plus `curl` and `jq`.

## Install

**From the KDE Store:** right-click panel/desktop → *Add Widgets* → *Get New
Widgets* → search "Claude Usage".

**From source:**

```sh
kpackagetool6 --type Plasma/Applet --install .     # or --upgrade
```

Then *Add Widgets* → search "Claude Usage".

Optional CLI: `ln -s "$PWD/contents/scripts/claude-usage" ~/.local/bin/claude-usage`

## Configure

Right-click → *Configure*:

- **Refresh interval** (default 5 min — the endpoint rate-limits hard, keep it ≥2).
- **Show time left until reset** — live countdown (`2h 14m left`).
- **Bar color** — follow system accent (default) or Claude orange.
- **Background** — follow system theme (default), or a solid color card with
  configurable corner radius and shadow.

## Notes

- If the token expires, the widget shows `Error: http 401` — run `claude` once to renew.
- Uses an **undocumented** endpoint; Anthropic may change it without notice.

## License

MIT — see [LICENSE](LICENSE).
