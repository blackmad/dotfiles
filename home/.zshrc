# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

export PATH=/opt/homebrew/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="robbyrussell"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
zstyle ':omz:update' mode auto # update automatically without asking

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.

FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"

export ZPLUG_HOME=/opt/homebrew/opt/zplug
source $ZPLUG_HOME/init.zsh
zplug "grigorii-zander/zsh-npm-scripts-autocomplete"
zplug "g-plane/zsh-yarn-autocompletions", hook-build:"./zplug.zsh", defer:2
zplug "MichaelAquilina/zsh-auto-notify"


plugins=(git z)

# alias cd=z

source $ZSH/oh-my-zsh.sh

export PATH=$PATH:~/.bin:~/.yarn/bin
export PATH="/opt/homebrew/opt/icu4c/bin:/opt/homebrew/opt/icu4c/sbin:$PATH"
export PKG_CONFIG_PATH="$PKG_CONFIG_PATH:/opt/homebrew/opt/icu4c/lib/pkgconfig"

# Make `cd` from a vscode terminal go to the workspace root
# Assume the following is in vscode settings:
# "terminal.integrated.env.linux":  {"VSCODE_WS": "${workspaceFolder}"},
# "terminal.integrated.env.windows":{"VSCODE_WS": "${workspaceFolder}"},
# When in filemode / not in a workspace, `VSCODE_WS` is set to the literal `${workspaceFolder}` so we check and ignore that
if [[ -v VSCODE_WS ]] && [[ "$VSCODE_WS" != '${workspaceFolder}' ]]; then
    alias cd="HOME=\"${VSCODE_WS}\" cd"
fi

DROPBOX_SECRETS_FILE=~/Dropbox/Credentials/personal-secrets.zsh
if [[ -f $DROPBOX_SECRETS_FILE ]]; then
    source $DROPBOX_SECRETS_FILE
fi

[ -s "/Users/blackmad/.scm_breeze/scm_breeze.sh" ] && source "/Users/blackmad/.scm_breeze/scm_breeze.sh"

# Created by `pipx` on 2024-03-17 09:35:57
export PATH="$PATH:/Users/blackmad/.local/bin"

export PYTHON=/opt/homebrew/bin/python3

### Automatically installed by `filament install`

function filament {
    # save the current directory so we can get back to it
    old_pwd=$(pwd)

    # clean up even if the command is interrupted
    trap "cd $old_pwd; VIRTUAL_ENV=$OLD_VIRTUAL_ENV" INT

    # clear out virtual env otherwise running poetry will be confused
    OLD_VIRTUAL_ENV=$VIRTUAL_ENV
    unset VIRTUAL_ENV

    cd /Users/blackmad/Filament/devscripts/cli

    poetry run python -m cli.main $@

    # clean up
    VIRTUAL_ENV=$OLD_VIRTUAL_ENV
    cd $old_pwd

    # get rid of the trap handler
    trap - INT
}

export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"                                       # This loads nvm
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" # This loads nvm bash_completion

if [ -f $HOME/.cargo/env ]; then
    . "$HOME/.cargo/env"   
fi
export OP_ACCOUNT="filamentinc"

export PATH=$PATH:/opt/homebrew/bin/

eval "$(brew shellenv)"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
