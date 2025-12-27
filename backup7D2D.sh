#!/bin/bash

################################################################################
# 7D2D Backup & Restore Script (Linux Professional Edition)
# Version: 1.0.0
# Author: fedoraBee
# Source: https://github.com/fedoraBee/backup7D2D
#
# Description:
#   A robust backup utility for 7 Days to Die on Linux.
#   - Defaults to .tar.gz (native Linux compression)
#   - Supports .zip via command line or menu
#   - Includes a PreRestore safety snapshot
#   - Full color-coded interactive CLI
################################################################################

# --- Configuration ---
# Standard paths for Steam on Linux (Fedora/Ubuntu/etc)
SAVE_ROOT="$HOME/.local/share/7DaysToDie/Saves"
DEFAULT_SAVE_NAME="Votute County"
SAVE_GAME_FOLDER="$SAVE_ROOT/$DEFAULT_SAVE_NAME"
BACKUP_PATH="$HOME/Documents/7d2dBackups"

# Formatting Colors
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Tooling Check
TAR_BIN=$(command -v tar)
ZIP_BIN=$(command -v zip)
UNZIP_BIN=$(command -v unzip)

# Default State
FORMAT="tar.gz"
DEFAULT_PREFIX=$(echo "$DEFAULT_SAVE_NAME" | tr ' ' '_')
ALL_SAVES_PREFIX="ALLSAVES"

# --- Initialization ---
[[ ! -d "$BACKUP_PATH" ]] && mkdir -p "$BACKUP_PATH"

# --- UI Functions ---

usage() {
    echo -e "${CYAN}Usage: $0 [OPTIONS]${NC}"
    echo -e "  -h, --help       Show this help message"
    echo -e "  -b, --backup     Run in non-interactive backup mode"
    echo -e "  -t, --type TYPE  Backup type: 'Default' or 'All' (requires -b)"
    echo -e "  -f, --format FMT Format: 'tar.gz' or 'zip'"
    echo -e "  -o, --output DIR Output backup path (default: $BACKUP_PATH)"
    echo -e "  -s, --save-path DIR Save root path (default: $SAVE_ROOT)"
    echo -e "  -n, --name NAME  Default save name (default: $DEFAULT_SAVE_NAME)"
    echo ""
}

print_llama() {
    echo -e "${MAGENTA}            __--_--_-_"
    echo -e "           ( I wish I  )"
    echo -e "          ( were a real )"
    echo -e "          (    llama   )"
    echo -e "           ( in Peru! )"
    echo -e "          o (__--_--_)"
    echo -e "       , o${NC}"
    echo -e "${GREEN}      ~)"
    echo -e "       (_---;"
    echo -e "          /|~|\\"
    echo -e "       /  /  /  |${NC}"
}

print_header() {
    clear
    print_llama
    echo -e "${CYAN}===================================================="
    echo -e "|  7D2D Powershell Backup Script (Linux Port)      |"
    echo -e "|  Revision: 1.2                                   |"
    echo -e "====================================================${NC}"
    echo -e " Current Format: ${YELLOW}$FORMAT${NC}"
    echo ""
}

# --- Core Logic ---

backup_folder() {
    local target_folder="$1"
    local type="$2"
    local prefix=""
    
    case $type in
        "Default")    prefix="$DEFAULT_PREFIX" ;;
        "All")        prefix="$ALL_SAVES_PREFIX" ;;
        "PreRestore") prefix="${DEFAULT_PREFIX}_PreRestore" ;;
    esac
    
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local extension="$FORMAT"
    local dest_file="$BACKUP_PATH/${prefix}_${timestamp}.$extension"
    
    echo -e "${YELLOW}Starting backup...${NC}"
    
    if [[ "$FORMAT" == "zip" ]]; then
        if [[ -z "$ZIP_BIN" ]]; then echo -e "${RED}Error: 'zip' utility not found.${NC}"; return; fi
        (cd "$(dirname "$target_folder")" && "$ZIP_BIN" -rq "$dest_file" "$(basename "$target_folder")")
    else
        # Standard tar.gz creation
        "$TAR_BIN" -czf "$dest_file" -C "$(dirname "$target_folder")" "$(basename "$target_folder")"
    fi
    
    if [[ -f "$dest_file" ]]; then
        echo -e "${GREEN}Backup Successful: $dest_file${NC}"
    else
        echo -e "${RED}Backup Failed!${NC}"
    fi
}

