# Portable VM workflow

## Local configuration

Read `.local/omarchy-vm.md` at the repository root before connecting. Keep this
Git-ignored file local; do not copy it into guest candidates or published reports.
It supplies the machine-specific values for:

- VM manager and guest identity, including the expected OS and unprivileged user.
- Lifecycle commands, SSH/desktop access, and any required host permissions.
- Guest workspace location and helper interface.
- Disk, firmware, snapshots, and the matching recovery procedure.
- Private credential-file locations and any local credential recovery history.

Store credential values only in the private credential files, never in the
configuration document. If local configuration is missing, complete independent
checks and report the missing VM setup; do not guess a host path or connection.

The examples below use `VM_ROOT`, set from the local configuration, as a host
directory containing these helper executables:

| Helper | Contract |
| --- | --- |
| `start` | Start the existing VM without resetting it. |
| `status` | Query the hypervisor for current guest state. |
| `ssh` | Connect to the configured unprivileged guest user; accept SSH options and a remote command. |
| `view` | Open the guest desktop through the configured viewer. |
| `stop` | Request graceful guest shutdown and wait for completion. |

If an installation uses a different interface, use its documented equivalents.
Do not create or replace helpers merely to match these examples.

## Connect and verify

```bash
# Set VM_ROOT from the private local configuration first.
"$VM_ROOT/start"
"$VM_ROOT/status"
"$VM_ROOT/ssh" 'hostname; id -un; cat /etc/os-release; systemctl is-system-running'
```

Compare identity with local configuration before any mutation. A boot may need
a short wait for SSH. A failed status command alone does not prove the VM has
stopped. Diagnose unexpected host-key changes; do not disable verification.
Preserve the configured network isolation and avoid adding host filesystem shares.
Allocate a host tool PTY as well as SSH `-t` for interactive terminal checks.

## Copy the exact candidate

Run from the candidate checkout. This example uses a fresh temporary directory
inside the guest; use a private configured workspace instead if persistence across
guest reboots is needed. Validate a returned path before embedding it in commands.

```bash
guest_run=$("$VM_ROOT/ssh" 'mktemp -d /tmp/cleaner-review.XXXXXXXX')
[[ "$guest_run" =~ ^/tmp/cleaner-review\.[A-Za-z0-9]+$ ]] || exit 1
```

For current working-tree code, copy the actual script and tests, including
untracked tests needed by the change. Inspect these paths for unrelated files or
links outside the checkout; extend the explicit list for required test assets.
Do not copy `.git`, `.local`, credentials, or VM state. Avoid archiving the entire
working directory: Git ignore rules do not protect against a broad `tar` command.

```bash
set -o pipefail
tar --exclude='__pycache__' --exclude='*.pyc' -cf - omarchy-cleaner.sh tests |
    "$VM_ROOT/ssh" "tar -xf - -C '$guest_run'"
sha256sum omarchy-cleaner.sh
"$VM_ROOT/ssh" "sha256sum '$guest_run/omarchy-cleaner.sh'"
"$VM_ROOT/ssh" "cd '$guest_run' && bash -n omarchy-cleaner.sh && python3 -m unittest discover -s tests -v"
```

Compare script hashes and verify transferred test/support files as well, such as
with a content-hash manifest. For committed code, an archive of the exact candidate
SHA can replace the tar producer. This omits uncommitted work, so use it only when
the commit is the intended candidate. Record candidate identity without including
local checkout paths or other machine-specific values in public reports.

Run the real interface in an allocated PTY:

```bash
"$VM_ROOT/ssh" -t "cd '$guest_run' && ./omarchy-cleaner.sh"
```

Do not pipe a password into the cleaner's stdin: it uses a real terminal. Guest
sudo should use that terminal or a separately established credential cache in
the same session. For screenshots and shortcut checks, use the guest desktop.
Keep screenshots and raw logs private unless checked and sanitized for publication.

## Snapshot and recovery

Use the VM manager and recovery instructions from local configuration. Establish
the baseline's contents before restoring; existing snapshots may predate guest
work or credential changes. Prefer a unique pre-test snapshot when preserving
the current guest matters. Never overwrite an existing baseline.

1. Inspect active sessions and preserve unrelated work. Save evidence outside the
   guest in Git-ignored local storage. Shut down gracefully and verify the VM
   process has exited before using offline disk tools. Resolve shutdown failures
   before restoring; never bypass an image lock or force a disk mutation.
2. Capture the pre-test disk state using the configured snapshot mechanism.
   Preserve matching firmware and any recovery credentials outside the guest,
   with private permissions. Record their association in local configuration.
3. Start the guest and run the scoped tests. Export evidence before restoring.
4. Stop the guest again, restore the matching disk and firmware state, and follow
   local credential recovery instructions. Preserve the user's chosen password:
   an older snapshot must not leave it silently reverted. Keep guest passwords
   and helper credentials consistent without logging them.
5. Restart and verify identity, SSH access, and service health. Return the VM to
   its original running/stopped state unless the task requires otherwise.

Remove only your own temporary snapshots and files after successful recovery
when no longer needed. Keep final public reports to reproducible behavior,
candidate/OS versions, sanitized commands, results, and coverage limits. Record
exact local snapshot names, file paths, and recovery history only in `.local/`.
