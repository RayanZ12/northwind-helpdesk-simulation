# CLAUDE.md — Northwind Supply Lab: history, configuration & Project 2 workflow

Background for Claude Code: what has already been built, how, and why — plus the
exact workflow for finishing Project 2 (helpdesk tickets).
Treat everything below as the current state of the lab. Do not rebuild or
"fix" existing configuration without asking.

---

## 1. Overall context

- Portfolio aimed at a first IT support (Tier 1/2) job in Toronto.
- Every project is set in one fictional company: **Northwind Supply**, a Toronto
  distribution company with **45 employees**.
- All deliverables (READMEs, scripts, KB articles) are in **English**.
- Working style: GUI for steps worth showing in the portfolio (wizards, consoles),
  PowerShell for bulk operations. Tests are usually batched at the end of a phase.
- The shared lab password must **never** appear in scripts, commits, logs or screenshots.
  Interactive scripts read it with `Read-Host -AsSecureString`; automation reads it from `.env`.

Project status: **Project 1 done**, **Project 2 in progress**.

---

## 2. Infrastructure

| VM     | OS                       | IP                     | Role |
|--------|--------------------------|------------------------|------|
| DC01   | Windows Server 2025      | 192.168.10.10 (static) | AD DS, DNS, DHCP |
| FS01   | Windows Server 2025      | 192.168.10.11 (static) | File server (shares, home folders, redirection) |
| CL01   | Windows 11               | 192.168.10.150 (static)| Domain-joined test workstation |
| HELP01 | Ubuntu Server 24.04 LTS  | 192.168.10.20 (static) | osTicket |

- Hypervisor: **VirtualBox**, all VMs on the NAT Network **`NAT-Northwind`**, `192.168.10.0/24`, gateway `192.168.10.1`.
- Host-to-lab remote access (SSH + WinRM + osTicket API) is set up — see section 6.
  NAT Network port forwarding is the working method; `VBoxManage guestcontrol` is only
  a secondary diagnostic channel and does not work reliably on every VM.

---

## 3. Project 1 — SMB Domain Lab (DONE)

### Phase 1–2: Domain controller
- DC01: static IP 192.168.10.10, DNS pointing to itself, renamed, Guest Additions installed.
- AD DS installed, new forest **`ad.northwind.ca`**, NetBIOS **`NORTHWIND`**.
  (`.local` deliberately avoided — RFC 6762 mDNS conflict; subdomain of a routable domain is best practice.)
- DNS forwarders: `8.8.8.8`, `1.1.1.1`.

### Phase 3: OUs, groups, users (PowerShell)
- **21-OU, three-tier hierarchy**:
  `NORTHWIND → Users / Computers / Groups → IT, Finance, Sales, HR, Management, Operations`
- **18 security groups, AGDLP model** — per department:
  - `GG_<Dept>` (global)
  - `DL_<Dept>_Share_RW` and `DL_<Dept>_Share_RO` (domain local)
  - `GG_<Dept>` nested into `DL_<Dept>_Share_RW`
- **45 users** from `data/employees.csv` (diverse Toronto-representative names),
  `ChangePasswordAtLogon` enabled, password entered via `Read-Host`.
- Scripts: `01-create-ou-structure.ps1`, `02-create-groups.ps1`, `03-create-users.ps1` (Project 1 repo).
- Later: bulk password reset on all 45 accounts with `Set-ADAccountPassword` + `ChangePasswordAtLogon $true`.

