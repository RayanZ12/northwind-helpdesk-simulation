# Northwind Supply — Helpdesk Ticket Catalog

**Project 2 — Helpdesk Simulation**
20 incidents and service requests processed through osTicket on the Northwind Active Directory environment.

Each ticket below documents:
- **User submission** — written as the end user would write it, with the ambiguity and missing detail typical of real helpdesk intake
- **Routing** — help topic, department, priority and SLA target
- **Fault injection** — the configuration change performed on the lab to reproduce the incident
- **Expected resolution path** — the diagnostic approach a Tier 1 technician would follow

> All users, company data and incidents are fictional. Faults were deliberately introduced on the lab infrastructure and resolved with full documentation.

---

## Category A — Accounts and Authentication (7 tickets)

### TKT-001 — Can't log in, says password is wrong

**From:** Samuel Mensah (Sales)
**Help Topic:** Password Reset / Account Locked
**Priority:** High — **SLA:** P2 (8h)

> Hi, I tried logging in this morning and it keeps saying my password is incorrect. I'm typing the same one I always use. I tried like five times. Can you reset it? I have a client call at 11.

**Fault injection:** Repeated failed logon attempts on CL01 until the account lockout threshold in the Default Domain Policy is reached.

**Resolution path:** Confirm lockout with `Search-ADAccount -LockedOut`; verify `BadPwdCount` and `LockedOut` attributes; unlock with `Unlock-ADAccount`; reset password; confirm user logon.

---

### TKT-002 — New starter needs an account

**From:** Aisha Rahman (HR)
**Help Topic:** New User Account Request
**Priority:** Normal — **SLA:** P3 (24h)

> Hello IT, we have a new person starting in Operations on Monday. Her name is Priya Raman. She'll need the usual — email, the shared drives, a laptop. Let me know if you need anything else from me.

**Fault injection:** None — this is a service request, not an incident.

**Resolution path:** Create the AD user in the correct OU; assign department security groups following the AGDLP model; create the home folder; verify drive mapping applies at logon; document in the onboarding checklist.

**Note:** This ticket demonstrates the difference between an incident and a service request — a distinction most Tier 1 candidates cannot articulate.

---

### TKT-003 — Password expired and now I'm stuck

**From:** Marco Rossi (Finance)
**Help Topic:** Password Reset / Account Locked
**Priority:** High — **SLA:** P2 (8h)

> It asked me to change my password when I logged in and I did, but now nothing works. It says the password doesn't meet requirements. What are the requirements?

**Fault injection:** Set `ChangePasswordAtLogon` on the account; the user attempts a password that fails the complexity policy.

**Resolution path:** Review the password policy with `Get-ADDefaultDomainPasswordPolicy`; explain the complexity requirements to the user in plain language; assist with the change; confirm successful logon.

---

### TKT-004 — Former employee still has access

**From:** Aisha Rahman (HR)
**Help Topic:** New User Account Request
**Priority:** High — **SLA:** P2 (8h)

> Hi, I noticed that Daniel's account is still active. He left the company two weeks ago. Can you check? I think this might be a problem for the audit.

**Fault injection:** Leave a test account enabled with group memberships intact.

**Resolution path:** Disable the account; remove group memberships; move to a Disabled Accounts OU; document the offboarding steps taken. Escalate the process gap — not the individual account — to Tier 2 as a policy issue.

**Note:** Good candidate for demonstrating that the fix and the root cause are two different things.

---

### TKT-005 — I can log in on my laptop but not the meeting room PC

**From:** Chen Wei (Operations)
**Help Topic:** Password Reset / Account Locked
**Priority:** Normal — **SLA:** P3 (24h)

> Works fine at my desk. On the meeting room computer it says my account can't sign in there. Is my account broken?

**Fault injection:** Configure a logon workstation restriction on the account.

**Resolution path:** Check the `LogonWorkstations` attribute; confirm the restriction is the cause rather than a credential problem; either clear the restriction or add the target machine, depending on policy.

---

### TKT-006 — Need access to the Finance folder

**From:** Julie Tremblay (Sales)
**Help Topic:** New User Account Request
**Priority:** Normal — **SLA:** P3 (24h)

> Hi, I need to get into the Finance shared folder for the quarterly report. Can you give me access please? Thanks.

**Fault injection:** None — access request from a user outside the owning department.

**Resolution path:** Do **not** grant access on request. Verify authorization with the Finance department owner; document the approval; grant via the appropriate global group; confirm access. If approval is not obtained, close with an explanation.

**Note:** The correct answer to this ticket is a process, not a permission change. Worth calling out explicitly in the knowledge base.

---

### TKT-007 — Getting locked out every morning

