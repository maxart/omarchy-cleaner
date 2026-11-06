"""4.5 contracts: pinned upstream helper, disposable homes, stubbed reshim."""
import shutil
import subprocess
import os
import unittest

import test_cleaner as harness


class Compatibility450Tests(unittest.TestCase):
    setUp = harness.CleanerTests.setUp
    run_bash = harness.CleanerTests.run_bash
    calls = harness.CleanerTests.calls
    install_mise = harness.CleanerTests.install_mise

    def defaults(self):
        helper = self.bin / 'omarchy-mise-default-tools'
        shutil.copyfile(harness.FIXTURES / 'mise-default-tools-4.5.0.sh', helper)
        helper.chmod(0o755)
        tools = self.root / 'omarchy-tools.toml'
        shutil.copyfile(harness.FIXTURES / 'omarchy-tools-4.5.0.toml', tools)
        mise = self.bin / 'mise'
        mise.write_text('''#!/bin/bash
[[ "$*" == reshim && "$MISE_OFFLINE" == 1 ]] || exit 99
printf '["mise", "reshim"]\\n' >> "$CALL_LOG"
if [[ "$FAIL_RESHIM" == yes ]]; then exit 1; fi
if [[ "$FAIL_RESHIM" == once && ! -e "$CALL_LOG.failed" ]]; then
    touch "$CALL_LOG.failed"
    exit 1
fi
''')
        mise.chmod(0o755)
        return tools

    @property
    def miserc(self):
        return self.home / '.config/mise/miserc.toml'

    def write_miserc(self, content):
        self.miserc.parent.mkdir(parents=True, exist_ok=True)
        self.miserc.write_text(content)
        self.miserc.chmod(0o640)

    def test_fresh_layout_offers_explicit_group_with_complete_confirmation(self):
        self.defaults()
        self.packaged.unlink()
        offered = self.run_bash('get_installed_npm_clis').splitlines()
        self.assertEqual(offered, ['Omarchy default CLI tools (all)'])
        output = self.run_bash('main', FILTER_SELECTION='⬢ ' + offered[0], CONFIRM_RESULT='1')
        for cli in harness.CATALOGUES['v4.5.0']['lazy_clis']:
            self.assertIn('• ' + cli['command'] + ' — ', output)
        self.assertIn('• node', output)
        self.assertIn('• uv', output)
        self.assertIn('Individual lazy defaults cannot be removed separately', output)
        self.assertFalse(self.miserc.exists())
        self.assertFalse(self.calls('mise'))
        self.assertFalse(self.calls('sudo'))

    def test_group_opt_out_preserves_personal_config_data_and_custom_launchers(self):
        tools = self.defaults()
        self.write_miserc('# personal setting without trailing newline\nexperimental = true')
        original = self.miserc.read_bytes()
        sentinels = [self.home / p for p in ('.config/mise/config.toml',
                     '.local/share/mise/installs/codex/data', '.local/share/mise/shims/custom',
                     '.local/bin/codex', '.cache/mise/personal')]
        for p in sentinels:
            p.parent.mkdir(parents=True, exist_ok=True)
            p.write_text('keep')
        upstream = tools.read_bytes()
        self.run_bash('plan_mise_defaults "$MISE_DEFAULTS_ITEM" && remove_npm_clis "$MISE_DEFAULTS_ITEM"')
        self.assertEqual(self.miserc.read_bytes(), original + b'\n' +
                         f'ignored_config_paths = ["{tools}"]\n'.encode())
        backups = list(self.miserc.parent.glob('miserc.toml.backup.*'))
        self.assertEqual(len(backups), 1)
        self.assertEqual(backups[0].read_bytes(), original)
        self.assertEqual(self.miserc.stat().st_mode & 0o777, 0o640)
        self.assertEqual(tools.read_bytes(), upstream)
        self.assertTrue(all(p.read_text() == 'keep' for p in sentinels))
        self.assertEqual(self.run_bash('get_installed_npm_clis'), '')
        self.assertEqual(self.calls('mise'), [['mise', 'reshim']])
        self.assertFalse(self.calls('sudo'))

    def test_opt_out_failure_restores_exact_existing_or_absent_config(self):
        self.defaults()
        for content in (None, '# keep\nexperimental = true', ''):
            with self.subTest(content=content):
                self.miserc.unlink(missing_ok=True)
                if content is not None:
                    self.write_miserc(content)
                self.run_bash('plan_mise_defaults "$MISE_DEFAULTS_ITEM" && remove_npm_clis "$MISE_DEFAULTS_ITEM"',
                              expected=1, FAIL_RESHIM='once')
                if content is None:
                    self.assertFalse(self.miserc.exists())
                else:
                    self.assertEqual(self.miserc.read_text(), content)
                    self.assertEqual(self.miserc.stat().st_mode & 0o777, 0o640)
                self.assertIn('Omarchy default CLI tools (all)', self.run_bash('get_installed_npm_clis'))
                self.log.with_name(self.log.name + '.failed').unlink()
        self.assertEqual(len(self.calls('mise')), 6)

    def test_persistent_reshim_failure_reports_recovery_needed(self):
        self.defaults()
        output = self.run_bash('plan_mise_defaults "$MISE_DEFAULTS_ITEM" && remove_mise_defaults',
                               expected=1, FAIL_RESHIM='yes')
        self.assertIn('run mise reshim', output)
        self.assertFalse(self.miserc.exists())

    def test_conflicting_personal_ignore_list_is_preserved(self):
        self.defaults()
        content = 'ignored_config_paths = ["/some/personal/file"]\n'
        self.write_miserc(content)
        self.run_bash('plan_mise_defaults "$MISE_DEFAULTS_ITEM" && remove_mise_defaults', expected=1)
        self.assertEqual(self.miserc.read_text(), content)
        self.assertFalse(self.calls('mise'))
        self.assertFalse(list(self.miserc.parent.glob('*.backup.*')))

    def test_symlinked_miserc_or_parent_is_refused_before_mutation(self):
        self.defaults()
        target = self.root / 'personal.toml'
        target.write_text('keep')
        self.miserc.parent.mkdir(parents=True)
        self.miserc.symlink_to(target)
        self.run_bash('plan_mise_defaults "$MISE_DEFAULTS_ITEM"', expected=1)
        self.assertEqual(target.read_text(), 'keep')
        self.miserc.unlink()
        self.miserc.parent.rmdir()
        self.miserc.parent.symlink_to(self.root, target_is_directory=True)
        self.run_bash('plan_mise_defaults "$MISE_DEFAULTS_ITEM"', expected=1)
        self.assertFalse(self.calls('mise'))

    def test_plan_recheck_refuses_changed_configuration_or_default_list(self):
        tools = self.defaults()
        for change in ('printf "# changed\\n" >> "$OMARCHY_MISE_CONFIG_PATH"',
                       'mkdir -p "$HOME/.config/mise"; printf "# changed\\n" > "$HOME/.config/mise/miserc.toml"',
                       'printf "newtool = {version=\\"latest\\",lazy=true}\\n" >> "$OMARCHY_MISE_CONFIG_PATH"'):
            with self.subTest(change=change):
                self.run_bash('plan_mise_defaults "$MISE_DEFAULTS_ITEM"; ' + change + '; remove_mise_defaults', expected=1)
        self.assertFalse(self.calls('mise'))
        self.assertNotIn('ignored_config_paths', self.miserc.read_text())
        self.assertIn('newtool', tools.read_text())

    def test_unconfirmed_opt_out_is_refused(self):
        self.defaults()
        self.run_bash('remove_npm_clis "$MISE_DEFAULTS_ITEM"', expected=1)
        self.assertFalse(self.calls('mise'))
        self.assertFalse(self.miserc.exists())

    def test_hardlinked_config_is_not_edited_through_another_name(self):
        self.defaults()
        self.write_miserc('# keep')
        target = self.root / 'linked-config'
        os.link(self.miserc, target)
        self.run_bash('plan_mise_defaults "$MISE_DEFAULTS_ITEM"', expected=1)
        self.assertEqual(target.read_text(), '# keep')
        self.assertFalse(self.calls('mise'))

    def test_backup_failure_prevents_opt_out(self):
        self.defaults()
        self.write_miserc('# keep')
        cp = self.bin / 'cp'
        cp.write_text('#!/bin/bash\nexit 1\n')
        cp.chmod(0o755)
        self.run_bash('plan_mise_defaults "$MISE_DEFAULTS_ITEM" && remove_mise_defaults', expected=1)
        self.assertEqual(self.miserc.read_text(), '# keep')
        self.assertFalse(self.calls('mise'))
        self.assertFalse(list(self.miserc.parent.glob('*.tmp.*')))

    def test_future_default_is_included_in_confirmation(self):
        tools = self.defaults()
        with tools.open('a') as f:
            f.write('future-tool = {version="latest", lazy=true}\n')
        output = self.run_bash('plan_mise_defaults "$MISE_DEFAULTS_ITEM" && print_mise_default_tools')
        self.assertIn('• future-tool', output)
        self.assertIn('• node — JavaScript runtime', output)
        self.assertIn('• uv — Python package and project manager', output)

    def test_partial_legacy_selection_never_disables_lazy_defaults(self):
        self.defaults()
        self.packaged.unlink()
        selected = self.install_mise('npm:@moonshot-ai/kimi-code', 'kimi')
        kept = self.install_mise('codex', 'codex')
        original = kept.read_bytes()
        self.run_bash('main', FILTER_SELECTION='⬢ kimi', CONFIRM_RESULT='0')
        self.assertFalse(selected.exists())
        self.assertEqual(kept.read_bytes(), original)
        self.assertFalse(self.miserc.exists())
        self.assertFalse(self.calls('mise'))
        self.assertIn('Omarchy default CLI tools (all)', self.run_bash('get_installed_npm_clis'))

    def test_v450_tool_mapping_and_legacy_templates(self):
        for cli in harness.CATALOGUES['v4.5.0']['lazy_clis']:
            with self.subTest(cli=cli):
                self.assertIn(cli['package'], self.run_bash('cli_packages_for "$CLI"', CLI=cli['command']).splitlines())
                self.install_mise(cli['package'], cli['command'])
                self.run_bash('is_npm_cli_installed "$CLI"', CLI=cli['command'])
                subprocess.run(['bash', str(harness.FIXTURES / 'mise-install-4.5.0.sh'),
                                cli['package'], cli['command']], env=self.env, check=True)
                self.run_bash('is_npm_cli_installed "$CLI"', CLI=cli['command'])
        self.assertFalse({'node', 'uv'} & set(self.run_bash('get_installed_npm_clis').splitlines()))

    def test_literal_calculator_bindings_and_personal_override(self):
        shutil.copyfile(harness.FIXTURES / 'applications-4.5.0.lua', self.packaged)
        personal = 'o.bind("SUPER + SHIFT + Q", "Personal", "my-calculator")\n'
        literal = 'o.bind("SUPER + C", nil, "omacalc") -- calculator\n'
        self.bindings.write_text(personal + literal)
        original = self.packaged.read_bytes()
        self.assertEqual(self.run_bash('find_packaged_unbind_keys omacalc').splitlines(),
                         ['SUPER + SHIFT + Q', 'XF86Calculator'])
        self.assertEqual(self.run_bash('find_app_bindings omacalc'), literal)
        self.run_bash('cleanup_bindings omacalc')
        self.assertEqual(self.bindings.read_text(),
                         '-- Omarchy Cleaner: disable removed apps before personal overrides.\n'
                         'hl.unbind("SUPER + SHIFT + Q")\nhl.unbind("XF86Calculator")\n\n' + personal)
        self.assertEqual(self.packaged.read_bytes(), original)
        self.assertEqual(self.run_bash('find_packaged_unbind_keys foot'), '')
        self.assertEqual(self.run_bash('find_packaged_unbind_keys omacalc'), '')

    def test_computed_escaped_and_multiline_commands_are_preserved(self):
        lines = [
            'o.bind("SUPER + A", "Calculator", "omacalc" .. suffix)',
            'o.bind("SUPER + B", "Calculator", "omacalc", extra)',
            'o.bind("SUPER + C", "Calculator", "omacalc\\ncustom")',
            'o.bind("SUPER + D", "Calculator", get_command("omacalc"))',
            'o.bind("SUPER + RETURN", "Terminal", o.launch_terminal())',
            'o.bind("SUPER + F", "Calculator",\n "omacalc")',
            '-- o.bind("SUPER + G", "Calculator", "omacalc")',
            'o.bind("SUPER + H", "Calculator", "omacalc-other")',
        ]
        self.bindings.write_text('\n'.join(lines) + '\n')
        self.assertEqual(self.run_bash('find_app_bindings omacalc'), '')
        self.run_bash('cleanup_bindings omacalc')
        self.assertEqual(self.bindings.read_text(), '\n'.join(lines) + '\n')