### Phase 4: DHCP & file server
- DHCP on DC01: scope **192.168.10.100–200**, DNS/domain options set, server authorized.
- FS01 joined to the domain in `OU=IT,OU=Computers,OU=NORTHWIND,DC=ad,DC=northwind,DC=ca`.
- SMB shares under `C:\Shares\`: one per department (`C:\Shares\Departments\<Dept>`), `Public`,
  hidden `Home$`, hidden `Redirected$` (`C:\Shares\Redirected`).
- NTFS hardening per department folder: inheritance disabled (`/inheritance:d`),
  **`BUILTIN\Users` removed explicitly**, then `SYSTEM` Full, `Domain Admins` Full,
  `DL_<Dept>_Share_RW` Modify.
- Per-user home folders, owner has Modify.

### Phase 5: Group Policy (7 GPOs, one concern each)
| GPO | Scope | Effect |
|---|---|---|
| Default Domain Policy | Domain | Password policy + lockout (5 attempts / 15 min) |
| GPO_Security_ScreenLock | Workstations | `scrnsave.scr`, 15 min, password on resume |
| GPO_Branding_Wallpaper | Linked on OU `NORTHWIND` | Wallpaper `\\FS01\Public\wallpaper.jpg`, style Fill |
| GPO_Restrictions_ControlPanel | Users | Control Panel/Settings blocked; **explicit Deny ACL for `GG_IT`** |
| GPO_Security_Workstation | Workstations | Firewall on all profiles, USB storage read-only, legal logon banner |
| GPO_Drives_Mapping | Users | GPP drive maps: `H:` (`\\FS01\Home$\%LogonUser%`) + one `S:` per department with item-level targeting on `GG_<Dept>` |
| GPO_Folder_Redirection | Users | Documents + Desktop → `\\FS01\Redirected$` |

Gotchas already solved (don't reintroduce):
- `Import-Module ActiveDirectory` is required before `Get-Acl "AD:\..."`.
- `Get-GPPermission` shows the explicit Deny as `GpoCustom / Denied=False` — known cmdlet limitation; verify via `(Get-Acl ...).Access`.
- `Redirected$` once pointed to `D:` (the VM's CD drive) — now `C:\Shares\Redirected`.
- Wallpaper GPO was initially unlinked; file had a missing then double extension (`wallpaper.jpg.jpg`).
- `H:` must be mapped by **one** method only (AD profile attribute **or** GPO, not both) — pending cleanup item.
- Password policy should be aligned with **NIST SP 800-63B** (improvement item).

### Phase 6: Client
- CL01 (Windows 11) installed with EFI, TPM and Secure Boot **disabled** (legacy BIOS boot — this is what worked in VirtualBox), `oobe\bypassnro`, local account `labadmin`.
- Joined with `Add-Computer` into `OU=IT,OU=Computers,OU=NORTHWIND,...`.
- Validated with test users (`marco.rossi`, Sales) via `gpresult /r` (AGDLP chain `GG_Sales → DL_Sales_Share_RW` confirmed) and registry check of the wallpaper policy.

### Planned improvements (not done)
NTP hierarchy, reverse DNS zone, tiered admin accounts with GPO "Deny log on", Windows LAPS, a second client CL02.

---

## 4. Project 2 — Helpdesk Simulation with osTicket (IN PROGRESS)

Goal: demonstrate helpdesk operations (ticket handling, SLAs, escalation, KB writing)
on top of the Project 1 environment. The value is in the process and the KB articles,
not in osTicket itself.

### Phase 1: Deployment (done)
- HELP01: Ubuntu Server 24.04 LTS, static IP 192.168.10.20 set in the installer.
- LAMP: Apache2, **MariaDB**, PHP + osTicket extensions (apt).
- `mariadb-secure-installation` run; database `osticket`, least-privilege user `osticketuser@localhost`.
- **osTicket v1.18.2** deployed to `/var/www/html/`.
- Post-install hardening: `/var/www/html/setup/` removed, `include/ost-config.php` set to `644`.
- URLs (from the host, via port forwarding): user portal `http://127.0.0.1:8080/`, agent panel `http://127.0.0.1:8080/scp/`.
- Admin/agent account: `rayan.admin`.

