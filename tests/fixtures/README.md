These fixtures are copied from [omacom/omarchy](https://github.com/omacom/omarchy) for offline regression checks. They are data; the only executable fixtures are the reviewed wrapper generators, which write into a temporary test home without running the wrappers.

- `applications-4.0.0.lua` and `mise-install-4.0.0.sh`: v4.0.0, commit `f0020448ca87329199de7cb12f2015ebc4a3e5e7`, from `default/hypr/bindings/applications.lua` and `bin/omarchy-mise-install`.
- `applications.lua`: v4.0.2, commit `346e69e1cec6c4e8924531874af6ba010a1bc99e`, from the same path. Unchanged in v4.0.4.
- `mise-install.sh`: v4.0.4, commit `c668141e9c42b13c80c9ca4ea108e11708c5e8a5`, from `bin/omarchy-mise-install`. It writes the same wrappers as v4.0.2 for package names without shell characters.
- `npx-install.sh`: v3.8.4, commit `8fcc9d6048af4cb0e3af8512c78049857a3b53dd`, from `bin/omarchy-npx-install`.
- `catalogues.json`: extracted package lists, removable package lists, CLI installer arguments, and webapp/TUI desktop contents from v4.0.2, v4.0.4 (`c668141e9c42b13c80c9ca4ea108e11708c5e8a5`) and Quattro commit `959e49dc52a60d35b299d4e13372bc74dd0797ae`. The source paths are `install/omarchy-base.packages`, `bin/omarchy-remove-preinstalls`, `install/user/mise.sh`, and `applications/*.desktop`.

The upstream MIT license is retained in `OMARCHY-LICENSE`. Refresh fixtures deliberately when comparing a new upstream release; tests should detect drift rather than silently read changing network content.
