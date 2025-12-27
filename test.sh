#!/bin/bash

# Configuration
SCRIPT="./backup7D2D.sh"
TEST_BACKUP_DIR="./test_backups"
SAVE_ROOT="$HOME/.local/share/7DaysToDie/Saves"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Ensure script is executable
chmod +x "$SCRIPT"

# Clean and create test backup directory
echo -e "Setting up test backup directory at ${TEST_BACKUP_DIR}..."
rm -rf "$TEST_BACKUP_DIR"
mkdir -p "$TEST_BACKUP_DIR"

# Helper function for assertions
assert_file_exists() {
    local pattern="$1"
    local description="$2"
    # Find files matching pattern in the test dir
    local files=("$TEST_BACKUP_DIR"/$pattern)
    
    # Check if the glob actually expanded to an existing file
    if [[ -e "${files[0]}" ]]; then
        local file="${files[0]}"
        echo -e "${GREEN}[PASS] ${description}${NC} -> Found: $(basename "$file")"
        
        # Integrity Check
        echo "       Verifying archive integrity..."
        if [[ "$file" == *.tar.gz || "$file" == *.tar ]]; then
            if tar -tf "$file" >/dev/null 2>&1; then
                echo -e "${GREEN}       [OK] Archive is valid.${NC}"
                return 0
            else
                echo -e "${RED}       [FAIL] Archive is corrupt!${NC}"
                return 1
            fi
        elif [[ "$file" == *.zip ]]; then
            if unzip -t "$file" >/dev/null 2>&1; then
                echo -e "${GREEN}       [OK] Archive is valid.${NC}"
                return 0
            else
                echo -e "${RED}       [FAIL] Archive is corrupt!${NC}"
                return 1
            fi
        fi
        return 0
    else
        echo -e "${RED}[FAIL] ${description}${NC}"
        echo "       Expected file matching: $pattern"
        return 1
    fi
}

echo "============================================"
echo "Starting backup7D2D.sh Functional Tests"
echo "============================================"

# Test 1: Default Backup (tar.gz)
echo "Test 1: Default Backup (tar.gz)"
"$SCRIPT" -b -o "$TEST_BACKUP_DIR"
assert_file_exists "Votute_County_*.tar.gz" "Default backup file created"
echo "--------------------------------------------"

# Test 2: ZIP Format
echo "Test 2: ZIP Format Backup"
"$SCRIPT" -b -f zip -o "$TEST_BACKUP_DIR"
assert_file_exists "Votute_County_*.zip" "ZIP backup file created"
echo "--------------------------------------------"

# Test 3: TAR Format
echo "Test 3: TAR Format Backup (No Compression)"
"$SCRIPT" -b -f tar -o "$TEST_BACKUP_DIR"
assert_file_exists "Votute_County_*.tar" "TAR backup file created"
echo "--------------------------------------------"

# Test 4: Specific Save Name (Navezgane)
# We verified 'Navezgane' exists in the user's save directory
echo "Test 4: Specific Save Name (Navezgane)"
"$SCRIPT" -b -n "Navezgane" -o "$TEST_BACKUP_DIR"
assert_file_exists "Navezgane_*.tar.gz" "Specific save backup created"
echo "--------------------------------------------"

# Test 5: Backup All Saves
echo "Test 5: Backup ALL Saves"
"$SCRIPT" -b -t All -o "$TEST_BACKUP_DIR"
assert_file_exists "ALLSAVES_*.tar.gz" "All-saves backup file created"
echo "--------------------------------------------"

# Test 6: Help Argument
echo "Test 6: Help Argument"
"$SCRIPT" -h > /dev/null
if [ $? -eq 0 ]; then
    echo -e "${GREEN}[PASS] Help argument executed successfully${NC}"
else
    echo -e "${RED}[FAIL] Help argument returned error code${NC}"
fi
echo "--------------------------------------------"

# Test 7: Restore Functionality
echo "Test 7: Restore Functionality"
TEST_SAVE_ROOT="$TEST_BACKUP_DIR/Saves"
TEST_WORLD="TestWorld"
TEST_WORLD_PATH="$TEST_SAVE_ROOT/$TEST_WORLD"
mkdir -p "$TEST_WORLD_PATH"
echo "Original Content" > "$TEST_WORLD_PATH/main.ttw"

# Create backup
"$SCRIPT" -b -s "$TEST_SAVE_ROOT" -n "$TEST_WORLD" -o "$TEST_BACKUP_DIR" > /dev/null

# Find the backup file
BACKUP_FILE=$(ls "$TEST_BACKUP_DIR/${TEST_WORLD}_"*.tar.gz | head -n 1)

if [[ -f "$BACKUP_FILE" ]]; then
    echo "Backup created: $(basename "$BACKUP_FILE")"
    
    # Modify the world
    echo "Corrupted Content" > "$TEST_WORLD_PATH/main.ttw"
    
    # Restore (Output path needed for safety backup location)
    "$SCRIPT" -r "$BACKUP_FILE" -s "$TEST_SAVE_ROOT" -n "$TEST_WORLD" -o "$TEST_BACKUP_DIR" > /dev/null
    
    # Verify
    CONTENT=$(cat "$TEST_WORLD_PATH/main.ttw")
    if [[ "$CONTENT" == "Original Content" ]]; then
        echo -e "${GREEN}[PASS] Restore successful. Content verified.${NC}"
        
        # Check for PreRestore backup
        if ls "$TEST_BACKUP_DIR/${TEST_WORLD}_PreRestore_"*.tar.gz 1> /dev/null 2>&1; then
             echo -e "${GREEN}[PASS] Pre-Restore safety backup found.${NC}"
        else
             echo -e "${RED}[FAIL] Pre-Restore safety backup MISSING.${NC}"
        fi
        
    else
        echo -e "${RED}[FAIL] Restore failed. Content: '$CONTENT'${NC}"
    fi
else
    echo -e "${RED}[FAIL] Could not find backup file to restore.${NC}"
fi
echo "--------------------------------------------"

echo "Tests Completed."
echo "Test artifacts are located in: $TEST_BACKUP_DIR"
