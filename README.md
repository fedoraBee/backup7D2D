# 7D2D Backup & Restore Script (Linux Edition)

A robust Bash utility designed for managing **7 Days to Die** save games on Linux. This tool offers an interactive menu for ease of use and powerful command-line arguments for automation.

Inspired by a Powershell backup script from [LewsTherinSedai](https://github.com/LewsTherinSedai/Public/tree/main/Games/7D2D), this Linux port is optimized for performance and reliability on distributions like Fedora, Ubuntu, and Debian.

## Key Features

*   **Dual Format Support:** Defaults to **`.tar.gz`** for native Linux efficiency, with optional **`.zip`** support for cross-platform compatibility.
*   **Safety First:** Automatically triggers a **PreRestore snapshot** before overwriting any data during a restore operation, ensuring you never lose progress accidentally.
*   **Flexible Scope:** Backup a specific "default" save game or the entire Saves directory.
*   **Interactive CLI:** Color-coded, menu-driven interface for easy manual management.
*   **Automation Ready:** Full support for command-line arguments, making it perfect for `cron` jobs or systemd timers.
*   **Smart Structure:** Archives are created with clean, relative paths to avoid absolute path clutter.

## Prerequisites

Ensure you have the standard compression utilities installed. Most Linux distributions have `tar` by default.

For ZIP support:
```bash
# Fedora
sudo dnf install zip unzip

# Ubuntu/Debian
sudo apt install zip unzip
```

## Installation

1.  **Clone or Download** this repository.
2.  **Make the script executable:**
    ```bash
    chmod +x backup7D2D.sh
    ```

## Configuration

Open `backup7D2D.sh` in your preferred text editor to customize the paths if your setup differs from the defaults:

```bash
# Standard paths for Steam on Linux
SAVE_ROOT="$HOME/.local/share/7DaysToDie/Saves"

# The specific world/save you play most often
DEFAULT_SAVE_NAME="Votute County"

# Where backups will be stored
BACKUP_PATH="$HOME/Documents/7d2dBackups"
```

## Usage

### 1. Interactive Mode
Simply run the script without arguments to launch the text-based UI:

```bash
./backup7D2D.sh
```

You will be presented with a menu:
1.  **Backup default save:** Backs up the folder specified in `DEFAULT_SAVE_NAME`.
2.  **Backup ALL saves:** Backs up the entire `SAVE_ROOT`.
3.  **Restore default save:** Lists available backups for the default save and restores the selection.
4.  **Restore ALL saves:** Lists available backups for the global saves folder and restores the selection.
5.  **Toggle Format:** Switch between `.tar.gz` and `.zip` for the current session.

### 2. Automation (Command Line)
Use flags to bypass the menu, ideal for scheduled backups.

| Flag (Short/Long) | Options | Description |
| :--- | :--- | :--- |
| `-h`, `--help` | N/A | Show help message. |
| `-b`, `--backup` | N/A | **Required.** Triggers the backup action immediately. |
| `-t`, `--type` | `Default`, `All` | **Optional.** Defaults to `Default`. Determines if you backup the single target save or everything. |
| `-f`, `--format` | `tar.gz`, `zip` | **Optional.** Defaults to `tar.gz`. Overrides the script default format. |
| `-o`, `--output` | PATH | **Optional.** Custom output backup path. |
| `-s`, `--save-path` | PATH | **Optional.** Custom save root directory. |
| `-n`, `--name` | NAME | **Optional.** Custom default save name. |

#### Examples:

**Backup the default save (Standard):**
```bash
./backup7D2D.sh --backup
```

**Backup ALL saves:**
```bash
./backup7D2D.sh -b -t All
```

**Backup default save as a ZIP file:**
```bash
./backup7D2D.sh --backup --format zip
```

## Restoration & Safety
When you choose to **Restore**, the script performs the following actions:
1.  **Safety Snapshot:** Immediately creates a backup of the *current* state of the target folder (suffixed with `_PreRestore`).
2.  **Extraction:** Decompresses the selected archive, overwriting files in the target directory.

This ensures that if you restore the wrong file or change your mind, your pre-restore state is safely saved in the backup folder.

## Credits
*   **Author:** [fedoraBee](https://github.com/fedoraBee)
*   **Source:** [GitHub](https://github.com/fedoraBee/backup7D2D)
*   **Inspiration:** [LewsTherinSedai's Public Repo](https://github.com/LewsTherinSedai/Public/tree/main/Games/7D2D)