**From:** Omar Haddad (IT)
**Help Topic:** Password Reset / Account Locked
**Priority:** High — **SLA:** P2 (8h)

> Every day around 9am my account locks. I unlock it and it's fine for the rest of the day. This has happened three days in a row now.

**Fault injection:** A mapped drive or scheduled task holding a stale cached credential triggers repeated authentication failures.

**Resolution path:** Identify the source of the failures in the Security event log (Event ID 4740 and 4771) on the domain controller; locate the calling machine; clear the cached credential. This is a recurring lockout, not a one-off — the fix is finding the source, not unlocking the account again.

---

## Category B — Shares and Permissions (5 tickets)

### TKT-008 — S drive is gone

**From:** Fatima Diallo (Finance)
**Help Topic:** Shared Drive / File Access
**Priority:** High — **SLA:** P2 (8h)

> My S drive disappeared. It was there yesterday. There's a red X on it. I need the budget file for a meeting at 2.

**Fault injection:** Disable the drive mapping GPO, or break item-level targeting on the S: drive preference.

**Resolution path:** Run `gpresult /r` on the client to confirm whether the GPO is applying; check the link status and security filtering on the GPO; verify the target share is reachable; restore and force `gpupdate /force`.

---

### TKT-009 — Access denied on a folder I've always used

**From:** Kwame Osei (Operations)
**Help Topic:** Shared Drive / File Access
**Priority:** High — **SLA:** P2 (8h)

> I get "You don't have permission to access this folder" on the Operations folder. Nothing changed on my end. I've been using it for months.

**Fault injection:** Remove the domain local group from the NTFS ACL on the departmental share on FS01.

**Resolution path:** Verify the user's group membership; walk the AGDLP chain — user → global group → domain local group → ACL; identify the missing link; restore the ACL entry; confirm access after a logoff/logon to refresh the token.

---

### TKT-010 — I can open files but can't save

**From:** Priya Raman (Operations)
**Help Topic:** Shared Drive / File Access
**Priority:** High — **SLA:** P2 (8h)

> I can see everything in the shared folder and open documents, but when I try to save it says read only. Am I doing something wrong?

**Fault injection:** Replace the read-write domain local group with the read-only group in the share permissions.

**Resolution path:** Distinguish share permissions from NTFS permissions — the effective permission is the most restrictive of the two. Identify which layer is wrong; correct the group assignment; confirm write access.

**Note:** The share-versus-NTFS distinction is a standard interview question. This ticket is where you earn the right to answer it from experience.

---

### TKT-011 — My H drive is empty

**From:** Lucas Fontaine (Sales)
**Help Topic:** Shared Drive / File Access
**Priority:** Emergency — **SLA:** P1 (4h)

> All my personal files are gone. The H drive opens but there's nothing in it. Please tell me they're not deleted.

**Fault injection:** Alter the `homeDirectory` attribute on the AD account so it points to a path that does not exist, causing an empty folder to be created.

**Resolution path:** Confirm the data still exists on FS01 before doing anything else, and tell the user so — a data-loss report is an emergency until proven otherwise. Compare the `homeDirectory` attribute against the actual folder path; correct the attribute; verify the files return.

**Note:** Escalation is not required here, but reassurance is. Time to first response matters more on this ticket than on any other.

---

### TKT-012 — New shared folder for a project

**From:** Nadia Kovacs (Management)
**Help Topic:** Shared Drive / File Access
**Priority:** Normal — **SLA:** P3 (24h)

> We're starting a project with three people from Sales and two from Operations. Can we get a shared space only that group can see?

**Fault injection:** None — service request.

**Resolution path:** Create the folder on FS01; create a dedicated global group and domain local group following the AGDLP model rather than assigning users directly to the ACL; add members; document the group naming and the ownership.

---

## Category C — Network and Workstation (5 tickets)

### TKT-013 — No internet on my PC

**From:** Sofia Almeida (Sales)
**Help Topic:** Network Connectivity
**Priority:** Emergency — **SLA:** P1 (4h)

> Internet doesn't work. Everything else seems fine, I can open my files. Other people around me are okay.

**Fault injection:** Change the DNS forwarders on DC01 to an unreachable address.

**Resolution path:** Isolate the layer — ping by IP succeeds, ping by name fails, so the fault is name resolution rather than connectivity. Test with `nslookup` against an external name; inspect the forwarder configuration on the DC; correct and flush the client resolver cache.

---

### TKT-014 — Computer can't find the domain

**From:** Ibrahim Sy (Operations)
**Help Topic:** Network Connectivity
**Priority:** Emergency — **SLA:** P1 (4h)

> When I try to log in it says something like "we can't sign you in because the domain isn't available". I haven't touched anything.

