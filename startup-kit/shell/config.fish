if status is-interactive
# Commands to run in interactive sessions can go here
end
fish_add_path ~/.local/bin
alias c="claude"

# Starship prompt (icons, git status, node version)
starship init fish | source

# Zoxide (smart cd - use 'z' to jump to frequent dirs)
zoxide init fish | source

# ASCII art is rendered inside fish_greeting (after the quote)
# so the motivational quote stays visible at the top of the terminal

# pnpm
set -gx PNPM_HOME "/Users/vibeyang/Library/pnpm"
if not string match -q -- $PNPM_HOME $PATH
  set -gx PATH "$PNPM_HOME" $PATH
end
# pnpm end
