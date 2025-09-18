# Omarchy Cleaner

> If Omarchy is the omakase of Linux distros, a curated feast of pre-installed apps and webapps, Omarchy Cleaner is your trusty pair of chopsticks to pluck away the unwanted wasabi for a perfectly tailored system. 🥢

An interactive shell script to remove unwanted default applications and webapps from Omarchy installations with a clean, visual interface.

![Screenshot of Omarchy Cleaner.](./screenshot.png)

## Quick Start

```bash
curl -fsSL https://raw.githubusercontent.com/maxart/omarchy-cleaner/main/omarchy-cleaner.sh | bash
```

## How It Works

The script scans your system for Omarchy's default packages and webapps, presents them in an interactive selection interface, and safely removes your choices. It can also clean up associated keyboard shortcuts and provides visual feedback on completion status.

## Customization

Edit the `DEFAULT_APPS` and `DEFAULT_WEBAPPS` arrays in the script to customize which items are offered for removal. The script includes comprehensive lists from Omarchy's default installation, with commonly unwanted applications enabled by default.



## Default Omarchy packages and webapps
You can find the default Omarchy package list [here](https://github.com/basecamp/omarchy/blob/master/install/omarchy-base.packages) and the default webapps [here](https://github.com/basecamp/omarchy/blob/master/install/packaging/webapps.sh).

## License

 Omarchy Cleaner is released under the [MIT License](https://opensource.org/licenses/MIT).