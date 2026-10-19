<#
.SYNOPSIS
    Colours your PowerShell terminal based on the current git branch/worktree.

.DESCRIPTION
    Each branch gets a consistent themed background (Catppuccin, Everforest, Tokyo Night, etc.)
    so you can instantly tell which worktree you're in. Also sets the tab title to the branch name.

    Designed to work alongside oh-my-posh. Add to your $PROFILE to activate on session start
    and auto-update whenever you change directory into a different worktree.

.USAGE
    # Dot-source this file from your $PROFILE:
    . "C:\path\to\Set-WorktreeColour.ps1"

    # Or call manually to refresh at any time:
    wt-colour

.NOTES
    Requires Windows Terminal for background/foreground colour support (OSC 10/11).
    Works on PowerShell 5.x and 7+.
#>

function Show-WorktreeColour {
    $worktreeRoot = git rev-parse --show-toplevel 2>$null
    if (-not $worktreeRoot) { return }

    $branch = git rev-parse --abbrev-ref HEAD 2>$null
    if (-not $branch) { $branch = Split-Path $worktreeRoot -Leaf }

    # Themed palette — each entry is a { bg; fg } pair matched to a popular dark/light theme
    # bg = background RGB, fg = foreground RGB chosen for readability on that background
    $palette = @(
        @{ bg = @( 30,  30,  46); fg = @(205, 214, 244) },   # Catppuccin Mocha      #1E1E2E / #CDD6F4
        @{ bg = @( 36,  39,  58); fg = @(202, 211, 245) },   # Catppuccin Macchiato  #24273A / #CAD3F5
        @{ bg = @( 45,  53,  59); fg = @(211, 198, 170) },   # Everforest            #2D353B / #D3C6AA
        @{ bg = @(239, 241, 245); fg = @( 76,  79, 105) },   # Catppuccin Latte      #EFF1F5 / #4C4F69
        @{ bg = @( 48,  52,  70); fg = @(198, 208, 245) },   # Catppuccin Frappe     #303446 / #C6D0F5
        @{ bg = @( 26,  27,  38); fg = @(169, 177, 214) },   # Tokyo Night           #1A1B26 / #A9B1D6
        @{ bg = @( 25,  23,  36); fg = @(224, 222, 244) },   # Rose Pine             #191724 / #E0DEF4
        @{ bg = @( 46,  52,  64); fg = @(216, 222, 233) }    # Nord                  #2E3440 / #D8DEE9
    )

    $index         = [System.Math]::Abs($branch.GetHashCode()) % $palette.Length
    $entry         = $palette[$index]
    $r,  $g,  $b  = $entry.bg
    $fr, $fg_, $fb = $entry.fg

    # Use [char]27 rather than `e — PS 5.x doesn't support the `e escape literal
    $esc = [char]27
    $bg  = "${esc}[48;2;${r};${g};${b}m"
    $fg  = "${esc}[38;2;${fr};${fg_};${fb}m"
    $rst = "${esc}[0m"

    Write-Host "${bg}${fg}  $branch  ${rst}"

    # Set tab title to the branch name — persists the whole session
    $Host.UI.RawUI.WindowTitle = $branch

    # OSC 11 sets pane background, OSC 10 sets default text colour (Windows Terminal)
    # [Console]::Write bypasses PowerShell's formatting pipeline so the sequences reach the terminal raw
    $bgHex = "#{0:X2}{1:X2}{2:X2}" -f $r,  $g,  $b
    $fgHex = "#{0:X2}{1:X2}{2:X2}" -f $fr, $fg_, $fb
    $st    = [char]7   # BEL terminator — wider compat than ESC\
    [Console]::Write("${esc}]11;${bgHex}${st}${esc}]10;${fgHex}${st}")
}

Set-Alias wt-colour Show-WorktreeColour

# -----------------------------------------------------------------------------------
# Auto-update on directory change — wraps oh-my-posh's prompt if present, otherwise
# wraps whatever prompt function is currently defined.
# -----------------------------------------------------------------------------------
$script:_existingPrompt   = (Get-Command prompt -CommandType Function -ErrorAction SilentlyContinue)?.ScriptBlock
$script:_lastPwd          = $null
$script:_lastWorktreeRoot = $null
$script:_lastBranch       = $null

function prompt {
    # Only call git when the directory changes — avoids slowing every prompt
    if ($PWD.Path -ne $script:_lastPwd) {
        $script:_lastPwd = $PWD.Path
        $newRoot   = git rev-parse --show-toplevel 2>$null
        $newBranch = git rev-parse --abbrev-ref HEAD 2>$null
        if ($newRoot -ne $script:_lastWorktreeRoot -or $newBranch -ne $script:_lastBranch) {
            $script:_lastWorktreeRoot = $newRoot
            $script:_lastBranch       = $newBranch
            Show-WorktreeColour
        }
    }
    if ($script:_existingPrompt) { & $script:_existingPrompt } else { "PS $($PWD.Path)> " }
}

# Run once immediately on load
Show-WorktreeColour
