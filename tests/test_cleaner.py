"""Destructive paths run only with disposable homes and stubbed system commands."""
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
import unicodedata
import unittest

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / 'omarchy-cleaner.sh'
FIXTURES = Path(__file__).with_name('fixtures')
CATALOGUES = json.loads((FIXTURES / 'catalogues.json').read_text())
V404_CLI_PACKAGES = {cli['command']: cli['package'] for cli in CATALOGUES['v4.0.4']['clis']}
GUM_FILTER_COLUMNS = 5  # " ▸" indicator plus the three-column selection prefix


def display_width(text):
    return sum(2 if unicodedata.east_asian_width(char) in 'WF' else 1 for char in text)

STUB = r'''
import json, os, pathlib, subprocess, sys, textwrap
name = pathlib.Path(sys.argv[0]).name
args = sys.argv[1:]
with open(os.environ['CALL_LOG'], 'a') as log:
    log.write(json.dumps([name, *args]) + '\n')
if name == 'gum':
    if args[0] == 'spin':
        command = args[args.index('--') + 1:]
        if command[0] == 'sleep': sys.exit(0)
        sys.exit(subprocess.run(command).returncode)
    if args[0] == 'filter':
        rows = sys.stdin.read().splitlines()
        pathlib.Path(os.environ['CALL_LOG'] + '.filter').write_text(''.join(row + '\n' for row in rows))
        # Pick rows as a user would, by name; print them exactly, like gum.
        picked = []
        for wanted in filter(None, os.environ.get('FILTER_SELECTION', '').split('\n')):
            picked += [row for row in rows if row == wanted or row.startswith(wanted + ' ')][:1]
        print('\n'.join(picked))
        sys.exit(int(os.environ.get('FILTER_RESULT', '0')))
    if args[0] == 'confirm': sys.exit(int(os.environ.get('CONFIRM_RESULT', '1')))
    print(' '.join(args))
elif name == 'sudo':
    if args[-1] == 'true': sys.exit(int(os.environ.get('SUDO_RESULT', '0')))
    sys.exit(subprocess.run(args).returncode)
elif name == 'pacman':
    if args[0] == '-Qi':
        names = [arg for arg in args[1:] if arg != '--']
        installed = os.environ.get('INSTALLED_PACKAGES', '').split()
        descriptions = json.loads(os.environ.get('STUB_PACKAGE_DESCRIPTIONS', '{}'))
        if '--' in args:
            with open(os.environ['CALL_LOG'] + '.pacman-env', 'a') as env_log:
                env_log.write('LC_ALL=' + os.environ.get('LC_ALL', '') + ' COLUMNS=' + os.environ.get('COLUMNS', '') + '\n')
        # Like pacman, wrap values to a positive COLUMNS, even into a pipe, with
        # continuation lines indented to the 18-column value position.
        columns = os.environ.get('STUB_PACMAN_WRAP') or os.environ.get('COLUMNS', '')
        width = int(columns) - 18 if columns.isdigit() and int(columns) > 18 else 0
        for package in names:
            if package in installed:
                description = descriptions.get(package, 'Test package ' + package)
                if width:
                    description = ('\n' + ' ' * 18).join(textwrap.wrap(description, width))
                print('Name            : ' + package + '\nVersion         : 1.0-1\nDescription     : '
                      + description + '\nArchitecture    : x86_64\n')
            else:
                print("error: package '" + package + "' was not found", file=sys.stderr)
        sys.exit(0 if names and set(names) <= set(installed) else 1)
    if args[:2] == ['-Rs', '--print']:
        # Dry run: report installed packages outside the targets that need one.
        with open(os.environ['CALL_LOG'] + '.dry-run-locale', 'a') as locale_log:
            locale_log.write(os.environ.get('LC_ALL', '') + '\n')
        if os.environ.get('STUB_DRY_RUN_ERROR'):
            print('error: ' + os.environ['STUB_DRY_RUN_ERROR'], file=sys.stderr)
            sys.exit(1)
        targets = args[args.index('--') + 1:]
        required_by = json.loads(os.environ.get('STUB_REQUIRED_BY', '{}'))
        broken = [(target, needer) for target in targets
                  for needer in required_by.get(target, []) if needer not in targets]
        if broken:
            print('error: failed to prepare transaction (could not satisfy dependencies)', file=sys.stderr)
            for target, needer in broken:
                print(f":: removing {target} breaks dependency '{target}' required by {needer}", file=sys.stderr)
            sys.exit(1)
        print('\n'.join(target + '-1.0-1' for target in targets))
        sys.exit(0)
    sys.exit(int(os.environ.get('PACMAN_RESULT', '0')))
elif name in ('omarchy-webapp-remove', 'omarchy-tui-remove'):
    result = int(os.environ.get('HELPER_RESULT', '0'))
    if result == 0:
        (pathlib.Path.home() / '.local/share/applications' / (args[0] + '.desktop')).unlink()
    sys.exit(result)
elif name == 'omarchy-install-hermes-cli':
    assert args == ['--owns'], 'Only the read-only ownership query is allowed'
    stub = pathlib.Path.home() / '.local/bin/hermes'
    sys.exit(0 if not stub.is_symlink() and '# Written by omarchy-install-hermes-cli.' in stub.read_text().splitlines() else 1)
'''


class CleanerTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='cleaner-tests-')
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.home = self.root / "user's home"
        self.bindings = self.home / '.config/hypr/bindings.lua'
        self.bindings.parent.mkdir(parents=True)
        self.bindings.write_text('')
        (self.home / '.local/bin').mkdir(parents=True)
        (self.home / '.local/share/applications').mkdir(parents=True)
        self.upstream = self.root / 'omarchy'
        packaged = self.upstream / 'default/hypr/bindings/applications.lua'
        packaged.parent.mkdir(parents=True)
        shutil.copyfile(FIXTURES / 'applications.lua', packaged)
        self.packaged = packaged
        self.bin = self.root / 'bin'
        self.bin.mkdir()
        self.log = self.root / 'calls.jsonl'
        for name in ('gum', 'sudo', 'pacman', 'omarchy-webapp-remove',
                     'omarchy-tui-remove', 'omarchy-install-hermes-cli', 'clear'):
            path = self.bin / name
            path.write_text('#!' + sys.executable + '\n' + STUB)
            path.chmod(0o755)
        self.env = {**os.environ, 'HOME': str(self.home), 'OMARCHY_PATH': str(self.upstream),
                    'PATH': str(self.bin) + ':/usr/bin:/bin', 'CALL_LOG': str(self.log),
                    'LC_ALL': 'C.UTF-8', 'COLUMNS': '100'}

    def run_bash(self, code, expected=0, timeout=30, **environment):
        result = subprocess.run(['bash', '-c', 'source "$1"\n' + code, 'test', str(SCRIPT)],
                                env={**self.env, **environment}, capture_output=True, text=True,
                                timeout=timeout)
        self.assertEqual(result.returncode, expected, result.stdout + result.stderr)
        return result.stdout

    def calls(self, name):
        if not self.log.exists():
            return []
        return [row for row in map(json.loads, self.log.read_text().splitlines()) if row[0] == name]

    def install_mise(self, package='codex', command='codex'):
        subprocess.run(['bash', str(FIXTURES / 'mise-install.sh'), package, command],
                       env=self.env, check=True)
        return self.home / '.local/bin' / command

    def desktop(self, name, content=None):
        path = self.home / '.local/share/applications' / (name + '.desktop')
        path.write_text(content or CATALOGUES['v4.0.2']['desktops'][name])
        return path

    def test_catalogue_covers_upstream_and_retains_old_entries(self):
        text = SCRIPT.read_text()
        catalogue = text.split('DEFAULT_APPS=(', 1)[1].split('\n)', 1)[0]
        all_packages = set(re.findall(r'"([a-z0-9.-]+)"', catalogue))
        active = set(re.findall(r'^    "([a-z0-9.-]+)"', catalogue, re.M))
        for source in CATALOGUES.values():
            self.assertFalse(set(source['base']) - all_packages)
            self.assertFalse(set(source['drop']) - active)
            for cli in source['clis']:
                with self.subTest(cli=cli):
                    self.install_mise(cli['package'], cli['command'])
                    self.run_bash('is_npm_cli_installed ' + cli['command'])
            offered = set(self.run_bash('get_installed_npm_clis').splitlines())
            self.assertFalse({cli['command'] for cli in source['clis']} - offered)
        self.assertTrue({'ghostty', 'alacritty', 'opencode', '1password-beta', 'ufw-docker'} <= active)

    def test_v404_cli_selection_removes_only_selected_wrapper(self):
        self.packaged.unlink()
        bindings = 'o.bind("SUPER + M", "My Muse", { launch = "muse" })\n'
        self.bindings.write_text(bindings)
        sentinels = [self.home / path for path in
                     ('.local/share/mise/installs/tool/data', '.cache/muse/data', '.config/Cursor/settings')]
        for path in sentinels:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text('keep')
        for selected, kept in [('cursor-agent', 'muse'), ('muse', 'cursor-agent')]:
            with self.subTest(selected=selected):
                stubs = {cmd: self.install_mise(V404_CLI_PACKAGES[cmd], cmd)
                         for cmd in (selected, kept)}
                kept_bytes = stubs[kept].read_bytes()
                self.assertEqual(set(self.run_bash('get_installed_npm_clis').splitlines()), set(stubs))
                output = self.run_bash('main', FILTER_SELECTION='⬢ ' + selected, CONFIRM_RESULT='0')
                self.assertIn('Completed all 1 selected removal(s).', output)
                self.assertFalse(stubs[selected].exists())
                self.assertEqual(stubs[kept].read_bytes(), kept_bytes)
                self.assertEqual(self.bindings.read_text(), bindings)
                self.assertFalse(list(self.bindings.parent.glob('*.backup.*')))
                self.assertTrue(all(path.read_text() == 'keep' for path in sentinels))
        self.assertFalse(self.calls('sudo'))
        self.assertTrue(all(call[1] == '-Qi' for call in self.calls('pacman')))

    def test_v404_cli_cancellation_keeps_wrappers(self):
        self.packaged.unlink()
        originals = {}
        for cmd in ('cursor-agent', 'muse'):
            stub = self.install_mise(V404_CLI_PACKAGES[cmd], cmd)
            originals[stub] = stub.read_bytes()
        self.run_bash('main', FILTER_SELECTION='⬢ cursor-agent\n⬢ muse', CONFIRM_RESULT='1')
        for stub, content in originals.items():
            self.assertEqual(stub.read_bytes(), content)
        self.assertFalse(self.calls('sudo'))
        self.assertTrue(all(call[1] == '-Qi' for call in self.calls('pacman')))

    def test_v404_modified_wrappers_are_not_offered_or_removed(self):
        for cmd in ('cursor-agent', 'muse'):
            stub = self.install_mise(V404_CLI_PACKAGES[cmd], cmd)
            original = stub.read_text()
            self.assertIn(cmd, self.run_bash('get_installed_npm_clis').splitlines())
            variants = {
                'custom command': original + '\necho customized\n',
                'different package': original.replace(V404_CLI_PACKAGES[cmd], 'other-package'),
                'different binary': original.replace('-- "' + cmd + '"', '-- "other-command"'),
            }
            if cmd == 'muse':
                variants['different URL'] = original.replace('api.meta.ai', 'example.invalid')
            for label, content in variants.items():
                with self.subTest(command=cmd, variant=label):
                    stub.write_text(content)
                    self.assertNotIn(cmd, self.run_bash('get_installed_npm_clis').splitlines())
                    self.run_bash('remove_npm_clis ' + cmd, expected=1)
                    self.assertEqual(stub.read_text(), content)
            stub.unlink()
            self.assertNotIn(cmd, self.run_bash('get_installed_npm_clis').splitlines())
            self.run_bash('remove_npm_clis ' + cmd, expected=1)

    def test_v404_symlinks_are_not_offered_or_removed(self):
        for cmd in ('cursor-agent', 'muse'):
            with self.subTest(command=cmd):
                stub = self.install_mise(V404_CLI_PACKAGES[cmd], cmd)
                original = stub.read_bytes()
                target = self.home / (cmd + '-user-managed')
                stub.rename(target)
                stub.symlink_to(target)
                self.assertNotIn(cmd, self.run_bash('get_installed_npm_clis').splitlines())
                self.run_bash('remove_npm_clis ' + cmd, expected=1)
                self.assertTrue(stub.is_symlink())
                self.assertEqual(target.read_bytes(), original)
                target.unlink()
                self.assertNotIn(cmd, self.run_bash('get_installed_npm_clis').splitlines())
                self.run_bash('remove_npm_clis ' + cmd, expected=1)
                self.assertTrue(stub.is_symlink())

    def test_v404_cli_deletion_failure_is_reported(self):
        stubs = {cmd: self.install_mise(V404_CLI_PACKAGES[cmd], cmd)
                 for cmd in ('cursor-agent', 'muse')}
        rm = self.bin / 'rm'
        rm.write_text('#!/bin/bash\nexit 1\n')
        rm.chmod(0o755)
        for cmd, stub in stubs.items():
            with self.subTest(command=cmd):
                original = stub.read_bytes()
                output = self.run_bash('remove_items --webapps-- --npmclis-- ' + cmd, expected=2)
                self.assertIn('Could not complete any selected removals.', output)
                self.assertEqual(stub.read_bytes(), original)
        self.assertFalse(self.calls('sudo'))
        self.assertFalse(self.calls('pacman'))

    def test_all_default_desktop_launchers_detected(self):
        for name in CATALOGUES['quattro']['desktops']:
            self.desktop(name, CATALOGUES['quattro']['desktops'][name])
        output = self.run_bash('get_installed_webapps').splitlines()
        self.assertTrue(set(CATALOGUES['quattro']['desktops']) <= set(output))

    def test_current_upstream_cli_discovery_and_preservation(self):
        current = CATALOGUES['quattro-10f1cbf']
        for cli in current['clis']:
            self.install_mise(cli['package'], cli['command'])
        missing = {cli['command'] for cli in current['clis']} - set(self.run_bash('get_installed_npm_clis').splitlines())
        self.assertFalse(missing)
        for cmd in ('basecamp', 'cf', 'grok'):
            with self.subTest(command=cmd):
                stub = self.home / '.local/bin' / cmd
                original = stub.read_bytes()
                stub.write_bytes(original + b'\necho custom\n')
                self.run_bash('remove_npm_clis ' + cmd, expected=1)
                self.assertNotIn(cmd, self.run_bash('get_installed_npm_clis').splitlines())
                self.assertEqual(stub.read_bytes(), original + b'\necho custom\n')
                stub.write_bytes(original)
                self.run_bash('remove_npm_clis ' + cmd)
                self.assertFalse(stub.exists())
        self.assertFalse(self.calls('sudo'))

    def test_basecamp_cli_and_webapp_are_independent(self):
        cli = next(cli for cli in CATALOGUES['quattro-10f1cbf']['clis'] if cli['command'] == 'basecamp')
        stub = self.install_mise(cli['package'], cli['command'])
        desktop = self.desktop('Basecamp', CATALOGUES['quattro-10f1cbf']['desktops']['Basecamp'])
        desktop_bytes = desktop.read_bytes()
        output = self.run_bash('enhanced_select_packages --webapps-- Basecamp --npmclis-- basecamp; '
                               'printf "RESULT<%s>|<%s>\\n" "$SELECTED_WEBAPPS" "$SELECTED_NPMCLIS"',
                               FILTER_SELECTION='🌐 Basecamp\n⬢ basecamp')
        self.assertIn('RESULT<Basecamp>|<basecamp>', output)
        self.run_bash('remove_items --webapps-- --npmclis-- basecamp')
        self.assertFalse(stub.exists())
        self.assertEqual(desktop.read_bytes(), desktop_bytes)
        self.install_mise(cli['package'], cli['command'])
        stub_bytes = stub.read_bytes()
        self.run_bash('remove_items --webapps-- Basecamp --npmclis--')
        self.assertFalse(desktop.exists())
        self.assertEqual(stub.read_bytes(), stub_bytes)
        self.assertFalse(self.calls('sudo'))

    def test_current_native_desktop_overrides_are_preserved(self):
        # 4.0.6 adds omarchy-browser.desktop, a NoDisplay link handler copied
        # into ~/.local/share/applications next to the webapps.
        for snapshot, current in CATALOGUES.items():
            if 'native_desktops' not in current:
                continue
            for name, content in current['desktops'].items():
                self.desktop(name, content)
            native = {name: self.desktop(name, content) for name, content in current['native_desktops'].items()}
            offered = set(self.run_bash('get_installed_webapps').splitlines())
            self.assertTrue(set(current['desktops']) <= offered)
            self.assertFalse(set(native) & offered)
            for name, path in native.items():
                with self.subTest(snapshot=snapshot, name=name):
                    self.run_bash('remove_webapps ' + name, expected=1)
                    self.assertEqual(path.read_text(), current['native_desktops'][name])
        self.assertIn('omarchy-browser', CATALOGUES['v4.0.6']['native_desktops'])
        self.assertFalse(self.calls('omarchy-webapp-remove'))

    def test_current_packaged_shortcuts_preserve_personal_overrides(self):
        shutil.copyfile(FIXTURES / 'applications-10f1cbf.lua', self.packaged)
        for item, key in [('omawrite', 'SUPER + SHIFT + W'), ('Google Messages', 'SUPER + SHIFT + CTRL + G')]:
            with self.subTest(item=item):
                self.assertIn(key, self.run_bash('find_packaged_unbind_keys "' + item + '"'))
        for item in ('monologue', 'hype'):
            self.assertEqual(self.run_bash('find_packaged_unbind_keys ' + item), '')
        original = 'o.bind("SUPER + SHIFT + W", "My editor", { launch = "nvim" })\n'
        self.bindings.write_text(original)
        self.run_bash('cleanup_bindings omawrite')
        updated = self.bindings.read_text()
        self.assertIn(original, updated)
        self.assertLess(updated.index('hl.unbind('), updated.index('o.bind('))
        marker = self.home / '.local/state/omarchy/preinstalls-removed'
        marker.parent.mkdir(parents=True)
        marker.touch()
        self.assertEqual(self.run_bash('find_packaged_unbind_keys "Google Messages"'), '')

    def test_hermes_without_ownership_contract_is_kept(self):
        stub = self.home / '.local/bin/hermes'
        original = '#!/bin/bash\n# Written by omarchy-install-hermes-cli.\n'
        stub.write_text(original)
        helper = self.bin / 'omarchy-install-hermes-cli'
        helper.write_text('#!/bin/bash\nprintf "%s\\n" "$*" > "$CALL_LOG.owns"\nexit 1\n')
        self.assertNotIn('hermes', self.run_bash('get_installed_npm_clis').splitlines())
        self.run_bash('remove_npm_clis hermes', expected=1)
        self.assertEqual(Path(str(self.log) + '.owns').read_text(), '--owns\n')
        self.assertEqual(stub.read_text(), original)
        self.assertFalse(self.calls('sudo'))

    def test_quattro_400_wrappers_and_docker_binding(self):
        subprocess.run(['bash', str(FIXTURES / 'mise-install-4.0.0.sh'), 'codex'],
                       env=self.env, check=True)
        self.run_bash('is_npm_cli_installed codex')
        shutil.copyfile(FIXTURES / 'applications-4.0.0.lua', self.packaged)
        self.assertIn('SUPER + SHIFT + D', self.run_bash('find_packaged_unbind_keys docker'))

    def test_legacy_npx_wrappers_detected(self):
        for package, command in [('@openai/codex', 'codex'), ('playwright', 'playwright-cli'),
                                 ('@mariozechner/pi-coding-agent', 'pi')]:
            subprocess.run(['bash', str(FIXTURES / 'npx-install.sh'), package, command],
                           env=self.env, check=True)
            self.run_bash('is_npm_cli_installed ' + command)

    def test_custom_scripts_and_symlinks_are_kept(self):
        path = self.home / '.local/bin/gh'
        for content in ['#!/bin/bash\n# mise is optional\nexec /usr/bin/gh "$@"\n',
                        '#!/bin/bash\nexec mise exec gh -- gh "$@"\n',
                        '#!/bin/bash\n# pnpm dlx gh\nexec /usr/bin/gh "$@"\n']:
            path.write_text(content)
            self.run_bash('is_npm_cli_installed gh', expected=1)
        owned = self.install_mise()
        path.unlink()
        path.symlink_to(owned)
        self.run_bash('is_npm_cli_installed gh', expected=1)
        self.run_bash('is_npm_cli_installed ../codex', expected=1)

    def test_modified_wrapper_rechecked_before_removal(self):
        stub = self.install_mise()
        original = stub.read_text() + '\necho custom behaviour\n'
        stub.write_text(original)
        self.run_bash('remove_npm_clis codex', expected=1)
        self.assertEqual(stub.read_text(), original)

    def test_cli_deletion_handles_apostrophe_in_home(self):
        stub = self.install_mise()
        self.run_bash('remove_npm_clis codex')
        self.assertFalse(stub.exists())
        self.assertFalse(self.calls('sudo'))

    def test_hermes_ownership_contract(self):
        stub = self.home / '.local/bin/hermes'
        stub.write_text('#!/bin/bash\n# Written by omarchy-install-hermes-cli.\n')
        self.run_bash('remove_npm_clis hermes')
        self.assertFalse(stub.exists())
        self.assertTrue(all(call[1:] == ['--owns'] for call in self.calls('omarchy-install-hermes-cli')))
        stub.write_text('#!/bin/bash\n# My Hermes\n')
        self.run_bash('remove_npm_clis hermes', expected=1)
        self.assertTrue(stub.exists())

    def test_real_packaged_shortcuts(self):
        for item, key in [('obsidian', 'SUPER + SHIFT + O'), ('docker', 'SUPER + SHIFT + D'),
                          ('Google Messages', 'SUPER + SHIFT + CTRL + G'), ('Grok', 'SUPER + SHIFT + ALT + A')]:
            output = self.run_bash('find_packaged_unbind_keys "' + item + '"')
            self.assertIn(key, output)
        self.assertEqual(self.run_bash('find_packaged_unbind_keys omacalc'), '')

    def test_user_override_survives_and_backup_is_exact(self):
        original = 'o.bind("SUPER + SHIFT + O", "Editor", { launch = "nvim" })\n-- tail'
        self.bindings.write_text(original)
        self.bindings.chmod(0o640)
        upstream = self.packaged.read_bytes()
        self.run_bash('cleanup_bindings obsidian')
        updated = self.bindings.read_text()
        self.assertLess(updated.index('hl.unbind('), updated.index('o.bind('))
        self.assertIn(original, updated)
        self.assertEqual(self.bindings.stat().st_mode & 0o777, 0o640)
        backups = list(self.bindings.parent.glob('*.backup.*'))
        self.assertEqual(len(backups), 1)
        self.assertEqual(backups[0].read_text(), original)
        self.assertEqual(self.packaged.read_bytes(), upstream)
        if shutil.which('luajit'):
            lua = self.root / 'check.lua'
            lua.write_text('local active = {}\n'
                           'o = { bind = function(k, label, v) active[k] = label end }\n'
                           'hl = { unbind = function(k) active[k] = nil end }\n'
                           'o.bind("SUPER + SHIFT + O", "Obsidian", {})\n'
                           'dofile(arg[1])\nassert(active["SUPER + SHIFT + O"] == "Editor")\n')
            subprocess.run(['luajit', str(lua), str(self.bindings)], check=True)

    def test_comments_do_not_count_as_unbinds_and_rerun_is_idempotent(self):
        self.bindings.write_text('-- hl.unbind("SUPER + SHIFT + A")\n')
        self.run_bash('cleanup_bindings ChatGPT ChatGPT')
        text = self.bindings.read_text()
        self.assertEqual(text.count('\nhl.unbind("SUPER + SHIFT + A")'), 1)
        self.run_bash('cleanup_bindings ChatGPT')
        self.assertEqual(self.bindings.read_text(), text)
        self.assertEqual(len(list(self.bindings.parent.glob('*.backup.*'))), 1)

    def test_active_unbind_ignores_whitespace(self):
        self.bindings.write_text("hl.unbind ( 'SUPER+SHIFT+A' ) -- mine\n")
        self.assertEqual(self.run_bash('find_packaged_unbind_keys ChatGPT'), '')

    def test_identical_lines_in_long_strings_are_preserved(self):
        binding = 'o.bind("SUPER + SHIFT + O", "Obsidian", { launch = "obsidian" })'
        literal = 'local text = [=[\n]]\n' + binding + '\n]=]\n'
        self.bindings.write_text(literal + binding + '\n')
        self.run_bash('cleanup_bindings obsidian')
        self.assertIn(literal, self.bindings.read_text())
        self.assertEqual(self.bindings.read_text().count(binding), 1)

    def test_ambiguous_long_string_layouts_are_preserved(self):
        binding = 'o.bind("SUPER + SHIFT + O", "Obsidian", { launch = "obsidian" })'
        for opener in ['local closing_example = "]]"; local documentation = [[',
                       'local first = [[example]]; local second = [[']:
            with self.subTest(opener=opener):
                original = opener + '\n' + binding + '\n]]\n'
                self.bindings.write_text(original)
                self.assertEqual(self.run_bash('find_app_bindings obsidian'), '')
                self.run_bash('cleanup_bindings obsidian')
                self.assertIn(original, self.bindings.read_text())

    def test_quoted_long_opener_cannot_expose_string_contents(self):
        original = ('local quoted = "[["\nlocal text = [=[\n]]\n'
                    'o.bind("K", "Obsidian", { launch = "obsidian" })\n]=]\n')
        self.bindings.write_text(original)
        self.assertEqual(self.run_bash('find_app_bindings obsidian'), '')
        self.run_bash('cleanup_bindings obsidian')
        self.assertIn(original, self.bindings.read_text())

    def test_long_string_unbind_example_is_not_active(self):
        self.bindings.write_text('local text = [=[\n]]\nhl.unbind("SUPER + SHIFT + A")\n]=]\n')
        self.assertIn('SUPER + SHIFT + A', self.run_bash('find_packaged_unbind_keys ChatGPT'))

    def test_domain_matching_rejects_misleading_urls(self):
        for url in ['https://x.com.evil.example', 'https://xXcom',
                    'https://other.example/?next=https://x.com',
                    'https://x.com:password@other.example']:
            self.bindings.write_text(f'o.bind("K", "Site", {{ webapp = "{url}" }})\n')
            self.assertEqual(self.run_bash('find_app_bindings X'), '', url)
        self.bindings.write_text('o.bind("K", "Site", { webapp = "https://x.com:443/path" })\n')
        self.assertIn('o.bind', self.run_bash('find_app_bindings X'))

    def test_compound_or_multiline_lua_is_left_alone(self):
        text = ('o.bind("K", "App", { launch = "obsidian" }); do_something()\n'
                'o.bind("J", "App", {\n launch = "obsidian"\n})\n')
        self.bindings.write_text(text)
        self.assertEqual(self.run_bash('find_app_bindings obsidian'), '')

    def test_legacy_conf_cleanup_and_final_line(self):
        self.bindings.unlink()
        legacy = self.bindings.with_suffix('.conf')
        legacy.write_text('bindd = SUPER, O, App, exec, uwsm-app -- obsidian\n# keep final')
        self.run_bash('cleanup_bindings obsidian')
        self.assertEqual(legacy.read_text(), '# keep final\n')
        self.assertFalse(self.bindings.exists())

    def test_missing_lua_created_for_quattro(self):
        self.bindings.unlink()
        (self.bindings.parent / 'hyprland.lua').write_text('require("default.hypr.omarchy")\n')
        self.run_bash('cleanup_bindings ChatGPT')
        self.assertIn('hl.unbind("SUPER + SHIFT + A")', self.bindings.read_text())

    def test_global_flags_and_marker_disable_packaged_shortcuts(self):
        config = self.bindings.parent / 'hyprland.lua'
        for flag in ['omarchy_default_bindings', 'omarchy_preinstalled_bindings']:
            config.write_text(flag + ' = false\n')
            self.assertEqual(self.run_bash('find_packaged_unbind_keys ChatGPT'), '')
        config.write_text('-- omarchy_preinstalled_bindings = false\n')
        marker = self.home / '.local/state/omarchy/preinstalls-removed'
        marker.parent.mkdir(parents=True)
        marker.touch()
        self.assertEqual(self.run_bash('find_packaged_unbind_keys ChatGPT'), '')
        config.write_text('omarchy_preinstalled_bindings = true\n')
        self.assertIn('SUPER + SHIFT + A', self.run_bash('find_packaged_unbind_keys ChatGPT'))

    def test_backup_and_replace_failures_keep_original(self):
        original = '-- personal config\n'
        self.bindings.write_text(original)
        for command in ['cp', 'mktemp', 'mv']:
            with self.subTest(command=command):
                self.run_bash(command + '() { return 1; }; cleanup_bindings ChatGPT', expected=1)
                self.assertEqual(self.bindings.read_text(), original)

    def test_config_changed_during_cleanup_is_not_overwritten(self):
        self.run_bash('cp() { command cp "$@"; echo "-- concurrent edit" >> "$BINDINGS_FILE"; }; cleanup_bindings ChatGPT', expected=1)
        self.assertEqual(self.bindings.read_text(), '-- concurrent edit\n')

    def test_symlink_to_packaged_config_is_refused(self):
        original = self.packaged.read_bytes()
        self.bindings.unlink()
        self.bindings.symlink_to(self.packaged)
        self.run_bash('cleanup_bindings ChatGPT', expected=1)
        self.assertEqual(self.packaged.read_bytes(), original)
        self.assertTrue(self.bindings.is_symlink())

    def test_symlink_to_personal_dotfile_is_preserved(self):
        target = self.home / 'dotfiles/bindings.lua'
        target.parent.mkdir()
        target.write_text('-- my config\n')
        self.bindings.unlink()
        self.bindings.symlink_to(target)
        self.run_bash('cleanup_bindings ChatGPT')
        self.assertTrue(self.bindings.is_symlink())
        self.assertIn('hl.unbind', target.read_text())

    def test_packages_are_one_transaction(self):
        self.run_bash('remove_packages docker docker-buildx docker-compose')
        self.assertEqual(self.calls('pacman'), [['pacman', '-Rns', '--noconfirm', '--',
                                                'docker', 'docker-buildx', 'docker-compose']])

    def test_sudo_failure_counts_every_package(self):
        output = self.run_bash('REMOVE_BINDINGS=true; remove_items obsidian omawrite', expected=2, SUDO_RESULT='1')
        self.assertIn('❌ FAILED', output)
        self.assertEqual(self.bindings.read_text(), '')
        self.assertFalse(self.calls('pacman'))

    def test_package_failure_keeps_shortcuts(self):
        original = 'o.bind("K", "Obsidian", { launch = "obsidian" })\n'
        self.bindings.write_text(original)
        self.run_bash('REMOVE_BINDINGS=true; remove_items obsidian', expected=2, PACMAN_RESULT='1')
        self.assertEqual(self.bindings.read_text(), original)
        self.assertFalse(list(self.bindings.parent.glob('*.backup.*')))

    def test_partial_removal_only_cleans_successful_items(self):
        path = self.desktop('Google Photos')
        output = self.run_bash('REMOVE_BINDINGS=true; remove_items obsidian --webapps-- "Google Photos"',
                               expected=1, PACMAN_RESULT='1')
        self.assertFalse(path.exists())
        self.assertIn('PARTIAL SUCCESS', output)
        self.assertIn('SUPER + SHIFT + P', self.bindings.read_text())
        self.assertNotIn('SUPER + SHIFT + O', self.bindings.read_text())

    def test_blocked_package_is_kept_and_the_rest_removed(self):
        self.packaged.unlink()
        output = self.run_bash('main', expected=1, INSTALLED_PACKAGES='docker obsidian',
                               STUB_REQUIRED_BY=json.dumps({'docker': ['ufw-docker']}),
                               FILTER_SELECTION='📦 docker\n📦 obsidian', CONFIRM_RESULT='0')
        removals = [call for call in self.calls('pacman') if call[1] == '-Rns']
        self.assertEqual(removals, [['pacman', '-Rns', '--noconfirm', '--', 'obsidian']])
        self.assertIn('docker (required by ufw-docker)', output)
        self.assertIn('Ready to remove 1 item(s)', output)
        self.assertIn('PARTIAL SUCCESS', output)
        self.assertIn('Completed 1 of 2 selected removal(s).', output)
        self.assertIn('Not removed (required by other packages): docker', output)
        self.assertFalse([call for call in self.calls('sudo') if '--print' in call], 'dry run needs no root')
        self.assertEqual(Path(str(self.log) + '.dry-run-locale').read_text(), 'C\nC\n')

    def test_packages_needed_by_kept_packages_are_kept_too(self):
        output = self.run_bash(
            'find_blocked_packages docker containerd obsidian; printf "<%s>|<%s>|<%s>|<%s>\\n" '
            '"${REMOVABLE_PACKAGES[*]}" "${KEPT_PACKAGES[*]}" "${KEPT_REASONS[docker]}" "${KEPT_REASONS[containerd]}"',
            STUB_REQUIRED_BY=json.dumps({'docker': ['ufw-docker', 'once-bin'], 'containerd': ['docker']}))
        self.assertIn('<obsidian>|<docker containerd>|<ufw-docker, once-bin>|<docker>', output)
        self.assertFalse(self.calls('sudo'))

    def check_docker_plugin_partial_removal(self, legacy=False):
        if legacy:
            self.bindings.unlink()
            self.bindings = self.bindings.with_suffix('.conf')
        for plugin, command in [('docker-compose', 'docker compose'),
                                ('docker-buildx', 'docker buildx')]:
            with self.subTest(plugin=plugin, legacy=legacy):
                if legacy:
                    docker = 'bindd = SUPER SHIFT, D, Docker, exec, omarchy-launch-tui lazydocker\n'
                    plugin_binding = f'bindd = SUPER, P, Plugin, exec, omarchy-launch-tui {command} version\n'
                    obsidian = 'bindd = SUPER SHIFT, O, Notes, exec, uwsm-app -- obsidian\n'
                else:
                    docker = 'o.bind("SUPER + SHIFT + D", "Docker", { tui = "omarchy-launch-docker-tui" })\n'
                    plugin_binding = f'o.bind("SUPER + P", "Plugin", {{ tui = "{command} version" }})\n'
                    obsidian = 'o.bind("SUPER + SHIFT + O", "Notes", { launch = "obsidian" })\n'
                original = docker + plugin_binding + obsidian
                self.bindings.write_text(original)
                self.log.unlink(missing_ok=True)
                previous_backups = set(self.bindings.parent.glob('*.backup.*'))
                output = self.run_bash(
                    'main', expected=1, INSTALLED_PACKAGES=f'docker {plugin} obsidian',
                    STUB_REQUIRED_BY=json.dumps({'docker': ['ufw-docker']}),
                    FILTER_SELECTION=f'📦 docker ⌨\n📦 {plugin} ⌨\n📦 obsidian ⌨',
                    CONFIRM_RESULT='0')
                removals = [call for call in self.calls('pacman') if call[1] == '-Rns']
                self.assertEqual(removals, [['pacman', '-Rns', '--noconfirm', '--', plugin, 'obsidian']])
                result = self.bindings.read_text()
                self.assertIn(docker, result)
                self.assertNotIn(plugin_binding, result)
                self.assertNotIn(obsidian, result)
                self.assertNotIn('hl.unbind("SUPER + SHIFT + D")', result)
                if not legacy:
                    self.assertIn('hl.unbind("SUPER + SHIFT + O")', result)
                backups = set(self.bindings.parent.glob('*.backup.*')) - previous_backups
                self.assertEqual(len(backups), 1)
                self.assertEqual(backups.pop().read_text(), original)
                self.assertIn('Not removed (required by other packages): docker', output)
                self.assertIn('Completed 2 of 3 selected removal(s).', output)

    def test_docker_plugins_preserve_kept_docker_shortcuts(self):
        self.check_docker_plugin_partial_removal()

    def test_docker_plugins_preserve_kept_docker_legacy_shortcuts(self):
        self.check_docker_plugin_partial_removal(legacy=True)

    def test_plugin_command_matches_do_not_claim_other_docker_commands(self):
        commands = ['docker', 'docker ps', 'lazydocker', 'omarchy-launch-docker-tui',
                    'docker-compose up', 'docker compose up', 'docker compose-extra',
                    'docker-buildx version', 'docker buildx version', 'docker buildx-extra']
        for legacy in (False, True):
            with self.subTest(legacy=legacy):
                if legacy:
                    lines = [f'bindd = SUPER, {i}, Tool, exec, omarchy-launch-tui {cmd}'
                             for i, cmd in enumerate(commands)]
                else:
                    lines = [f'o.bind("SUPER + {i}", "Tool", {{ tui = "{cmd}" }})'
                             for i, cmd in enumerate(commands)]
                self.bindings.write_text('\n'.join(lines) + '\n')
                for package, indices in [('docker-compose', (4, 5)), ('docker-buildx', (7, 8)),
                                         ('lazydocker', (2, 3))]:
                    self.assertEqual(self.run_bash('find_app_bindings ' + package).splitlines(),
                                     [lines[i] for i in indices])

    def test_1password_cli_removal_preserves_gui_shortcuts(self):
        gui = 'o.bind("SUPER + SHIFT + SLASH", "Passwords", { omarchy = "1password" })\n'
        cli = 'o.bind("SUPER + P", "Vault CLI", { tui = "op item list" })\n'
        self.bindings.write_text(gui + cli)
        self.run_bash('REMOVE_BINDINGS=true; remove_items 1password-cli')
        self.assertEqual(self.bindings.read_text(), gui)
        self.assertEqual(next(self.bindings.parent.glob('*.backup.*')).read_text(), gui + cli)

    def test_docker_and_blocker_can_be_removed_together(self):
        output = self.run_bash(
            'main', INSTALLED_PACKAGES='docker ufw-docker',
            STUB_REQUIRED_BY=json.dumps({'docker': ['ufw-docker']}),
            FILTER_SELECTION='📦 docker ⌨\n📦 ufw-docker', CONFIRM_RESULT='0')
        removals = [call for call in self.calls('pacman') if call[1] == '-Rns']
        self.assertEqual(removals, [['pacman', '-Rns', '--noconfirm', '--', 'docker', 'ufw-docker']])
        self.assertIn('Completed all 2 selected removal(s).', output)
        self.assertIn('hl.unbind("SUPER + SHIFT + D")', self.bindings.read_text())

    def test_selected_docker_launcher_keeps_retained_engine_shortcuts(self):
        desktop = self.desktop('Docker')
        engine = 'o.bind("SUPER + E", "Containers", { tui = "docker ps" })\n'
        tui = 'o.bind("SUPER + SHIFT + D", "Docker", { tui = "omarchy-launch-docker-tui" })\n'
        self.bindings.write_text(engine + tui)
        output = self.run_bash(
            'main', expected=1, INSTALLED_PACKAGES='docker',
            STUB_REQUIRED_BY=json.dumps({'docker': ['ufw-docker']}),
            FILTER_SELECTION='📦 docker ⌨\n🌐 Docker ⌨', CONFIRM_RESULT='0')
        self.assertFalse(desktop.exists())
        self.assertEqual(self.calls('omarchy-tui-remove'), [['omarchy-tui-remove', 'Docker']])
        self.assertFalse([call for call in self.calls('pacman') if call[1] == '-Rns'])
        self.assertFalse(self.calls('sudo'))
        self.assertIn(engine, self.bindings.read_text())
        self.assertNotIn(tui, self.bindings.read_text())
        self.assertIn('hl.unbind("SUPER + SHIFT + D")', self.bindings.read_text())
        self.assertIn('Completed 1 of 2 selected removal(s).', output)

    def test_blocked_package_cancellation_and_sudo_failure_keep_shortcuts(self):
        original = 'o.bind("SUPER + SHIFT + O", "Notes", { launch = "obsidian" })\n'
        for confirm, sudo, status in [('1', '0', 0), ('0', '1', 2)]:
            with self.subTest(confirm=confirm, sudo=sudo):
                self.bindings.write_text(original)
                self.log.unlink(missing_ok=True)
                self.run_bash('main', expected=status, INSTALLED_PACKAGES='docker obsidian',
                              STUB_REQUIRED_BY=json.dumps({'docker': ['ufw-docker']}),
                              FILTER_SELECTION='📦 docker ⌨\n📦 obsidian ⌨',
                              CONFIRM_RESULT=confirm, SUDO_RESULT=sudo)
                self.assertFalse([call for call in self.calls('pacman') if call[1] == '-Rns'])
                self.assertEqual(self.bindings.read_text(), original)
                self.assertFalse(list(self.bindings.parent.glob('*.backup.*')))

    def test_unexpected_dependency_diagnostic_cannot_loop_forever(self):
        output = self.run_bash('find_blocked_packages obsidian; '
                               'printf "<%s>|<%s>\\n" "${REMOVABLE_PACKAGES[*]}" "${KEPT_PACKAGES[*]}"',
                               timeout=3, STUB_DRY_RUN_ERROR="could not satisfy dependencies\n"
                               ":: removing unselected-dependency breaks dependency 'library' required by consumer")
        self.assertIn('<obsidian>|<>', output)
        self.assertEqual(len(self.calls('pacman')), 1)
        self.assertFalse(self.calls('sudo'))

    def test_only_blocked_packages_removes_nothing(self):
        self.packaged.unlink()
        output = self.run_bash('main', expected=1, INSTALLED_PACKAGES='docker',
                               STUB_REQUIRED_BY=json.dumps({'docker': ['ufw-docker']}),
                               FILTER_SELECTION='📦 docker', CONFIRM_RESULT='0')
        self.assertIn('docker (required by ufw-docker)', output)
        self.assertIn('Nothing was removed', output)
        self.assertNotIn('CONFIRMATION REQUIRED', output)
        self.assertFalse(self.calls('sudo'))
        self.assertFalse([call for call in self.calls('pacman') if call[1] == '-Rns'])

    def test_unexplained_dry_run_failure_leaves_the_selection_to_pacman(self):
        output = self.run_bash('find_blocked_packages docker obsidian; '
                               'printf "<%s>|<%s>\\n" "${REMOVABLE_PACKAGES[*]}" "${KEPT_PACKAGES[*]}"',
                               STUB_DRY_RUN_ERROR='target not found: docker')
        self.assertIn('<docker obsidian>|<>', output)

    def test_shortcut_only_requires_consent(self):
        self.run_bash('remove_items --webapps-- ChatGPT', expected=2)
        self.assertEqual(self.bindings.read_text(), '')
        self.run_bash('REMOVE_BINDINGS=true; remove_items --webapps-- ChatGPT')
        self.assertIn('SUPER + SHIFT + A', self.bindings.read_text())
        self.assertFalse(self.calls('omarchy-webapp-remove'))

    def test_shortcut_cleanup_failure_is_not_success(self):
        output = self.run_bash('cp() { return 1; }; REMOVE_BINDINGS=true; remove_items --webapps-- ChatGPT', expected=2)
        self.assertIn('❌ FAILED', output)
        output = self.run_bash('cp() { return 1; }; REMOVE_BINDINGS=true; remove_items obsidian', expected=1)
        self.assertIn('PARTIAL SUCCESS', output)
        self.assertIn('cleanup could not be completed', output)

    def test_native_desktop_with_same_name_is_preserved(self):
        native = self.desktop('Google Photos', '[Desktop Entry]\nExec=my-photo-editor\n')
        self.run_bash('remove_webapps "Google Photos"', expected=1)
        self.assertTrue(native.exists())
        self.assertFalse(self.calls('omarchy-webapp-remove'))

    def test_tui_removal_is_selective(self):
        docker = self.desktop('Docker')
        usage = self.desktop('Disk Usage')
        self.run_bash('remove_webapps Docker')
        self.assertFalse(docker.exists())
        self.assertTrue(usage.exists())
        self.assertEqual(self.calls('omarchy-tui-remove'), [['omarchy-tui-remove', 'Docker']])
        self.assertFalse(self.calls('sudo'))

    def test_selection_preserves_names_and_categories(self):
        self.desktop('Google Photos')
        output = self.run_bash('enhanced_select_packages opencode --webapps-- "Google Photos" --npmclis-- opencode; '
                               'printf "RESULT<%s>|<%s>|<%s>\\n" "$SELECTED_PACKAGES" "$SELECTED_WEBAPPS" "$SELECTED_NPMCLIS"',
                               FILTER_SELECTION='🌐 Google Photos ⌨\n⬢ opencode')
        self.assertIn('RESULT<>|<Google Photos>|<opencode>', output)

    def filter_rows(self, code='enhanced_select_packages obsidian --webapps-- "Google Photos" --npmclis-- codex',
                    **environment):
        environment.setdefault('INSTALLED_PACKAGES', 'obsidian')
        self.run_bash(code, expected=1, FILTER_RESULT='1', **environment)
        return Path(str(self.log) + '.filter').read_text().splitlines()

    def test_every_curated_item_has_a_description(self):
        output = self.run_bash(
            'for name in "${DEFAULT_WEBAPPS[@]}" "${DEFAULT_TUIS[@]}"; do '
            'printf "webapp\\t%s\\t%s\\n" "$name" "$(curated_description_for webapp "$name")"; done; '
            'for name in "${DEFAULT_NPM_CLIS[@]}"; do '
            'printf "npmcli\\t%s\\t%s\\n" "$name" "$(curated_description_for npmcli "$name")"; done')
        rows = [line.split('\t') for line in output.splitlines()]
        self.assertGreaterEqual(len(rows), 40)
        for category, name, description in rows:
            with self.subTest(category=category, name=name):
                self.assertTrue(description)
                self.assertLessEqual(len(description), 100)
                self.assertEqual(description, ' '.join(description.split()))
                self.assertFalse(description.endswith('.'))
        self.assertNotEqual(self.run_bash('curated_description_for webapp Grok'),
                            self.run_bash('curated_description_for npmcli grok'))

    def test_selector_descriptions_align_and_fit_the_terminal(self):
        self.desktop('Google Photos')
        self.install_mise()
        long = ('A powerful knowledge base that works on top of a local folder of plain text '
                'Markdown files and keeps going')
        for columns in ('80', '120'):
            with self.subTest(columns=columns):
                rows = self.filter_rows(COLUMNS=columns, STUB_PACKAGE_DESCRIPTIONS=json.dumps({'obsidian': long}))
                self.assertEqual([row.split()[1] for row in rows], ['obsidian', 'Google', 'codex'])
                starts = set()
                for row, description in zip(rows, (long, 'Edit, Organize, Search', 'Codex CLI is')):
                    label, blurb = re.split(r'\s{2,}', row, maxsplit=1)
                    self.assertTrue(description.startswith(blurb.rstrip('…')) or blurb.startswith(description))
                    starts.add(GUM_FILTER_COLUMNS + display_width(row[:len(row) - len(blurb)]))
                    self.assertLessEqual(GUM_FILTER_COLUMNS + display_width(row), int(columns))
                self.assertEqual(len(starts), 1, rows)
                obsidian = re.split(r'\s{2,}', rows[0], maxsplit=1)[1]
                self.assertTrue(obsidian.endswith('…'))
                kept = obsidian[:-1]
                self.assertEqual(long[len(kept)], ' ', 'trimmed at a word boundary')
                self.assertIn('Google Photos ⌨', rows[1])

    def test_every_catalogue_label_shares_the_description_column(self):
        rows = self.filter_rows(
            'enhanced_select_packages obsidian --webapps-- "${DEFAULT_WEBAPPS[@]}" "${DEFAULT_TUIS[@]}" '
            '--npmclis-- "${DEFAULT_NPM_CLIS[@]}"', COLUMNS='200')
        self.assertTrue(any(row.startswith('🌐 Google Messages (shortcut only) ⌨ ') for row in rows), rows)
        blurbs = [re.split(r'\s{2,}', row, maxsplit=1)[1] for row in rows]
        starts = {GUM_FILTER_COLUMNS + display_width(row[:len(row) - len(blurb)])
                  for row, blurb in zip(rows, blurbs)}
        self.assertEqual(len(starts), 1, 'raise the label cap for a longer catalogue label:\n' + '\n'.join(rows))

    def test_wide_descriptions_are_trimmed_to_terminal_cells(self):
        # CJK characters take two cells each, and break without spaces.
        cjk = '基于本地纯文本文件夹的强大知识库，支持双向链接、图谱视图和丰富的社区插件生态系统'
        for wide, columns in ((text, columns) for text in (cjk, 'Obsidian ' + cjk) for columns in (40, 80)):
            environment = {'INSTALLED_PACKAGES': 'obsidian',
                           'STUB_PACKAGE_DESCRIPTIONS': json.dumps({'obsidian': wide})}
            with self.subTest(description=wide[:9], columns=columns):
                row, = self.filter_rows('enhanced_select_packages obsidian', COLUMNS=str(columns), **environment)
                output = self.run_bash('load_package_descriptions obsidian; print_confirmation_items package obsidian',
                                       COLUMNS=str(columns), **environment)
                confirmation = output.split('style --foreground 214 ', 1)[1].rstrip('\n')
                for line, used in ((row, GUM_FILTER_COLUMNS + display_width(row)),
                                   (confirmation, display_width(confirmation))):
                    blurb = re.split(r'\s{2,}', line.lstrip(), maxsplit=1)[1]
                    self.assertTrue(blurb.endswith('…') and wide.startswith(blurb[:-1]), line)
                    self.assertLessEqual(used, columns, line)
                    self.assertGreaterEqual(used, columns - 4, 'trimmed back to the space: ' + line)

    def test_narrow_terminal_or_missing_description_keeps_plain_rows(self):
        self.desktop('Google Photos')
        self.install_mise()
        self.assertEqual(self.filter_rows(COLUMNS='30'), ['📦 obsidian ⌨', '🌐 Google Photos ⌨', '⬢ codex'])
        rows = self.filter_rows('enhanced_select_packages obsidian --webapps-- --npmclis-- not-a-catalogue-cli',
                                STUB_PACKAGE_DESCRIPTIONS=json.dumps({'obsidian': 'None'}))
        self.assertEqual(rows, ['📦 obsidian ⌨', '⬢ not-a-catalogue-cli'])

    def test_package_description_control_characters_are_removed(self):
        hostile = 'Notes\x1b]0;owned\x07 app\x1b[31m in\tred\r'
        rows = self.filter_rows('enhanced_select_packages obsidian',
                                STUB_PACKAGE_DESCRIPTIONS=json.dumps({'obsidian': hostile}))
        self.assertEqual(len(rows), 1)
        self.assertFalse(any(unicodedata.category(char) == 'Cc' for char in rows[0]), repr(rows[0]))
        self.assertIn('Notes ]0;owned app [31m in red', rows[0])

    def test_described_rows_still_select_the_right_items(self):
        self.desktop('Google Photos')
        output = self.run_bash(
            'enhanced_select_packages opencode --webapps-- "Google Photos" Grok --npmclis-- opencode grok; '
            'printf "RESULT<%s>|<%s>|<%s>\\n" "$SELECTED_PACKAGES" "${SELECTED_WEBAPPS//$\'\\n\'/,}" "$SELECTED_NPMCLIS"',
            INSTALLED_PACKAGES='opencode',
            FILTER_SELECTION='📦 opencode\n🌐 Grok (shortcut only) ⌨\n⬢ grok')
        self.assertIn('RESULT<opencode>|<Grok>|<grok>', output)
        rows = Path(str(self.log) + '.filter').read_text().splitlines()
        self.assertTrue(any(row.startswith('🌐 Grok (shortcut only) ⌨  Grok is an AI assistant') for row in rows), rows)

    def test_confirmation_lists_descriptions(self):
        self.packaged.unlink()
        self.install_mise()
        output = self.run_bash('main', INSTALLED_PACKAGES='opencode', CONFIRM_RESULT='1',
                               STUB_PACKAGE_DESCRIPTIONS=json.dumps({'opencode': 'The open source coding agent'}),
                               FILTER_SELECTION='📦 opencode\n⬢ codex')
        self.assertRegex(output, r'   • opencode {2,}The open source coding agent\n')
        self.assertRegex(output, r'   • codex {2,}Codex CLI is a coding agent from OpenAI')
        self.assertFalse(self.calls('sudo'))
        self.assertTrue(all(call[1] == '-Qi' or call[1:3] == ['-Rs', '--print'] for call in self.calls('pacman')))
        self.assertTrue(self.home.joinpath('.local/bin/codex').exists())

    def test_package_descriptions_are_read_unwrapped_in_the_c_locale(self):
        self.filter_rows('enhanced_select_packages obsidian')
        self.assertEqual(Path(str(self.log) + '.pacman-env').read_text(), 'LC_ALL=C COLUMNS=0\n')
        self.assertIn(['pacman', '-Qi', '--', 'obsidian'], self.calls('pacman'))

    def test_wrapped_package_descriptions_are_kept_whole(self):
        long = 'A powerful knowledge base that works on top of a local folder of plain text Markdown files'
        environment = {**self.env, 'COLUMNS': '80', 'INSTALLED_PACKAGES': 'obsidian',
                       'STUB_PACKAGE_DESCRIPTIONS': json.dumps({'obsidian': long})}
        stub = subprocess.run([str(self.bin / 'pacman'), '-Qi', '--', 'obsidian'], env=environment,
                              capture_output=True, text=True).stdout
        self.assertIn('\n' + ' ' * 18 + 'of plain text', stub, 'the fixture wraps like pacman')
        # COLUMNS=0 alone, then continuation joining alone with forced wrapping.
        for forced_wrap in ('', '40'):
            with self.subTest(forced_wrap=forced_wrap):
                output = self.run_bash('load_package_descriptions obsidian; '
                                       'printf "<%s>" "${PACKAGE_DESCRIPTIONS[obsidian]}"',
                                       **{**environment, 'STUB_PACMAN_WRAP': forced_wrap})
                self.assertEqual(output, '<' + long + '>')
        output = self.run_bash('load_package_descriptions obsidian; print_confirmation_items package obsidian',
                               **{**environment, 'COLUMNS': '100'})
        blurb = re.search(r'   • obsidian {2,}(.*)$', output, re.M).group(1)
        self.assertTrue(blurb.endswith('…') and long.startswith(blurb[:-1]), blurb)

    def test_parse_sections_handles_empty_and_space_names(self):
        output = self.run_bash('parse_sections --webapps-- "Google Photos" --npmclis-- codex; '
                               'printf "RESULT<%s>|<%s>|<%s>\\n" "${#PARSED_PACKAGES[@]}" "${PARSED_WEBAPPS[0]}" "${PARSED_NPMCLIS[0]}"')
        self.assertIn('RESULT<0>|<Google Photos>|<codex>', output)

    def test_final_confirmation_cancellation_has_no_mutations(self):
        self.packaged.unlink()
        self.run_bash('main', INSTALLED_PACKAGES='opencode', FILTER_SELECTION='📦 opencode')
        self.assertFalse(self.calls('sudo'))
        self.assertTrue(all(call[1] == '-Qi' or call[1:3] == ['-Rs', '--print'] for call in self.calls('pacman')))
        self.assertEqual(self.bindings.read_text(), '')

    def test_selector_cancellation_has_no_mutations(self):
        self.run_bash('main', INSTALLED_PACKAGES='opencode', FILTER_RESULT='1')
        self.assertFalse(self.calls('sudo'))
        self.assertEqual(self.bindings.read_text(), '')

    def test_piped_entrypoint_still_runs(self):
        self.packaged.unlink()
        result = subprocess.run(['bash'], input=SCRIPT.read_text(), env=self.env,
                                capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('System is clean', result.stdout)


if __name__ == '__main__':
    unittest.main()