**Fault injection:** Stop the DHCP service on DC01, causing the client to fall back to an APIPA address on reboot.

**Resolution path:** Check the client address with `ipconfig /all` — a 169.254.x.x address indicates DHCP failure rather than a credential problem. Verify the DHCP service state and scope on the DC; confirm the scope is authorized in AD; renew the lease; confirm domain logon.

**Note:** A real incident encountered during the build of this lab. The diagnostic sequence is documented from experience.

---

### TKT-015 — Company wallpaper disappeared

**From:** Grace Adeyemi (HR)
**Help Topic:** Software Issue
**Priority:** Normal — **SLA:** P3 (24h)

> My desktop background is just black now. It used to have the company logo. Not urgent but it looks odd on video calls.

**Fault injection:** Modify the UNC path in the desktop wallpaper GPO, or take the file server offline.

**Resolution path:** Confirm the GPO is applying with `gpresult /r`; test the UNC path from the client; verify the file exists and that the user has read access to it. A GPO can apply successfully and still produce nothing if the referenced file is unreachable.

---

### TKT-016 — Everything is very slow since this morning

**From:** Thomas Nguyen (Finance)
**Help Topic:** Workstation Hardware
**Priority:** Normal — **SLA:** P3 (24h)

> My computer is really slow today. Opening anything takes forever. It was fine last week.

**Fault injection:** Fill the system drive on the client to near capacity.

**Resolution path:** Check disk space, memory usage and running processes; identify the constraint; clear temporary files; verify improvement. Vague performance complaints require narrowing before acting — resist the urge to reboot first.

---

### TKT-017 — Can't print to the office printer

**From:** Elena Popescu (Management)
**Help Topic:** Printer Issue
**Priority:** Normal — **SLA:** P3 (24h)

> Nothing comes out when I print. The document just sits in the queue. I already restarted my computer twice.

**Fault injection:** Stop the Print Spooler service on the client, or leave a stuck job in the queue.

**Resolution path:** Check the spooler service state; clear the print queue; restart the spooler; send a test page. Note in the ticket that the user already attempted a restart — repeating a step the user has taken wastes their time and damages trust.

---

## Category D — Escalations and Requests (3 tickets)

### TKT-018 — Shared mailbox needed for the support team

**From:** Nadia Kovacs (Management)
**Help Topic:** New User Account Request
**Priority:** Normal — **SLA:** P3 (24h)

> Can we set up a single email address that three people in Operations can all monitor? Right now everything goes to one person and it's a bottleneck when she's off.

**Fault injection:** None — service request requiring infrastructure change.

**Resolution path:** Escalate to Tier 2. Meets escalation criterion 4 — infrastructure modification required. Document the request, the business justification and the reason for escalation in an internal note before reassigning.

---

### TKT-019 — Several people in Finance can't reach the shared drive

**From:** Fatima Diallo (Finance)
**Help Topic:** Shared Drive / File Access
**Priority:** Emergency — **SLA:** P1 (4h)

> It's not just me, four of us in Finance can't open the F drive. We're closing the month today.

**Fault injection:** Stop the Server service on FS01, or remove the share entirely.

**Resolution path:** Confirm the scope — multiple users affected meets escalation criterion 3. Verify the server is reachable and the share is published with `Get-SmbShare`; restore. Communicate to the affected group rather than only to the reporter.

**Note:** This ticket demonstrates that priority is driven by business impact, not by the technical difficulty of the fix.

---

### TKT-020 — Can I install this software myself?

**From:** Lucas Fontaine (Sales)
**Help Topic:** Software Issue
**Priority:** Normal — **SLA:** P3 (24h)

> I downloaded a PDF editor but it won't install, it asks for an admin password. Can you send it to me?

**Fault injection:** None — standard user without local administrator rights, which is the intended configuration.

**Resolution path:** Do not provide administrative credentials. Explain the standard-user policy; identify the legitimate business need; propose an approved alternative or route the request through software approval. Close with the reasoning documented.

**Note:** Declining a request correctly is a Tier 1 skill. This ticket exists to show that the answer to a user is sometimes no, delivered well.

---

## Summary

| Category | Tickets | P1 | P2 | P3 |
|---|---|---|---|---|
| Accounts and Authentication | 7 | 0 | 4 | 3 |
| Shares and Permissions | 5 | 1 | 3 | 1 |
| Network and Workstation | 5 | 2 | 0 | 3 |
| Escalations and Requests | 3 | 1 | 0 | 2 |
| **Total** | **20** | **4** | **7** | **9** |

**Escalated to Tier 2:** TKT-018, TKT-019
**Service requests (not incidents):** TKT-002, TKT-006, TKT-012, TKT-018, TKT-020
