"""Extract a pinned upstream catalogue without executing upstream shell code.

Usage: python3 tests/fixtures/extract_catalogue.py OMARCHY_CHECKOUT REVISION
Historical snapshots before quattro-10f1cbf omitted native_desktops; compare
that field only when it was recorded. Python 3.11+ is needed for 4.5 TOML.
"""
import json
from pathlib import Path
import re
import shlex
import subprocess
import sys
import tomllib


def extract(repo, revision):
    def git(*args):
        return subprocess.check_output(['git', '-C', str(repo), *args], text=True)

    def read(path):
        return git('show', f'{revision}:{path}')

    files = git('ls-tree', '-r', '--name-only', revision).splitlines()
    base = [line.split('#', 1)[0].strip() for line in read('install/omarchy-base.packages').splitlines()]
    remover = read('bin/omarchy-remove-preinstalls').replace('\\\n', ' ')
    drop = re.search(r'^\s*omarchy-pkg-drop\s+([^\n]+)', remover, re.M)
    assert drop, 'No removable package list'
    clis = []
    for line in read('install/user/mise.sh').splitlines():
        if line.lstrip().startswith('#') or 'omarchy-mise-install ' not in line:
            continue
        args = shlex.split(line.split('omarchy-mise-install ', 1)[1], comments=True)
        clis.append({'package': args[0], 'command': args[1] if len(args) > 1 else args[0]})
    result = {'sha': git('rev-parse', revision + '^{commit}').strip(),
              'base': [line for line in base if line], 'drop': shlex.split(drop[1]),
              'clis': clis, 'desktops': {}, 'native_desktops': {}}
    for path in files:
        if path.startswith('applications/') and path.endswith('.desktop'):
            content = read(path)
            category = 'desktops' if re.search(r'^Exec=(omarchy-(launch-webapp|webapp-handler)|xdg-terminal-exec)', content, re.M) else 'native_desktops'
            result[category][Path(path).stem] = content
    if 'etc/mise/conf.d/omarchy-tools.toml' in files:
        tools = tomllib.loads(read('etc/mise/conf.d/omarchy-tools.toml'))['tools']
        # Aliases verified against mise v2026.11.1 registry bins. Other entries
        # use upstream lazy_bins or the identically named registry binary.
        aliases = {'antigravity-cli': 'agy', 'hey-cli': 'hey', 'oh-my-pi': 'omp'}
        result['lazy_clis'] = [{'package': key, 'command': value.get('lazy_bins', [aliases.get(key, key)])[0]}
                               for key, value in tools.items() if key not in ('node', 'uv')]
        result['runtimes'] = ['node', 'uv']
    return result


if __name__ == '__main__':
    print(json.dumps(extract(sys.argv[1], sys.argv[2]), indent=2, ensure_ascii=False))
