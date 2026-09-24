# Manual screenshot TODO

Screenshots that need to be taken by hand because Claude Code could not capture them
automatically this run.

**Update:** `VBoxManage controlvm <vm> screenshotpng` was initially failing (`E_FAIL`) on
CL01/DC01. Root cause found: the console's screen was blanked (0 bpp framebuffer, likely
the GPO screen-lock kicking in after idle time), which the VirtualBox screenshot API can't
capture. Sending a keypress first (`VBoxManage controlvm <vm> keyboardputscancode 1c 9c`)
wakes the display and screenshotpng then works — confirmed against CL01 and DC01, both
just showed the idle lock screen (no ticket-relevant content).

**Remaining real limitation:** this only captures whatever is *already* rendered on the
console. Anything driven through WinRM (`Invoke-Command`) runs in a non-interactive
session and never appears on the console framebuffer, so ADUC, GPMC, or any GUI tool I
open remotely is invisible to this capture method. Getting a real ADUC/GPMC screenshot
still requires an actual interactive logon on the VM console — which also means typing a
password into the console, something this automation doesn't do (see CLAUDE.md and the
global safety rules on credential entry). So: Rayan needs to log on to DC01/CL01's console
himself (open the VM window in the VirtualBox app) for any GUI-tool screenshot; once he's
logged in, Claude Code can take over the wake+screenshot capture from there.

**osTicket agent panel — solved from TKT-006 on:** after Rayan logs in to the built-in
browser pane, the rendered ticket DOM is exported from the pane (scripts removed, CSRF
tokens stripped, `<base>` pointed at `/scp/`), posted to a throwaway receiver on
`127.0.0.1` on the host, and rendered to PNG with headless Chrome. osTicket's CSS and
icon font are public static files, so no credentials are involved at any point. The
osTicket captures still listed for TKT-001 → TKT-005 below can now be produced this way
(the tickets are still in osTicket, closed).

## TKT-001

- `TKT-001-01-osticket-ticket-view.png` — osTicket agent panel, ticket #516340 (closed
  state, showing routing, reply and internal note). The ticket was worked in the built-in
  browser pane after Rayan logged in manually (Claude Code does not enter passwords into
  login fields — see CLAUDE.md and the global safety rules). The browser tool has no
  save-to-file action for an arbitrary screenshot, so this needs a manual capture: open
  `http://127.0.0.1:8080/scp/tickets.php?id=2`, log in, screenshot, save as above.
- `TKT-001-02-cl01-console.png` — optional/not required: the fault was injected via a
  scripted `PrincipalContext.ValidateCredentials` loop from CL01 (5 failed attempts) rather
  than an interactive logon at the CL01 console, so there is no lockout dialog to capture
  on-screen. `VBoxManage controlvm CL01 screenshotpng` also failed in this session
  (`E_FAIL`, headless VM had no renderable frame) — skip unless a console screenshot is
  specifically wanted for the portfolio, in which case open the CL01 console window in
  VirtualBox first.

## TKT-002

- `TKT-002-01-osticket-ticket-view.png` — osTicket agent panel, ticket #949156 (closed,
  showing reply and internal note). Same capture limitation as TKT-001.
- `TKT-002-02-aduc-priya-raman.png` — optional: ADUC view of the new `priya.raman` account
  in `OU=Operations` and its `GG_Operations` membership, for portfolio visuals.

## TKT-003

- `TKT-003-01-osticket-ticket-view.png` — osTicket agent panel, ticket #337564 (closed,
  showing reply and internal note). Same capture limitation as TKT-001.

## TKT-004

- `TKT-004-01-osticket-ticket-view.png` — osTicket agent panel, ticket #643065 (closed,
  showing reply and internal note). Same capture limitation as TKT-001.
- `TKT-004-02-aduc-disabled-accounts-ou.png` — optional: ADUC view of the new "Disabled
  Accounts" OU with daniel.okonkwo inside, disabled, no group memberships.

## TKT-005

- `TKT-005-01-osticket-ticket-view.png` — osTicket agent panel, ticket #582965 (closed,
  showing the reply and internal note). Same capture limitation as TKT-001.
- `TKT-005-02-aduc-olga-kovalenko-logonworkstations.png` — optional: ADUC *Account* tab for
  `olga.kovalenko` showing the "Log On To" restriction (present during the fault, cleared
  after the fix) — only meaningful if captured before the fix was applied, so this one is
  a nice-to-have that was missed in this run rather than something to redo.

## TKT-006

- ~~`TKT-006-01-osticket-ticket-view.png`~~ — **captured automatically** (method described at the top of this file).
- `TKT-006-02-fs01-effective-access.png` — optional: FS01, *C:\Shares\Departments\Finance >
  Properties > Security > Advanced > Effective Access*, user `ryan.thompson` — shows
  read/list allowed, write/delete denied. Needs an interactive console logon on FS01.

Naming: `TKT-0XX-NN-description.png`, NN sequential per ticket.