restore_folder() {
    local restore_path="$1"
    local archive_file="$2"
    
    # Safety Snapshot
    echo -e "${YELLOW}Creating safety pre-restore backup...${NC}"
    backup_folder "$restore_path" "PreRestore"
    
    echo -e "${YELLOW}Restoring files...${NC}"
    if [[ "$archive_file" == *.zip ]]; then
        "$UNZIP_BIN" -o "$archive_file" -d "$(dirname "$restore_path")" > /dev/null
    else
        "$TAR_BIN" -xzf "$archive_file" -C "$(dirname "$restore_path")"
    fi
    echo -e "${GREEN}Restore complete!${NC}"
}

select_backup() {
    local pattern="$1"
    # Search for both supported types
    mapfile -t files < <(ls -t "$BACKUP_PATH"/${pattern}*.{zip,tar.gz} 2>/dev/null | head -n 10)
    
    if [[ ${#files[@]} -eq 0 ]]; then
        echo -e "${RED}No backups found for pattern: $pattern${NC}"; return 1
    fi
    
    echo "Select a backup to restore:"
    for i in "${!files[@]}"; do
        echo -e "$((i + 1)). ${CYAN}$(basename "${files[$i]}")${NC}"
    done
    
    read -p "Enter selection (1-${#files[@]}): " choice
    if [[ "$choice" =~ ^[0-9]+$ ]] && ((choice >= 1 && choice <= ${#files[@]})); then
        SELECTED_FILE="${files[$((choice - 1))]}"
        return 0
    fi
    echo -e "${RED}Invalid selection.${NC}"
    return 1
}

# --- Parameter Support ---

# Use getopt for long option support
PARSED_ARGS=$(getopt -o hbt:f:o:s:n: --long help,backup,type:,format:,output:,save-path:,name: --name "$0" -- "$@")
if [[ $? -ne 0 ]]; then
    usage
    exit 1
fi

eval set -- "$PARSED_ARGS"

while true; do
    case "$1" in
        -h|--help)
            usage
            exit 0
            ;;
        -b|--backup)
            ACTION="backup"
            shift
            ;;
        -t|--type)
            TYPE="$2"
            shift 2
            ;;
        -f|--format)
            FORMAT="$2"
            shift 2
            ;;
        -o|--output)
            BACKUP_PATH="$2"
            shift 2
            ;;
        -s|--save-path)
            SAVE_ROOT="$2"
            shift 2
            ;;
        -n|--name)
            DEFAULT_SAVE_NAME="$2"
            shift 2
            ;;
        --)
            shift
            break
            ;;
        *)
            echo "Programming error"
            exit 3
            ;;
    esac
done

# Re-evaluate dependent variables
SAVE_GAME_FOLDER="$SAVE_ROOT/$DEFAULT_SAVE_NAME"
DEFAULT_PREFIX=$(echo "$DEFAULT_SAVE_NAME" | tr ' ' '_')

# Ensure backup path exists if changed
[[ ! -d "$BACKUP_PATH" ]] && mkdir -p "$BACKUP_PATH"

if [[ "$ACTION" == "backup" ]]; then
    TYPE=${TYPE:-"Default"}
    if [[ "$TYPE" == "Default" ]]; then
        backup_folder "$SAVE_GAME_FOLDER" "Default"
    else
        backup_folder "$SAVE_ROOT" "All"
    fi
    exit 0
fi

# --- Main Interactive Loop ---

while true; do
    print_header
    echo "Menu:"
    echo -e "1. Backup default save (${CYAN}$DEFAULT_PREFIX${NC})"
    echo -e "2. Backup ALL saves"
    echo -e "3. Restore default save"
    echo -e "4. Restore ALL saves"
    echo -e "5. Toggle Format (${YELLOW}ZIP / TAR.GZ${NC})"
    echo -e "6. Exit"
    echo ""
    read -p "Please select an option (1-6): " choice
    
    case $choice in
        1) backup_folder "$SAVE_GAME_FOLDER" "Default" ;;
        2) backup_folder "$SAVE_ROOT" "All" ;;
        3)
            if select_backup "$DEFAULT_PREFIX"; then
                restore_folder "$SAVE_GAME_FOLDER" "$SELECTED_FILE"
            fi
        ;;
        4)
            if select_backup "$ALL_SAVES_PREFIX"; then
                restore_folder "$SAVE_ROOT" "$SELECTED_FILE"
            fi
        ;;
        5)
            [[ "$FORMAT" == "tar.gz" ]] && FORMAT="zip" || FORMAT="tar.gz"
            echo -e "${GREEN}Format set to: $FORMAT${NC}"
            sleep 1
            continue
        ;;
        6) echo "Goodbye!"; exit 0 ;;
        *) echo -e "${RED}Invalid option.${NC}" ;;
    esac
    echo ""
    read -p "Press Enter to continue..."
done