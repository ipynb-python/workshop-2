#!/usr/bin/bash

# --- 1. HELP MENU ---
show_help() {
    echo "-------------------------------------------------------"
    echo "  GIT HELPER TOOL"
    echo "-------------------------------------------------------"
    echo "Usage: $0 [COMMAND] [ARGUMENT]"
    echo ""
    echo "Commands:"
    echo "  --commit [msg]  : 1. Saves all your work."
    echo "                    2. Pushes it to the server."
    echo "                    3. Provides a download link for your work."
    echo ""
    echo "  --rollback [n]  : 1. Checks if you have saved (--commit) first."
    echo "                    2. Moves your computer back [n] commits."
    echo ""
    echo "  --sync          : 1. SAVES your current messy work to a backup branch."
    echo "                    2. RESETS your computer to match the clean server version."
    echo "-------------------------------------------------------"
}

# --- 2. PRE-FLIGHT CHECKS ---
COMMAND="$1"
ARG="$2"

if [[ -z "$COMMAND" || "$COMMAND" == "--help" || "$COMMAND" == "-h" ]]; then
    show_help
    exit 0
fi

if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    echo "[ERROR] This folder is not a Git repository."
    exit 1
fi

if ! git remote get-url origin > /dev/null 2>&1; then
    echo "[ERROR] No remote server found."
    exit 1
fi

get_branch() {
    git rev-parse --abbrev-ref HEAD
}

# Function to generate web URLs from the git remote
print_github_links() {
    local branch=$(get_branch)
    local remote_url=$(git config --get remote.origin.url)
    local web_url=""

    # Convert SSH (git@github.com:user/repo.git) to HTTPS if needed
    if [[ "$remote_url" == git@* ]]; then
        # Replace first colon with slash
        web_url="${remote_url/:/\/}"
        # Replace git@ with https://
        web_url="${web_url/git@/https:\/\/}"
    else
        web_url="$remote_url"
    fi

    # Remove .git suffix if present
    web_url="${web_url%.git}"

    # Construct the standard GitHub ZIP download URL
    # Format: https://github.com/USER/REPO/archive/refs/heads/BRANCH.zip
    local zip_url="${web_url}/archive/refs/heads/${branch}.zip"

    echo "-------------------------------------------------------"
    echo "[LINKS]"
    echo "   View Repo:     $web_url/tree/$branch"
    echo "   Download Zip:  $zip_url"
    echo "-------------------------------------------------------"
}

# --- 3. MAIN LOGIC ---
case "$COMMAND" in

  # ---------------------------------------------------------
  # SAVE GAME (--commit)
  # ---------------------------------------------------------
  --commit)
    echo "[ACTION] Saving work..."
    
    if [[ -n $(git status --porcelain) ]]; then
        git add .
        MSG="${ARG:-Update $(date)}"
        if ! git commit -m "$MSG"; then
            echo "[ERROR] Failed to create commit."
            exit 1
        fi
        echo "[OK] Files committed."
    else
        echo "[INFO] No new files to commit."
    fi

    BRANCH=$(get_branch)
    echo "[ACTION] Pushing to server..."
    
    if ! git push origin "$BRANCH" --force; then
        echo "[ERROR] PUSH FAILED. Check internet connection."
        exit 1
    fi
    
    echo "-------------------------------------------------------"
    echo "[SUCCESS] SAVE COMPLETE."
    echo "   Your work is safe on the server."
    
    # Print the new links
    print_github_links
    ;;

  # ---------------------------------------------------------
  # GO BACK (--rollback)
  # ---------------------------------------------------------
  --rollback)
    if [[ -n $(git status --porcelain) ]]; then
        echo "[ERROR] BLOCK: You have unsaved file changes."
        echo "   You must run '$0 --commit' before you can rollback."
        exit 1
    fi

    echo "[ACTION] Verifying server status..."
    if ! git fetch origin; then
        echo "[ERROR] Could not connect to server."
        exit 1
    fi

    BRANCH=$(get_branch)
    LOCAL_HASH=$(git rev-parse HEAD)
    REMOTE_HASH=$(git rev-parse "origin/$BRANCH")

    if [ "$LOCAL_HASH" != "$REMOTE_HASH" ]; then
        AHEAD=$(git rev-list HEAD ^origin/$BRANCH --count)
        if [ "$AHEAD" -gt 0 ]; then
             echo "[ERROR] BLOCK: You have local commits that are not on the server."
             echo "   You must run '$0 --commit' to save them first."
             exit 1
        fi
    fi

    if [[ -z "$ARG" ]]; then
        COUNT=1
    else
        COUNT="$ARG"
    fi

    echo "[ACTION] Rolling back local computer by $COUNT commit(s)..."
    
    if ! git reset --hard "HEAD~$COUNT"; then
        echo "[ERROR] Rollback failed."
        exit 1
    fi
    
    echo "-------------------------------------------------------"
    echo "[SUCCESS] ROLLBACK COMPLETE (Local only)."
    echo "   Your files are now in the past."
    echo "-------------------------------------------------------"
    ;;

  # ---------------------------------------------------------
  # SAFE SYNC (Backup then Reset)
  # ---------------------------------------------------------
  --sync)
    echo "[ACTION] Checking status against server..."
    if ! git fetch origin; then
        echo "[ERROR] Connection failed. Cannot sync."
        exit 1
    fi

    BRANCH=$(get_branch)
    LOCAL_HASH=$(git rev-parse HEAD)
    REMOTE_HASH=$(git rev-parse "origin/$BRANCH")
    UNCOMMITTED_CHANGES=$(git status --porcelain)

    if [[ "$LOCAL_HASH" == "$REMOTE_HASH" && -z "$UNCOMMITTED_CHANGES" ]]; then
        echo "-------------------------------------------------------"
        echo "[INFO] SYNC NOT NEEDED."
        echo "   Your local files already match the server exactly."
        echo "-------------------------------------------------------"
        exit 0
    fi

    echo "-------------------------------------------------------"
    echo "[WARNING] STARTING SAFE SYNC"
    echo "   1. We will backup your current work to a new branch."
    echo "   2. We will reset your computer to match the clean server version."
    echo "-------------------------------------------------------"
    
    read -p "Do you want to proceed? (y/n): " CONFIRM
    if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
        echo "[INFO] Cancelled."
        exit 0
    fi

    if [[ -n "$UNCOMMITTED_CHANGES" ]]; then
        echo "[ACTION] Committing local changes for backup..."
        git add .
        git commit -m "Auto-save before sync $(date)" > /dev/null
    fi

    BACKUP_NAME="backup/sync-$(date +%s)"
    echo "[ACTION] Uploading backup to branch: '$BACKUP_NAME'..."
    
    if ! git push origin HEAD:refs/heads/"$BACKUP_NAME"; then
        echo "[ERROR] Backup failed. Stopping sync to protect your files."
        exit 1
    fi
    echo "[OK] Backup secure."

    echo "[ACTION] Resetting local computer to match 'origin/$BRANCH'..."
    if ! git reset --hard "origin/$BRANCH"; then
        echo "[ERROR] Reset failed."
        exit 1
    fi
    
    echo "-------------------------------------------------------"
    echo "[SUCCESS] SYNC COMPLETE."
    echo "   - Your computer is now clean (matches server)."
    echo "   - Your old messy work is saved on branch: $BACKUP_NAME"
    
    # We print links here too, so they can quickly verify the clean state
    print_github_links
    ;;

  *)
    echo "[ERROR] Unknown command: $COMMAND"
    show_help
    exit 1
    ;;
esac