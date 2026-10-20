"""Destructive paths run only with disposable homes and stubbed system commands."""
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / 'omarchy-cleaner.sh'
FIXTURES = Path(__file__).with_name('fixtures')
CATALOGUES = json.loads((FIXTURES / 'catalogues.json').read_text())
V404_CLI_PACKAGES = {cli['command']: cli['package'] for cli in CATALOGUES['v4.0.4']['clis']}

STUB = r'''
import json, os, pathlib, subprocess, sys
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
        sys.stdin.read()
        print(os.environ.get('FILTER_SELECTION', ''))
        sys.exit(int(os.environ.get('FILTER_RESULT', '0')))
    if args[0] == 'confirm': sys.exit(int(os.environ.get('CONFIRM_RESULT', '1')))
    print(' '.join(args))
elif name == 'sudo':
    if args[-1] == 'true': sys.exit(int(os.environ.get('SUDO_RESULT', '0')))
    sys.exit(subprocess.run(args).returncode)
elif name == 'pacman':
    if args[0] == '-Qi':
        sys.exit(0 if args[1] in os.environ.get('INSTALLED_PACKAGES', '').split() else 1)
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
                    'LC_ALL': 'C.UTF-8'}

    def run_bash(self, code, expected=0, **environment):
        result = subprocess.run(['bash', '-c', 'source "$1"\n' + code, 'test', str(SCRIPT)],
                                env={**self.env, **environment}, capture_output=True, text=True)
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
        current = CATALOGUES['quattro-10f1cbf']
        for name, content in current['desktops'].items():
            self.desktop(name, content)
        native = {name: self.desktop(name, content) for name, content in current['native_desktops'].items()}
        offered = set(self.run_bash('get_installed_webapps').splitlines())
        self.assertTrue(set(current['desktops']) <= offered)
        self.assertFalse(set(native) & offered)
        for name, path in native.items():
            with self.subTest(name=name):
                self.run_bash('remove_webapps ' + name, expected=1)
                self.assertEqual(path.read_text(), current['native_desktops'][name])
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
