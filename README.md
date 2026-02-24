# gcloud-switch

Per-terminal Google Cloud configuration switching for zsh. Switch between multiple gcloud configurations in different terminal sessions without global configuration changes.

## Features

- **Per-terminal isolation**: Each terminal can use a different gcloud configuration simultaneously
- **Session-based**: Configuration persists only in the current terminal
- **Automatic cleanup**: Session variables cleaned up automatically on terminal exit
- **ADC management**: Separate Application Default Credentials for each configuration
- **Zero interference**: Uses wrapper script to inject configuration transparently

## Installation

### With zinit

Add to your `~/.zshrc`:

```zsh
zinit light g-eorge/gcloud-switch
```

Then run the installation script:

```bash
~/.local/share/zinit/plugins/g-eorge---gcloud-switch/bin/install.sh
```

### With antidote

Add to your `~/.zsh_plugins.txt`:

```
g-eorge/gcloud-switch
```

Then run:

```bash
antidote load
~/.cache/antidote/https-COLON--SLASH--SLASH-github.com-SLASH-georgeagnelli-SLASH-gcloud-switch/bin/install.sh
```

### With oh-my-zsh

```bash
git clone https://github.com/g-eorge/gcloud-switch.git \
  ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/gcloud-switch
```

Add to plugins array in `~/.zshrc`:

```zsh
plugins=(... gcloud-switch)
```

Run installation script:

```bash
${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/gcloud-switch/bin/install.sh
```

### Manual installation

```bash
git clone https://github.com/g-eorge/gcloud-switch.git \
  ~/.local/share/zsh-plugins/gcloud-switch
```

Add to your `~/.zshrc`:

```zsh
source ~/.local/share/zsh-plugins/gcloud-switch/gcloud-switch.plugin.zsh
```

Run installation script:

```bash
~/.local/share/zsh-plugins/gcloud-switch/bin/install.sh
```

## Usage

### First-time setup for a configuration

Before switching, set up Application Default Credentials (ADC) for each configuration. This requires browser authentication (one-time only):

```bash
gcloud-setup-adc <config-name>
```

This creates a configuration-specific ADC file at `~/.config/gcloud/adc-<config-name>.json`.

### Extra API scopes

By default, ADC credentials use the `cloud-platform` scope. If you need access to additional Google APIs (e.g., YouTube, Google Drive), pass extra scopes as positional arguments after the config name:

```bash
# Default cloud-platform scope only
gcloud-setup-adc myconfig

# Add YouTube read-only access
gcloud-setup-adc myconfig youtube.readonly

# Add multiple scopes
gcloud-setup-adc myconfig drive.readonly spreadsheets pubsub
```

Short names like `youtube.readonly` are expanded automatically. You can also pass full URLs:

```bash
gcloud-setup-adc myconfig https://www.googleapis.com/auth/calendar.readonly
```

Run `gcloud-setup-adc` with no arguments to see all available short scope names.

### Switching configurations

```bash
# Switch to a configuration (terminal-local only)
gcloud-switch <config-name>

# List available configurations
gcloud-switch
```

### Quick aliases

You can define custom aliases in the plugin file or your `~/.zshrc`:

```zsh
alias gcloud-prod='gcloud-switch production'
alias gcloud-dev='gcloud-switch development'
alias gcloud-staging='gcloud-switch staging'
```

### Cleanup

Remove stale session variables from dead processes:

```bash
gcloud-cleanup
```

## How it works

### Session isolation

Each terminal session gets a unique session ID. When you switch configurations:

1. Session-specific environment variables are set (`GCLOUD_CONFIG_<session-id>`, `GCLOUD_ADC_<session-id>`)
2. `GOOGLE_APPLICATION_CREDENTIALS` is exported for the current session
3. The wrapper script detects these variables and injects them into gcloud commands

### Wrapper script

The installation script places a wrapper at `~/.local/bin/gcloud` that intercepts all gcloud commands. The wrapper:

1. Looks for session-specific configuration variables
2. If found, injects `CLOUDSDK_ACTIVE_CONFIG_NAME` and `GOOGLE_APPLICATION_CREDENTIALS`
3. Calls the real gcloud CLI at `/usr/bin/gcloud`
4. If not found, calls gcloud with default behaviour

This works transparently with any tool that calls gcloud (Terraform, SDKs, etc.).

### Automatic cleanup

When a terminal session ends, the `EXIT` trap automatically removes session variables to prevent pollution.

## Architecture

```
~/.local/share/zsh-plugins/gcloud-switch/
├── gcloud-switch.plugin.zsh     # Entry point, sources all libraries
├── bin/
│   ├── gcloud                   # Wrapper script (installed to ~/.local/bin/)
│   └── install.sh               # Installation helper
├── lib/
│   ├── session.zsh              # Session ID and variable management
│   ├── core.zsh                 # gcloud-switch function
│   ├── adc.zsh                  # gcloud-setup-adc function
│   └── cleanup.zsh              # Cleanup utilities
└── completions/
    └── _gcloud-switch           # Tab completion
```

## Troubleshooting

### Wrapper script not found

Ensure `~/.local/bin` is in your `PATH` before other gcloud installations:

```zsh
export PATH="$HOME/.local/bin:$PATH"
```

Verify the wrapper is prioritised:

```bash
which gcloud
# Should show: /home/user/.local/bin/gcloud
```

### ADC file missing

If you get "ADC file missing" error:

```bash
gcloud-setup-adc <config-name>
```

This sets up Application Default Credentials for the configuration.

### Session isolation not working

Check that:

1. The wrapper script is installed: `ls -l ~/.local/bin/gcloud`
2. The wrapper is first in PATH: `which gcloud`
3. Session ID is set: `echo $GCLOUD_SESSION_ID`

### Configuration not switching

Verify session variables are set:

```bash
env | grep GCLOUD_CONFIG_
```

You should see variables like `GCLOUD_CONFIG_gcloud_<timestamp>_<pid>=<config-name>`.

## Plugin manager compatibility

| Plugin Manager | Compatible | Installation Method |
|----------------|------------|---------------------|
| zinit          | ✅ Yes     | `zinit light g-eorge/gcloud-switch` |
| antidote       | ✅ Yes     | Add to `~/.zsh_plugins.txt` |
| oh-my-zsh      | ✅ Yes     | Clone to `$ZSH_CUSTOM/plugins/` |
| zplug          | ✅ Yes     | `zplug "g-eorge/gcloud-switch"` |
| Manual         | ✅ Yes     | Source plugin file directly |

## Requirements

- zsh 5.0 or later
- Google Cloud SDK installed at `/usr/bin/gcloud`
- `~/.local/bin` in PATH

## Development

### Running tests

```bash
make test
```

### Linting

```bash
make lint
```

### Running all checks

```bash
make check
```

## Licence

MIT

## Contributing

Contributions welcome! Please ensure tests pass and ShellCheck validates cleanly.

```bash
make check
```