### Phase 2: Business configuration (done)
- **Departments:** General Support, Network & Access, Hardware.
- **SLA plans:** P1 Critical 4h (24/7), P2 High 8h (business hours), P3 Normal 24h (business hours).
- **7 help topics** with automatic routing and priority (e.g. "Password Reset / Account Locked" → High / P2).
- **Agents:** `rayan.admin` (Tier 1), David Okonkwo (fictional Tier 2, escalation).
- **Escalation rules Tier 1 → Tier 2:** >75% of SLA elapsed; privileged access needed (Domain Admins, GPO change); >3 users impacted; infrastructure change needed (DNS, DHCP, AD schema).
- **45 users imported** from AD: CSV generated with `Get-ADUser` on DC01 → `C:\Temp\osticket-users.csv` → osTicket import.

### Unplanned incident (documented as portfolio material)
- CL01 lost domain connectivity: fell back to APIPA (169.254.x.x), DHCP requests not reaching DC01 although the service and scope were fine.
- Fix: static IP on CL01 `192.168.10.150/24`, gateway `192.168.10.1`, DNS `192.168.10.10` (outside the DHCP scope).
- `marco.rossi` got locked out during repeated attempts; logon restored with `samuel.mensah`.
- Worth its own KB article (`kb/INC-001-cl01-apipa.md`) at the end of the ticket run.

### Phase 3–4: Ticket catalog
- 20 tickets, **TKT-001 → TKT-020**, in English, in `tickets/catalog.md`. Each has: user submission,
  routing metadata, fault injection instructions, resolution path.
- Categories: accounts/authentication (7), shares/permissions (5), network/workstation (5), escalations/service requests (3).
- Priorities: 4× P1, 7× P2, 9× P3. 5 are service requests; 3 have a "correct answer" that is refusal/process, not a technical fix.
- **Status: no ticket has been fully processed and documented yet.** TKT-001 was walked
  through as a design exercise (workflow below) but must be run end to end like the others,
  starting the run at TKT-001.
- TKT-001 reference workflow: `samuel.mensah` (Sales) locked out, error misleadingly says wrong
  password. Help topic Password Reset / Account Locked, High, P2. Check lockout policy on DC01 →
  trigger lockout on CL01 (5 bad attempts) → `Search-ADAccount -LockedOut`, `Get-ADUser` →
  `Unlock-ADAccount` → `Set-ADAccountPassword` + `Set-ADUser -ChangePasswordAtLogon $true` →
  close ticket with user reply + internal technical note.

### Remaining work
- Process TKT-001 → TKT-020 with the workflow in section 5.
- KB article for each ticket (section 8) + screenshots (section 9).
- KB article for the CL01 APIPA incident.
- Final README update.
- Optional: add a Jira Service Management or ServiceNow PDI instance.

---

## 5. Ticket processing workflow (TKT-001 → TKT-020)

For each ticket, **one at a time, in catalog order**:

1. **Prepare** — make sure only the VMs this ticket needs are running (see RAM note, section 6).
2. **Create** the ticket through the osTicket API (`scripts/New-OsTicket.ps1`), with the
   submitter, subject and message from the catalog. Then set help topic / department /
   priority in the agent panel if the API did not route it as the catalog specifies.
3. **Inject the fault** on the correct VM, exactly as the catalog's reproduction steps say.
4. **Diagnose** as a Tier 1 technician would: gather evidence first (logs, `Get-*` commands,
   `gpresult`, event viewer), and record each check and what it showed.
5. **Resolve for real** — perform the actual fix, not just close the ticket.
6. **Verify** by re-testing the original failing condition.
7. **Close** the ticket in osTicket with a user-facing reply (plain English, no jargon) and an
   internal technical note (commands, root cause).
8. **Screenshots** (section 9) and **KB article** `kb/TKT-0XX.md` (section 8).
9. **Update** the status table in `README.md`.
10. **Commit**: `git add .` then `git commit -m "TKT-0XX: <short title>"`.

