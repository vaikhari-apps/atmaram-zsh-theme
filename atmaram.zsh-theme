# atmaram.zsh-theme
# Minimal zsh theme inspired by robbyrussell with git status color coding.
#
# Git branch name changes color based on working tree state:
#   Green  — clean working tree
#   Amber  — staged changes (ready to commit)
#   Red    — unstaged or untracked changes
#
# Additional indicators (inside the branch parentheses):
#   ↑N  — N commits ahead of remote   (cyan)
#   ↓N  — N commits behind remote     (cyan)
#   ⚑   — stashed changes exist       (magenta)
#
# Customization (set in .zshrc BEFORE "source $ZSH/oh-my-zsh.sh"):
#
#   ATMARAM_PROMPT_CHAR        — prompt arrow character  (default: ➜)
#
#   Git branch colors use 256-color spectrum codes (000–255).
#   Run  spectrum_ls  in your terminal to browse all available colors.
#
#   ATMARAM_GIT_COLOR_CLEAN    — branch color when clean       (default: 034  green)
#   ATMARAM_GIT_COLOR_STAGED   — branch color when staged only (default: 214  amber)
#   ATMARAM_GIT_COLOR_UNSTAGED — branch color when unstaged    (default: 196  red)
#
# Requirements: oh-my-zsh

# Configurable prompt character
ATMARAM_PROMPT_CHAR="${ATMARAM_PROMPT_CHAR:-➜}"

# Git branch colors — spectrum 256 codes (run `spectrum_ls` to browse)
ATMARAM_GIT_COLOR_CLEAN="${ATMARAM_GIT_COLOR_CLEAN:-034}"      # green
ATMARAM_GIT_COLOR_STAGED="${ATMARAM_GIT_COLOR_STAGED:-214}"    # amber
ATMARAM_GIT_COLOR_UNSTAGED="${ATMARAM_GIT_COLOR_UNSTAGED:-196}" # red 196

function _atmaram_git_prompt() {
  # Only proceed inside a git repository
  git rev-parse --git-dir &>/dev/null || return

  # Current branch name; fall back to detached HEAD short SHA
  local branch=$(git_current_branch)
  if [[ -z "$branch" ]]; then
    local sha
    sha=$(command git rev-parse --short HEAD 2>/dev/null) || return
    branch="HEAD:${sha}"
  fi

  # -------------------------------------------------------------------
  # Branch color — determined by working tree state
  # -------------------------------------------------------------------
  # git status --porcelain format: XY filename
  #   X = index (staged) status     Y = working tree (unstaged) status
  #   '??' = untracked file
  #
  # Priority: unstaged/untracked > staged only > clean
  # -------------------------------------------------------------------
  local git_status
  git_status=$(command git status --porcelain 2>/dev/null)

  local color_code
  if [[ -z "$git_status" ]]; then
    color_code="$ATMARAM_GIT_COLOR_CLEAN"       # Nothing to commit
  elif echo "$git_status" | grep -qE '^(.[^ ?]|\?\?)'; then
    color_code="$ATMARAM_GIT_COLOR_UNSTAGED"    # Unstaged or untracked changes
  else
    color_code="$ATMARAM_GIT_COLOR_STAGED"      # Staged changes only
  fi

  # -------------------------------------------------------------------
  # Remote ahead / behind indicators
  # -------------------------------------------------------------------
  local remote_info=""
  local ahead behind
  ahead=$(command git rev-list --count @{upstream}..HEAD 2>/dev/null)
  behind=$(command git rev-list --count HEAD..@{upstream} 2>/dev/null)
  [[ -n "$ahead"  && "$ahead"  != "0" ]] && remote_info+="%{$FG[045]%} ↑${ahead}"
  [[ -n "$behind" && "$behind" != "0" ]] && remote_info+="%{$FG[045]%} ↓${behind}"

  # -------------------------------------------------------------------
  # Stash indicator
  # -------------------------------------------------------------------
  local stash_info=""
  command git stash list 2>/dev/null | grep -q . && stash_info="%{$FG[133]%} ⚑"

  # Assemble: (branch ↑N ↓N ⚑)
  # $FX[bold] + $FG[code] for bold 256-color branch name
  echo "%{$fg_bold[blue]%}(%{$FX[bold]%}%{$FG[$color_code]%}${branch}%{$reset_color%}${remote_info}${stash_info}%{$fg_bold[blue]%})%{$reset_color%} "
}

PROMPT="%(?:%{$fg_bold[green]%}%1{${ATMARAM_PROMPT_CHAR}%} :%{$fg_bold[red]%}%1{${ATMARAM_PROMPT_CHAR}%} ) %{$fg[cyan]%}%c%{$reset_color%}"
PROMPT+=' $(_atmaram_git_prompt)'
