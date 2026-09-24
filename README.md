# Northwind Supply — Helpdesk Simulation (osTicket)

Project 2 of a hands-on IT support portfolio. Northwind Supply is a fictional 45-employee
distribution company in Toronto; this project runs its Tier 1 helpdesk on top of the
Active Directory environment built in Project 1.

The value of this project is the **process**: intake, routing, SLA handling, diagnosis,
escalation, and knowledge base writing — not osTicket itself.

## Environment

| VM | OS | Role |
|---|---|---|
| DC01 | Windows Server 2025 | AD DS, DNS, DHCP (`ad.northwind.ca`) |
| FS01 | Windows Server 2025 | File server — department shares, home folders, folder redirection |
| CL01 | Windows 11 | Domain-joined user workstation |
| HELP01 | Ubuntu Server 24.04 | osTicket 1.18.2 (LAMP, MariaDB) |

## osTicket configuration

- **Departments:** General Support, Network & Access, Hardware
- **SLA plans:** P1 Critical 4h (24/7) · P2 High 8h (business hours) · P3 Normal 24h (business hours)
- **7 help topics** with automatic routing and priority
- **Agents:** Tier 1 technician + Tier 2 escalation contact
- **Escalation triggers:** >75% of SLA elapsed · privileged access required · >3 users impacted · infrastructure change required
- **45 users** imported from Active Directory

## Ticket catalog

Legend: ✅ done · 🔄 in progress · 📋 planned

| ID | Category | Title | Priority | Status | KB |
|---|---|---|---|---|---|
| TKT-001 | Accounts / Authentication | Account locked out — misleading "wrong password" error | P2 | ✅ | [TKT-001](kb/TKT-001.md) |
| TKT-002 | | | | 📋 | — |
| TKT-003 | | | | 📋 | — |
| TKT-004 | | | | 📋 | — |
| TKT-005 | | | | 📋 | — |
| TKT-006 | | | | 📋 | — |
| TKT-007 | | | | 📋 | — |
| TKT-008 | | | | 📋 | — |
| TKT-009 | | | | 📋 | — |
| TKT-010 | | | | 📋 | — |
| TKT-011 | | | | 📋 | — |
| TKT-012 | | | | 📋 | — |
| TKT-013 | | | | 📋 | — |
| TKT-014 | | | | 📋 | — |
| TKT-015 | | | | 📋 | — |
| TKT-016 | | | | 📋 | — |
| TKT-017 | | | | 📋 | — |
| TKT-018 | | | | 📋 | — |
| TKT-019 | | | | 📋 | — |
| TKT-020 | | | | 📋 | — |

## Incidents

| ID | Summary | KB |
|---|---|---|
| INC-001 | CL01 lost domain connectivity (APIPA) — fixed with a static IP outside the DHCP scope | 📋 |

## Repository layout

```
tickets/catalog.md     20 ticket scenarios (submission, routing, fault injection, resolution path)
kb/                    one knowledge base article per ticket
screenshots/           evidence, named TKT-0XX-NN-description.png
scripts/               helper scripts (osTicket API, lab remoting)
```

## Skills demonstrated

Active Directory account and group troubleshooting · NTFS/SMB permissions · Group Policy
diagnosis (`gpresult`) · Windows networking (DHCP, DNS, APIPA) · ticket triage and SLA
management · escalation judgment · technical writing for end users and for a knowledge base.