Rules for the run:
- **Stop after TKT-003** on the first run so the user can validate method and format.
  After that, work in batches of 4–5 tickets, one category at a time, then stop for review.
- If a ticket leaves the lab in an unexpected state (lockout that did not clear, permission
  that did not apply, VM unreachable), **stop and report** instead of moving on on a broken baseline.
- Escalation / refusal tickets: the correct outcome may be a documented refusal or a handoff to
  David Okonkwo (Tier 2) with the matching escalation trigger from section 4 — do not force a
  technical fix that a Tier 1 technician should not perform.
- Faults must be reversible and limited to the objects named in the ticket.

---

## 6. Host ↔ Lab Remote Access (DONE)

Goal: let the Windows host drive the lab (WinRM to the 3 Windows VMs, SSH/HTTP to
HELP01) without opening the VirtualBox console each time.

### Port forwarding (NAT Network `NAT-Northwind`, all targets via `127.0.0.1` on the host)
| Rule | Host port | Target |
|---|---|---|
| SSH-HELP01 | 2222 | HELP01:22 |
| HTTP-HELP01 | 8080 | HELP01:80 |
| WINRM-DC01 | 55985 | DC01:5985 |
| WINRM-FS01 | 55986 | FS01:5985 |
| WINRM-CL01 | 55987 | CL01:5985 |

Managed with `VBoxManage natnetwork modify --netname NAT-Northwind --port-forward-4 "..."`.

### WinRM / PowerShell Remoting
- `Enable-PSRemoting -Force -SkipNetworkProfileCheck` run on DC01, FS01, CL01.
- Basic auth + unencrypted traffic allowed on both the VM (`WSMan:\localhost\Service\...`)
  and the host client (`WSMan:\localhost\Client\...`) — acceptable only because this is
  127.0.0.1-only lab traffic through VirtualBox NAT, never do this on a real network.
