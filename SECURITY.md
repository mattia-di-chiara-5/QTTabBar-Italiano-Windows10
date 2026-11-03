# Security policy

Esplora Italia 0.2.x is a preview packaging/localization of Explorer++ 1.5.0.2844, with a COM pool startup fix, separately verified build provenance and a resource-only Italian DLL update. It is not an independently audited or certified product. Maintenance is best effort; no fixed response SLA or bug bounty is offered.

Read the [assessment, privacy and known limitations](EsploraItalia/docs/SICUREZZA.md). Separate application processes are not a security sandbox. Windows, runtime components and Shell extensions must remain patched. Public computer diagnostics are not included in releases.

QTTabBar Italiano 0.6.1 is the earlier in-process extension and retains legacy security debt, including BinaryFormatter deserialization. It is not represented as fully hardened. Earlier package editions are superseded. The unrelated 5.1/5.0/4.0 version table from the former placeholder policy has been removed.

Use GitHub's **Report a vulnerability** facility if enabled. Otherwise open an issue requesting a private reporting channel without exploit details, credentials, personal paths or customer data. Do not upload sensitive dumps publicly. Include affected version, artificial reproduction data, expected/actual behavior and impact.
QTTabBar Italiano 0.7.0 preview retires direct BinaryFormatter calls in core/Memo, uses bounded typed IPC over a Windows-authenticated same-user pipe, and changes persistent data formats. Read [the security review and migration limits](Italiano/docs/SICUREZZA_0.7.0.md). It requires dedicated Explorer testing, is not a sandbox, and does not retroactively harden older installations or the emergency rollback MSI.

0.7.1 fixes the maintenance wrapper's supported-version check and selects an exact, hash-pinned rollback for 0.6.0, 0.6.1 or 0.7.0. The 0.7.0 wrapper refused 0.6.1 before restarting Explorer or running MSI. Older rollback packages retain the security limitations of their respective versions.

Maintenance restarts Explorer with the interactive user's limited token when UAC is enabled, using a session-bound temporary task removed after launch. If Windows UAC is disabled, no split token exists: the wrapper preserves that system policy and reports the limitation. QTTabBar's elevated-process IPC remains disabled; this project does not make such a Windows configuration equivalent to one with UAC enabled.
