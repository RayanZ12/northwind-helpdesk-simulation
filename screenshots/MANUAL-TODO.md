# Manual screenshot TODO

Screenshots that need to be taken by hand because Claude Code could not capture them
automatically this run.

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

Naming: `TKT-0XX-NN-description.png`, NN sequential per ticket.