- Host `TrustedHosts` set to `127.0.0.1`.
- **Gotcha (don't rediscover this):** `-Authentication Basic` with a domain account fails with
  "Access Denied" on FS01 and CL01 (Basic auth on a member machine only checks the local SAM).
  It works on DC01 only because a DC has no separate local SAM.
  **Always use `-Authentication Negotiate`** for domain accounts:
  ```powershell
  $cred = New-Object System.Management.Automation.PSCredential('NORTHWIND\Administrator', $secpw)
  Invoke-Command -ComputerName 127.0.0.1 -Port 55987 -Credential $cred -Authentication Negotiate -ScriptBlock { hostname }
  ```
  Helper: `scripts/Connect-Lab.ps1` wraps this (reads `.env`, one function per VM).
- **FS01 IP conflict found and fixed:** FS01 was still answering on `192.168.10.20` (HELP01's
  address). Fixed to `192.168.10.11/24`, gateway `192.168.10.1`, DNS `192.168.10.10`. If WinRM to
  FS01 stops responding, check the actual IP first (`ipconfig` in console, or
  `VBoxManage guestproperty enumerate FS01`) before assuming a firewall/auth problem.
- **Known unresolved issue:** `VBoxManage guestcontrol run` against FS01 fails ("specified user
  was not able to logon on guest"). Probably a `SeBatchLogonRight` restriction. Not blocking
  (WinRM covers the need) — do not rely on `guestcontrol` for FS01.

### SSH to HELP01
- Host key: `~/.ssh/northwind_ed25519` (ed25519, no passphrase), installed for user `sysadmin`.
- Command: `ssh -i ~/.ssh/northwind_ed25519 -p 2222 sysadmin@127.0.0.1`.

### osTicket API
- API key created in Admin Panel > Manage > API, "Can Create Tickets", restricted to IP
  `192.168.10.1` (HELP01 sees host requests arriving from the NAT Network gateway, not from
  127.0.0.1). If the key is rejected, check osTicket's System Logs for the IP actually seen.
- `.env`: `OSTICKET_URL=http://127.0.0.1:8080`, `OSTICKET_API_KEY=...`.
- Endpoint: `POST {OSTICKET_URL}/api/tickets.json`, header `X-API-Key`.
- **Gotcha:** "Request headers must contain only ASCII characters" = invisible character
  pasted with the key. Retype it by hand in `.env` or regenerate it. The helper script trims
  the value and rejects non-ASCII keys with a clear message.

### Host resource note
- Host has 16 GB RAM. All 4 VMs together (DC01 4096 + FS01 3072 + CL01 4096 + HELP01 2048 MB)
  exhaust memory; HELP01 then fails with `VERR_UNRESOLVED_ERROR` / Windows error 1455.
  **Start only the VMs needed for the current ticket** and power off the rest
  (`VBoxManage controlvm <vm> poweroff`; ACPI shutdown does not work on these guests).
- Typical needs: account tickets → DC01 + CL01 (+ HELP01 briefly for the ticket);
  share tickets → DC01 + FS01 + CL01; osTicket-only steps → HELP01.
  If RAM is short, create/close tickets in osTicket in a separate phase from the fault work.

### Rules Claude Code follows for this lab (don't relitigate)
- Never touch Active Directory configuration **outside the objects named in the current ticket**
  (e.g. unlocking the named user is fine; changing OUs, groups policy, other accounts is not).
- Ask before any GPO change and before any network configuration change on a VM.
- Never display lab passwords in chat; read them from `.env` (gitignored) or ask the user to
  update that file instead of pasting a password.
- Security-setting changes (WinRM/PSRemoting enablement, firewall rules, WSMan TrustedHosts,
  Windows logon-right grants) are handed to the user as exact commands to run themselves —
  Claude Code does not execute these directly.

---

## 7. Where commands run

- AD / GPO / DNS / DHCP → **DC01**, Windows PowerShell **5.1**.
- Shares / NTFS → **FS01**.
- User-side reproduction and checks (`gpupdate /force`, `gpresult /r`, logon tests) → **CL01**.
- osTicket, Apache, MariaDB → **HELP01** (`sudo` for services and logs; Apache logs in `/var/log/apache2/`).
- PowerShell 7 on the host is reserved for Microsoft Graph (Project 3 — out of scope here).

---

## 8. KB article format

One file per ticket: `kb/TKT-0XX.md`, copied from `kb/_TEMPLATE.md`. Sections:
- **Title** — short, matches the ticket subject.
- **Metadata** — category, help topic, department, priority/SLA, affected user/system.
- **Symptom** — what the user reported, in their words.
- **Diagnosis** — each check in order, *why* it was run and what it showed.
- **Resolution** — exact steps/commands, GUI path where relevant.
- **Root cause** — one or two sentences.
- **Verification** — how the fix was confirmed.
- **Prevention** — what would avoid recurrence (optional).
- **Screenshots** — relative links to `../screenshots/TKT-0XX-*.png`.

Write for a reader who has never seen this ticket: the diagnosis logic is what has portfolio
value. Command output goes in fenced code blocks (text, not images), with any secret removed.

---

## 9. Screenshots

- VM console (ADUC, GPMC, Windows dialogs, logon errors on CL01):
  `VBoxManage controlvm "<VM>" screenshotpng <absolute path>`. This captures only what is on the
  VM's display — actions run through WinRM are invisible there. When a GUI screenshot is needed
  and the window is not open, **ask the user to open it**, or add it to the manual list.
- osTicket web UI: Playwright (headless Chromium), log in to `/scp/` with the agent credentials
  from `.env`, navigate to the exact ticket, capture.
- Command output: text in the KB, not screenshots.
- Naming: `screenshots/TKT-0XX-NN-description.png`, NN sequential per ticket.
- No password, API key or lab secret may be visible in any image.
- End of each ticket: list screenshots that must be taken manually in `screenshots/MANUAL-TODO.md`.
