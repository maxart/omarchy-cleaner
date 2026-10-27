"""Real selector checks; package commands and HOME remain isolated fixtures."""
import fcntl
import os
from pathlib import Path
import pty
import select
import shutil
import signal
import struct
import subprocess
import termios
import time
import unittest

import test_cleaner as fixtures


GUM = os.environ.get('CLEANER_TEST_GUM') or shutil.which('gum')


@unittest.skipUnless(GUM, 'install gum or set CLEANER_TEST_GUM for real selector checks')
class GumTests(unittest.TestCase):
    def setUp(self):
        self.fixture = fixtures.CleanerTests()
        self.fixture.setUp()
        self.addCleanup(self.fixture.doCleanups)
        self.fixture.desktop('Google Photos')
        stub = self.fixture.bin / 'gum'
        stub.unlink()
        stub.symlink_to(Path(GUM).resolve())

    def select_item(self, query, inherited_selection=''):
        master, slave = pty.openpty()
        self.addCleanup(os.close, master)
        fcntl.ioctl(slave, termios.TIOCSWINSZ, struct.pack('HHHH', 50, 80, 0, 0))

        def terminal_session():
            os.setsid()
            fcntl.ioctl(0, termios.TIOCSCTTY, 0)

        code = ('source "$1"; enhanced_select_packages docker docker-buildx opencode '
                '--webapps-- Docker "Google Photos" --npmclis-- codex opencode; '
                'printf "RESULT<%s>|<%s>|<%s>\\n" '
                '"$SELECTED_PACKAGES" "$SELECTED_WEBAPPS" "$SELECTED_NPMCLIS"')
        child = subprocess.Popen(['bash', '-c', code, 'test', str(fixtures.SCRIPT)],
                                 stdin=slave, stdout=slave, stderr=slave,
                                 preexec_fn=terminal_session,
                                 env={**self.fixture.env, 'TERM': 'xterm-256color',
                                      'GUM_FILTER_SELECTED': inherited_selection})
        os.close(slave)

        def cleanup():
            if child.poll() is None:
                os.killpg(child.pid, signal.SIGKILL)
            child.wait()

        self.addCleanup(cleanup)
        output = b''

        def read_until(needle, timeout=10):
            nonlocal output
            deadline = time.monotonic() + timeout
            while needle not in output and time.monotonic() < deadline:
                if select.select([master], [], [], 0.1)[0]:
                    try:
                        chunk = os.read(master, 65536)
                    except OSError:
                        break
                    if not chunk:
                        break
                    output += chunk
            self.assertIn(needle, output, output.decode(errors='replace'))

        read_until(b'Select items to remove:')
        os.write(master, query.encode())
        # Let gum finish its asynchronous fuzzy scoring before selecting the
        # focused row. This exercises ranking, unlike the isolated gum stub.
        time.sleep(0.5)
        os.write(master, b'\t')
        time.sleep(0.2)
        os.write(master, b'\r')
        read_until(b'RESULT<')
        self.assertEqual(child.wait(timeout=5), 0)
        self.assertFalse(self.fixture.calls('sudo'))
        self.assertFalse(self.fixture.calls('pacman'))
        return output.decode(errors='replace')

    def test_exact_docker_name_is_focused_without_inherited_preselection(self):
        output = self.select_item('📦 docker', inherited_selection='*')
        self.assertIn('RESULT<docker>|<>|<>', output)

    def test_space_name_and_cli_category_remain_distinct(self):
        output = self.select_item('🌐 Google Photos')
        self.assertIn('RESULT<>|<Google Photos>|<>', output)

    def test_cli_name_does_not_select_same_named_package(self):
        output = self.select_item('⬢ opencode')
        self.assertIn('RESULT<>|<>|<opencode>', output)
