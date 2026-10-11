---
name: omarchy-vm-testing
description: Validate Omarchy Cleaner runtime changes and pull requests in its existing disposable Omarchy VM, using isolated regression tests and targeted live checks with recoverable snapshots. Use for catalogue, detection, selection, removal, bindings, privilege, and TUI changes; documentation-only edits need no live VM run.
---

# Omarchy VM testing

Use the existing guest to establish whether the candidate works on real Omarchy.
Read the repository's `AGENTS.md` and the changed code before choosing live cases.
For host commands, guest access, candidate transfer, and snapshot recovery, read
[references/vm-workflow.md](references/vm-workflow.md).
Read `.local/omarchy-vm.md` in the candidate repository root for private machine
configuration. This Git-ignored file supplies access details; it is not part of
the skill distribution. When using a separate worktree, consult the original
checkout's local configuration without adding it to the candidate archive.

## Boundaries and readiness

- Run the cleaner only inside the **VM guest**, reached through the configured
  SSH connection or desktop. A container hosting the hypervisor may still access
  host files; do not run removals there or in the host shell.
- Verify the guest's current version and identity against local configuration;
  do not assume it
  matches current upstream or silently upgrade it to make a test pass.
- Use the locally configured VM and helpers. If configuration or access is
  unavailable, diagnose and report what is blocked; do not install another
  environment or bypass sandbox policy.
- A requested implementation or PR test permits relevant tests in this disposable
  guest. Before any reset, establish that guest changes are disposable test state
  or preserve them. Do not overwrite another session's work or reset merely to
  run read-only checks. Ask only if ownership of valuable guest state is unclear.
- Never print credentials, place them in command arguments, or copy host secrets
  into a candidate checkout. Read the private credential through standard input
  when guest sudo needs it. Run the cleaner as the configured unprivileged guest
  user, not as root. Keep machine-specific values, local paths, credential
  locations, and recovery history in `.local/`, never in committed artifacts.

## Candidate and regression checks

1. Identify the precise candidate: PR head SHA, proposed merge SHA if relevant,
   or working-tree base SHA plus uncommitted changes. Review PR scripts before
   executing them. Fetch/check out PRs in an isolated worktree if necessary;
   preserve the user's checkout and edits.
2. Run `bash -n omarchy-cleaner.sh` and ShellCheck when available. Copy the
   candidate into a fresh guest directory, including modified/untracked test
   files needed by the change. `git archive HEAD` alone omits uncommitted work.
   Verify transferred content against the source; never assume an existing guest
   checkout contains the candidate.
3. Inside the guest, run syntax validation and
   `python3 -m unittest discover -s tests -v`. Report the observed test count.
   Passing stubbed regression tests is distinct from passing live tests.

## Targeted live checks

Start with scan and cancel through the real `gum` interface, using a PTY or the
desktop. Nothing should be selected by default. Cancel at selection and, where
affected, at final confirmation; compare relevant state before and after.

Choose live cases according to the diff, using actual installed defaults:

| Changed behavior | Evidence to collect |
| --- | --- |
| Catalogue or discovery | Installed package names, desktop contents, and wrapper ownership agree with offered items; absent/customized items are excluded. Compare upstream sources for the version being claimed. |
| Selection or confirmation | Names with spaces and category boundaries survive; final confirmation lists exactly the selection; cancellation causes no removals or binding edits. |
| Package removal or sudo | One selected disposable package is removed through the expected transaction; unselected apps remain; refusal/failure is reported and retains shortcuts. Only the package transaction uses sudo. |
| Webapp/TUI or CLI removal | Selected owned launcher/wrapper disappears; unselected and customized files remain. Same-name native desktops and symlinks remain protected. |
| Binding cleanup | Consent is respected; backup is exact; only successful removals affect matching shortcuts; personal overrides still work; packaged config and the global removal marker remain unchanged. |
| TUI or summaries | Real display renders and accepts input; success, cancellation, and partial/failure output agree with actual results. |

For removals, capture relevant package/file/binding state first and establish a
recoverable snapshot. Use only disposable guest targets. Preserve evidence
outside the guest before restoring. Exercise failure cases with isolated stubs
when a live failure would require unrelated system damage. Do not claim a live
failure-path test when only its regression test ran.

If the diff changes Bash entrypoint or stdin handling, also exercise the piped
entrypoint with a real terminal. Use desktop/Hyprland validation for actual
shortcut behavior; an SSH PTY alone cannot prove shortcuts work. Legacy formats
and upstream revisions absent from the guest need fixtures or a separately
authorized environment; state that coverage limit explicitly.

## Finish and report

Restore test mutations to the captured pre-test state when finished, preserving
the user's current password and unrelated guest work. Confirm SSH and guest
health after a restore. Leave the environment ready for the next test.

Report candidate identity, guest version, commands and results, the live cases
actually exercised, failures and coverage limits, and final snapshot/VM state.
Keep raw logs and screenshots containing local details in Git-ignored storage.
Use sanitized commands and results in committed or public reports; exclude
machine identifiers, access paths, addresses, ports, and credential locations.
For PR reviews, connect findings to the changed behavior and evidence. Do not
merge, push, post comments, or modify PR state solely because this skill ran.
