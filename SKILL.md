---
name: obsidian-vault
description: |
  Integrate with Obsidian vaults through the Local REST API plugin.

  Use this skill when the user wants to:
  - Search notes in their Obsidian vault
  - Read specific notes
  - Create new notes
  - Modify existing notes
  - Manage daily/periodic notes
  - Execute Dataview queries

  IMPORTANT: This skill performs destructive operations (create, modify, delete).
  Always follow safety rules and confirmation requirements.

  Activates when user mentions:
  - "Obsidian", "my vault", "my notes"
  - "daily note", "journal entry"
  - "search my notes", "find in Obsidian"
  - Creating, updating, or deleting notes
tools:
  - Bash
  - Read
  - Write
---

# Obsidian Vault Integration Skill

You are operating the **Obsidian Vault Integration Skill**, which enables Claude to interact with Obsidian vaults through the Local REST API plugin. This skill provides complete access to all 31 API endpoints for reading, searching, creating, updating, and managing Obsidian notes.

**Critical Context**: The Obsidian Local REST API runs on localhost (HTTPS port 27124 by default) and requires Bearer token authentication. All operations use standard HTTP methods with markdown content.

---

# SECTION 1: GUARDRAIL DEFINITIONS

Each guardrail defines WHEN it applies, WHAT it checks, and HOW to confirm. These are reusable safety patterns that endpoints reference by ID.

## G1: DELETE Permission Check
**ID**: `G1`
**Type**: Config-based blocking
**Applies to**: All DELETE operations
**Risk Level**: 🔴 CRITICAL - Permanent data loss

**Logic**:
1. Load `allowDelete` from config (see Configuration section)
2. If `allowDelete` is `false` (default) → **BLOCK operation entirely**
3. If `allowDelete` is `true` → Proceed to G2 (DELETE Confirmation)

**User Message (when blocked)**:
```
❌ DELETE operations are disabled

To enable DELETE operations, set:
  - Environment: OBSIDIAN_SKILL_ALLOW_DELETE=true
  - .env file: allowDelete=true
  - Config file: ~/.cc_obsidian/config.json → "allowDelete": true

⚠️  Enabling DELETE is permanent. Consider using backups.
```

**Affected Endpoints**: `DELETE /active/`, `DELETE /vault/{filename}`, `DELETE /periodic/{period}/`, `DELETE /periodic/{period}/{year}/{month}/{day}/`

---

## G2: DELETE Confirmation
**ID**: `G2`
**Type**: Mandatory user confirmation
**Applies to**: All DELETE operations (after G1 passes)
**Risk Level**: 🔴 CRITICAL - Irreversible

**Logic**:
1. Get file content for preview (if accessible)
2. Calculate file stats (lines, words, size)
3. Show confirmation prompt with operation type, target path, content preview, and file stats
4. Require exact text match: user MUST type `DELETE` (all caps)
5. If current periodic note (today's daily, this week's weekly): Extra warning + require typing `DELETE TODAY` instead

**Can be skipped?** NO - NEVER (even with `DANGEROUSLY_SKIP_CONFIRMATIONS=true`)

**Confirmation Template**:
```
⚠️  DESTRUCTIVE OPERATION - FILE DELETION

Operation: DELETE
Target: Projects/meeting-notes.md
Current size: 234 lines (1,456 words)

--- Content preview ---
Meeting Notes - Q4 Planning
[first 200 chars of content]
--- End preview ---

⚠️  This operation CANNOT be undone.
⚠️  A backup will be created (if backup.enabled: true)

Type 'DELETE' (in caps) to confirm, or 'cancel' to abort: _
```

**For Current Period Notes**:
```
⚠️⚠️⚠️  DELETING TODAY'S DAILY NOTE ⚠️⚠️⚠️

File: 2025-11-10.md (TODAY'S daily note)
Created: Today at 6:00 AM
Modified: 5 minutes ago
Size: 1,234 lines (5,678 words)

--- Content preview ---
2025-11-10 - Sunday
Morning Review
[content...]
--- End preview ---

⚠️  This contains ALL of today's entries, tasks, and notes.
⚠️  Consider archiving instead of deleting.

Type 'DELETE TODAY' (exactly) to confirm, or 'cancel' to abort: _
```

---

## G3: PUT Confirmation (File Exists)
**ID**: `G3`
**Type**: User confirmation with existence check
**Applies to**: PUT operations on existing files
**Risk Level**: 🟠 HIGH - Complete content replacement

**Logic**:
1. Check if file exists (GET request)
2. If file doesn't exist → Skip to simple "yes/no" confirmation (creating new file)
3. If file exists: Get current content, calculate stats, show preview (first 100 + last 100 chars), suggest safer alternatives (POST/PATCH), require exact text match: `REPLACE` (all caps)

**Can be skipped?** YES (with `DANGEROUSLY_SKIP_CONFIRMATIONS=true`)

**Confirmation Template (File Exists)**:
```
⚠️  DESTRUCTIVE OPERATION - CONTENT REPLACEMENT

Operation: PUT (Replace All Content)
Target: Projects/meeting-notes.md
Current size: 234 lines (1,456 words)

--- Current content preview ---
[First 100 chars...]
...
[Last 100 chars...]
--- End current content ---

--- New content preview ---
[First 100 chars of new content...]
--- End new content ---

⚠️  ALL existing content will be PERMANENTLY LOST.
⚠️  A backup will be created (if backup.enabled: true)

Safer alternatives:
  - POST /vault/Projects/meeting-notes.md → Append to end
  - PATCH /vault/Projects/meeting-notes.md → Modify specific section

Type 'REPLACE' (in caps) to confirm, or 'cancel' to abort: _
```

**Confirmation Template (New File)**:
```
Creating new file: Projects/new-note.md

--- Content preview ---
[First 200 chars...]
--- End preview ---

Confirm? (yes/no): _
```

**Affected Endpoints**: `PUT /active/`, `PUT /vault/{filename}`, `PUT /periodic/{period}/`, `PUT /periodic/{period}/{year}/{month}/{day}/`

---

## G4: PATCH Replace Confirmation
**ID**: `G4`
**Type**: Operation-conditional confirmation
**Applies to**: PATCH operations with `Operation: replace` header
**Risk Level**: 🟡 MEDIUM - Section replacement

**Logic**:
1. Check `Operation` header value
2. If `Operation: append` or `Operation: prepend` → **Skip guardrail** (safe, additive)
3. If `Operation: replace`: Get current file content, parse and extract target section (if possible), show current section content, show new section content, require confirmation: type `yes`

**Can be skipped?** YES (with `DANGEROUSLY_SKIP_CONFIRMATIONS=true`)

**Confirmation Template**:
```
⚠️  PARTIAL CONTENT REPLACEMENT

Operation: PATCH with Operation=replace
Target Type: heading
Target: "Tasks"
File: Projects/meeting-notes.md

--- Current section content ---
Tasks section:
- [ ] Review Q4 goals
- [ ] Schedule team sync
--- End current section ---

--- New section content ---
Tasks section:
- [ ] Complete project proposal
--- End new section ---

⚠️  This section will be completely replaced.
⚠️  A backup will be created (if backup.enabled: true)

Type 'yes' to confirm, or 'no' to cancel: _
```

**Affected Endpoints**: `PATCH /active/` (only when `Operation: replace`), `PATCH /vault/{filename}`, `PATCH /periodic/{period}/`, `PATCH /periodic/{period}/{year}/{month}/{day}/`

---

## G5: Bulk Operation Confirmation
**ID**: `G5`
**Type**: Count-based confirmation
**Applies to**: Operations affecting >5 files
**Risk Level**: 🟡 MEDIUM - Multiple file modification

**Logic**:
1. Count total files affected by operation
2. If count ≤ 5 → **Skip guardrail** (small batch, proceed)
3. If count > 5: Show complete list of affected files, display count prominently, require confirmation: type `yes`

**Can be skipped?** YES (with `DANGEROUSLY_SKIP_CONFIRMATIONS=true`)

**Confirmation Template**:
```
⚠️  BULK OPERATION

Operation: POST (Append)
Affected files: 12

Files to be modified:
  1. Archive/2025-01-01.md
  2. Archive/2025-01-02.md
  3. Archive/2025-01-03.md
  [...]
 12. Archive/2025-01-12.md

--- Content to append ---
[Preview of content being appended]
--- End content ---

Type 'yes' to proceed, or 'no' to cancel: _
```

**Affected Operations**: Any POST operation affecting >5 files, any batch PUT/PATCH/DELETE (though DELETE has G1+G2)

---

## G6: Active File Context Check
**ID**: `G6`
**Type**: Pre-operation context verification
**Applies to**: All operations on `/active/` endpoints
**Risk Level**: 🟡 MEDIUM - User may not know active file

**Logic**:
1. Call `GET /active/` to retrieve current active file path
2. Display prominently: "Active file: path/to/file.md"
3. Ask user: "Is this the file you want to [operation]?"
4. If user unsure or says no → **ABORT operation**
5. Suggest user check Obsidian window first

**Can be skipped?** NO (always show active file path)

**Confirmation Template**:
```
The currently active file in Obsidian is:
📄 Projects/meeting-notes.md

Is this the file you want to [DELETE/modify/append to]? (yes/no): _

(If unsure, check your Obsidian window first)
```

**Affected Endpoints**: `PUT /active/`, `POST /active/`, `PATCH /active/`, `DELETE /active/`

---

## G7: User Abort Keywords
**ID**: `G7`
**Type**: Global abort pattern
**Applies to**: All confirmation prompts
**Risk Level**: N/A (safety mechanism)

**Logic**:
1. Accept any of these keywords as immediate abort: "no", "cancel", "stop", "abort"
2. Acknowledge: "❌ Operation cancelled"
3. Stop execution immediately
4. Do NOT proceed with any part of the operation

**Can be skipped?** NO (always active)

**Response**:
```
❌ Operation cancelled

No changes were made.
```

---

# SECTION 2: CONFIGURATION & SETUP

## Configuration Sources

The skill uses a **three-tier fallback system** (first found wins):

1. **Environment Variables** (Highest Priority)
   - Prefix: `OBSIDIAN_SKILL_`
   - Example: `OBSIDIAN_SKILL_API_KEY="your-key"`

2. **Project .env File** (Second Priority)
   - Location: `.env` in project root
   - No prefix required
   - Example: `apiKey=your-key`

3. **User Config File** (Lowest Priority)
   - Location: `~/.cc_obsidian/config.json`
   - No prefix required
   - Example: `{"apiKey": "your-key"}`

## Available Settings

| Setting | Env Var | Config Key | Type | Default | Description |
|---------|---------|------------|------|---------|-------------|
| API Key | `OBSIDIAN_SKILL_API_KEY` | `apiKey` | string | *required* | Authentication token from Obsidian Local REST API plugin |
| API URL | `OBSIDIAN_SKILL_API_URL` | `apiUrl` | string | `https://localhost:27124` | Base URL for API |
| Allow DELETE | `OBSIDIAN_SKILL_ALLOW_DELETE` | `allowDelete` | boolean | `false` | Enable DELETE operations |
| Backup Enabled | `OBSIDIAN_SKILL_BACKUP_ENABLED` | `backupEnabled` | boolean | `true` | Auto-backup before destructive ops |
| Backup Directory | `OBSIDIAN_SKILL_BACKUP_DIRECTORY` | `backupDirectory` | string | `~/.cc_obsidian/backups` | Where to store backups |
| Backup Keep N | `OBSIDIAN_SKILL_BACKUP_KEEP_LAST_N` | `backupKeepLastN` | number | `5` | Number of backups to keep |
| Skip Confirmations | `OBSIDIAN_SKILL_DANGEROUSLY_SKIP_CONFIRMATIONS` | `DANGEROUSLY_SKIP_CONFIRMATIONS` | boolean | `false` | Skip confirmations (except DELETE) |

## Example Configurations

### User Config (~/.cc_obsidian/config.json)

```json
{
  "apiKey": "your-api-key-here",
  "apiUrl": "https://localhost:27124",
  "allowDelete": false,
  "backupEnabled": true,
  "backupDirectory": "~/.cc_obsidian/backups",
  "backupKeepLastN": 5,
  "DANGEROUSLY_SKIP_CONFIRMATIONS": false
}
```

### Environment Variables

```bash
export OBSIDIAN_SKILL_API_KEY="your-key"
export OBSIDIAN_SKILL_API_URL="https://localhost:27124"
export OBSIDIAN_SKILL_ALLOW_DELETE=false
```

### Project .env File

```
apiKey=your-api-key-here
apiUrl=https://localhost:27124
allowDelete=false
```

## Configuration Loading Implementation

Use this pattern to load config values:

```python
import os
import json
from pathlib import Path
from typing import Any

def get_config_value(key: str, default: Any = None) -> Any:
    """
    Load configuration value with fallback priority.

    Priority:
    1. Environment variable: OBSIDIAN_SKILL_{KEY_UPPER}
    2. Project .env file: {key}
    3. User config: ~/.cc_obsidian/config.json
    4. Default value
    """
    # 1. Check environment variable with prefix
    env_key = f"OBSIDIAN_SKILL_{key.upper()}"
    env_value = os.getenv(env_key)
    if env_value is not None:
        # Convert string booleans
        if env_value.lower() in ('true', 'false'):
            return env_value.lower() == 'true'
        # Convert numbers
        if env_value.isdigit():
            return int(env_value)
        return env_value

    # 2. Check project .env file (simplified - use python-dotenv in production)
    dotenv_path = Path('.env')
    if dotenv_path.exists():
        with open(dotenv_path) as f:
            for line in f:
                line = line.strip()
                if line.startswith('#') or '=' not in line:
                    continue
                k, v = line.split('=', 1)
                if k.strip() == key:
                    v = v.strip()
                    if v.lower() in ('true', 'false'):
                        return v.lower() == 'true'
                    if v.isdigit():
                        return int(v)
                    return v

    # 3. Check user config file
    config_path = Path.home() / '.cc_obsidian' / 'config.json'
    if config_path.exists():
        with open(config_path) as f:
            config = json.load(f)
            if key in config:
                return config[key]

    # 4. Return default
    return default

# Usage examples
api_key = get_config_value('apiKey')
api_url = get_config_value('apiUrl', 'https://localhost:27124')
allow_delete = get_config_value('allowDelete', False)
```

---

# SECTION 3: API ENDPOINT REFERENCE

Base URL: `https://localhost:27124` (default)
Auth: `Authorization: Bearer {API_KEY}`
SSL: Use `verify=False` for self-signed localhost certs
Timeout: Always include `timeout=10`

**Path Format Rules** (CRITICAL):
- ✅ Relative to vault root: `folder/subfolder/note.md`
- ❌ No leading slash: `/folder/note.md` is WRONG
- ✅ Forward slashes only
- ✅ Always include `.md` extension
- ✅ URL-encode non-ASCII characters in PATCH targets

## Content-Type Standards

- `text/markdown` - Markdown content
- `application/json` - JSON data (tables, arrays)
- `application/vnd.olrapi.note+json` - Note with parsed metadata
- `application/vnd.olrapi.dataview.dql+txt` - Dataview DQL query
- `application/vnd.olrapi.jsonlogic+json` - JsonLogic query

## System Endpoints

### GET `/`
**Purpose**: Health check - returns server info
**Auth**: NO (only unauthenticated endpoint)
**Risk**: 🟢 None (read-only)
**Guardrails**: None

### GET `/openapi.yaml`
**Purpose**: Returns OpenAPI specification
**Auth**: YES
**Risk**: 🟢 None (read-only)
**Guardrails**: None

### GET `/obsidian-local-rest-api.crt`
**Purpose**: Returns SSL certificate
**Auth**: YES
**Risk**: 🟢 None (read-only)
**Guardrails**: None

## Active File Operations

### GET `/active/`
**Purpose**: Get path and content of currently active file
**Accept**: `text/markdown` or `application/vnd.olrapi.note+json`
**Risk**: 🟢 None (read-only)
**Guardrails**: None
**Use Case**: Identify active file before operations

### POST `/active/`
**Purpose**: Append content to end of active file
**Content-Type**: `text/markdown`
**Risk**: 🟢 Low (append-only)
**Guardrails**: **G6** (Active File Context), **G5** (if bulk)

### PUT `/active/`
**Purpose**: Replace entire content of active file
**Content-Type**: `text/markdown` or `*/*`
**Risk**: 🟠 HIGH - Overwrites ALL content
**Guardrails**: **G6** (Active File Context) → **G3** (PUT Confirmation)

### PATCH `/active/`
**Purpose**: Modify specific section of active file
**Headers**: `Operation` (append/prepend/replace), `Target-Type` (heading/block/frontmatter), `Target`, `Target-Delimiter` (default: `::`), `Content-Type`
**Risk**: 🟡 MEDIUM if `Operation: replace`, 🟢 Low if append/prepend
**Guardrails**: **G6** (Active File Context) → **G4** (only when `Operation: replace`)

### DELETE `/active/`
**Purpose**: Delete currently active file
**Risk**: 🔴 CRITICAL - Irreversible
**Guardrails**: **G6** (Active File Context) → **G1** (Permission Check) → **G2** (DELETE Confirmation)

## Vault File Operations

### GET `/vault/{filename}`
**Purpose**: Read file content
**Path**: `folder/subfolder/note.md` (no leading slash)
**Accept**: `text/markdown` or `application/vnd.olrapi.note+json`
**Risk**: 🟢 None (read-only)
**Guardrails**: None

### POST `/vault/{filename}`
**Purpose**: Append to file (creates if doesn't exist)
**Content-Type**: `text/markdown`
**Risk**: 🟢 Low (append-only)
**Guardrails**: **G5** (only if bulk >5 files)

### PUT `/vault/{filename}`
**Purpose**: Create new file OR replace existing file entirely
**Content-Type**: `text/markdown` or `*/*`
**Risk**: 🟠 HIGH - Overwrites ALL content if file exists
**Guardrails**: **G3** (PUT Confirmation)

### PATCH `/vault/{filename}`
**Purpose**: Modify specific section of file
**Headers**: Same as `PATCH /active/` (see above)
**Risk**: 🟡 MEDIUM if `Operation: replace`, 🟢 Low if append/prepend
**Guardrails**: **G4** (only when `Operation: replace`)

### DELETE `/vault/{filename}`
**Purpose**: Permanently delete file
**Risk**: 🔴 CRITICAL - Irreversible
**Guardrails**: **G1** (Permission Check) → **G2** (DELETE Confirmation)

## Vault Directory Operations

### GET `/vault/`
**Purpose**: List files in vault root
**Returns**: `{"files": ["note.md", "folder/"]}`
**Risk**: 🟢 None (read-only)
**Guardrails**: None
**Note**: Directories end with `/`

### GET `/vault/{pathToDirectory}/`
**Purpose**: List files in specific directory
**Returns**: `{"files": ["note.md", "subfolder/"]}`
**Risk**: 🟢 None (read-only)
**Guardrails**: None
**Note**: Empty directories not returned

## Periodic Notes Operations

Supports: `daily`, `weekly`, `monthly`, `quarterly`, `yearly`

### GET `/periodic/{period}/`
**Purpose**: Get current period note (today's daily, this week's weekly, etc.)
**Accept**: `text/markdown` or `application/vnd.olrapi.note+json`
**Risk**: 🟢 None (read-only)
**Guardrails**: None

### GET `/periodic/{period}/{year}/{month}/{day}/`
**Purpose**: Get historical periodic note for specific date
**Risk**: 🟢 None (read-only)
**Guardrails**: None

### POST `/periodic/{period}/`
**Purpose**: Append to current period note (creates if doesn't exist)
**Content-Type**: `text/markdown`
**Risk**: 🟢 Low (append-only)
**Guardrails**: **G5** (only if bulk)

### POST `/periodic/{period}/{year}/{month}/{day}/`
**Purpose**: Append to historical periodic note (creates if doesn't exist)
**Content-Type**: `text/markdown`
**Risk**: 🟢 Low (append-only)
**Guardrails**: **G5** (only if bulk)

### PUT `/periodic/{period}/`
**Purpose**: Replace content of current period note
**Content-Type**: `text/markdown` or `*/*`
**Risk**: 🟠 HIGH - Overwrites today's/this week's note entirely
**Guardrails**: **G3** (PUT Confirmation) with extra warning for current period

### PUT `/periodic/{period}/{year}/{month}/{day}/`
**Purpose**: Replace content of historical periodic note
**Content-Type**: `text/markdown` or `*/*`
**Risk**: 🟠 HIGH - Overwrites historical note
**Guardrails**: **G3** (PUT Confirmation)

### PATCH `/periodic/{period}/`
**Purpose**: Modify section of current period note
**Headers**: Same as `PATCH /active/` (see above)
**Risk**: 🟡 MEDIUM if `Operation: replace`, 🟢 Low if append/prepend
**Guardrails**: **G4** (only when `Operation: replace`)

### PATCH `/periodic/{period}/{year}/{month}/{day}/`
**Purpose**: Modify section of historical periodic note
**Headers**: Same as `PATCH /active/` (see above)
**Risk**: 🟡 MEDIUM if `Operation: replace`, 🟢 Low if append/prepend
**Guardrails**: **G4** (only when `Operation: replace`)

### DELETE `/periodic/{period}/`
**Purpose**: Delete current period note
**Risk**: 🔴 CRITICAL - Deletes today's/this week's/this month's note
**Guardrails**: **G1** (Permission Check) → **G2** (DELETE Confirmation with extra prominent warning "THIS IS TODAY'S DAILY NOTE" and require "DELETE TODAY")
**Warning**: At 11 PM, deleting daily note loses entire day's work

### DELETE `/periodic/{period}/{year}/{month}/{day}/`
**Purpose**: Delete historical periodic note
**Risk**: 🔴 CRITICAL - Irreversible
**Guardrails**: **G1** (Permission Check) → **G2** (DELETE Confirmation with date clearly shown)

## Search Operations

### POST `/search/simple/`
**Purpose**: Simple text search across vault
**Body**: `{"query": "search term", "contextLength": 100}`
**Content-Type**: `application/json`
**Returns**: Array of matches with context
**Risk**: 🟢 None (read-only)
**Guardrails**: None

### POST `/search/`
**Purpose**: Advanced search (Dataview DQL or JsonLogic)
**Content-Type**:
  - `application/vnd.olrapi.dataview.dql+txt` for Dataview queries
  - `application/vnd.olrapi.jsonlogic+json` for JsonLogic queries
**Body**: Query string or JSON
**Returns**: Search results (only non-falsy results)
**Risk**: 🟢 None (read-only)
**Guardrails**: None

**Dataview DQL Example**:
```
TABLE
  time-played AS "Time Played",
  length AS "Length",
  rating AS "Rating"
FROM #game
SORT rating DESC
```

**JsonLogic Examples**:

Find by frontmatter value:
```json
{
  "==": [
    {"var": "frontmatter.myField"},
    "myValue"
  ]
}
```

Find by tag:
```json
{
  "in": [
    "myTag",
    {"var": "tags"}
  ]
}
```

**Custom JsonLogic Operators**:
- `glob: [PATTERN, VALUE]` - Match glob patterns
- `regexp: [PATTERN, VALUE]` - Match regular expressions

## Commands Operations

### GET `/commands/`
**Purpose**: List all available Obsidian commands
**Returns**: `{"commands": [{"id": "graph:open", "name": "Graph view: Open graph view"}]}`
**Risk**: 🟢 None (read-only)
**Guardrails**: None

### POST `/commands/{commandId}/`
**Purpose**: Execute Obsidian command
**Risk**: 🟠 VARIABLE - Depends on command
**Guardrails**: Command analysis with keyword detection (always show command name/description, require 'yes' for dangerous patterns: "delete", "remove", "clear", "erase", "destroy")

## Open File Operation

### POST `/open/{filename}`
**Purpose**: Open file in Obsidian UI (brings into focus)
**Query Params**: `newLeaf=true` to open in new tab
**Risk**: 🟢 None (UI operation only)
**Guardrails**: None
**Note**: Creates empty file if doesn't exist

---

# SECTION 4: OPERATIONAL PATTERNS

## Pattern 1: Read a Note

```python
import os
import requests

api_key = os.getenv('OBSIDIAN_SKILL_API_KEY')
api_url = os.getenv('OBSIDIAN_SKILL_API_URL', 'https://localhost:27124')

response = requests.get(
    f'{api_url}/vault/Projects/meeting-notes.md',
    headers={'Authorization': f'Bearer {api_key}'},
    verify=False,  # Required for self-signed localhost cert
    timeout=10     # Always include timeout
)

if response.status_code == 200:
    content = response.text
    print(f"✅ File read successfully ({len(content)} chars)")
    print(content)
elif response.status_code == 404:
    print(f"❌ File not found: Projects/meeting-notes.md")
else:
    print(f"❌ Error {response.status_code}: {response.text}")
```

## Pattern 2: Create New Note (with Confirmation)

```python
import os
import requests
from pathlib import Path

def create_note(file_path: str, content: str):
    """Create new note with confirmation"""

    api_key = os.getenv('OBSIDIAN_SKILL_API_KEY')
    api_url = os.getenv('OBSIDIAN_SKILL_API_URL', 'https://localhost:27124')

    # Check if file exists
    check = requests.get(
        f'{api_url}/vault/{file_path}',
        headers={'Authorization': f'Bearer {api_key}'},
        verify=False,
        timeout=10
    )

    if check.status_code == 200:
        # File exists - show warning (PUT would overwrite)
        print(f"⚠️  File already exists: {file_path}")
        print("Use PUT to replace or POST to append")
        return False

    # File doesn't exist - safe to create
    preview = content[:200] + "..." if len(content) > 200 else content
    print(f"Creating new file: {file_path}")
    print(f"Content preview:\n{preview}\n")

    confirm = input("Confirm? (yes/no): ").strip().lower()
    if confirm not in ['yes', 'y']:
        print("❌ Operation cancelled")
        return False

    # Create file
    response = requests.put(
        f'{api_url}/vault/{file_path}',
        headers={
            'Authorization': f'Bearer {api_key}',
            'Content-Type': 'text/markdown'
        },
        data=content,
        verify=False,
        timeout=10
    )

    if response.status_code in [200, 201, 204]:
        print(f"✅ File created: {file_path}")
        return True
    else:
        print(f"❌ Create failed: {response.status_code}")
        print(f"Error: {response.text}")
        return False
```

## Pattern 3: Search Notes

```python
def search_notes(query: str, context_length: int = 100):
    """Search notes with context"""

    api_key = os.getenv('OBSIDIAN_SKILL_API_KEY')
    api_url = os.getenv('OBSIDIAN_SKILL_API_URL', 'https://localhost:27124')

    response = requests.post(
        f'{api_url}/search/simple/',
        headers={
            'Authorization': f'Bearer {api_key}',
            'Content-Type': 'application/json'
        },
        json={
            'query': query,
            'contextLength': context_length
        },
        verify=False,
        timeout=10
    )

    if response.status_code == 200:
        results = response.json()
        print(f"✅ Found {len(results)} matches for '{query}'")

        for i, result in enumerate(results, 1):
            filename = result.get('filename', 'unknown')
            matches = result.get('matches', [])
            print(f"\n{i}. {filename}")
            for match in matches:
                context = match.get('context', '')
                print(f"   {context}")

        return results
    else:
        print(f"❌ Search failed: {response.status_code}")
        print(f"Error: {response.text}")
        return []
```

## Pattern 4: Update Note Section (PATCH)

```python
def update_note_section(file_path: str, heading: str, new_content: str, operation: str = 'replace'):
    """Update specific section of note using PATCH"""

    api_key = os.getenv('OBSIDIAN_SKILL_API_KEY')
    api_url = os.getenv('OBSIDIAN_SKILL_API_URL', 'https://localhost:27124')

    # If operation is 'replace', show current content and confirm
    if operation == 'replace':
        # Get current content
        response = requests.get(
            f'{api_url}/vault/{file_path}',
            headers={'Authorization': f'Bearer {api_key}'},
            verify=False,
            timeout=10
        )

        if response.status_code == 200:
            print(f"⚠️  PARTIAL CONTENT REPLACEMENT")
            print(f"Target: heading '{heading}' in {file_path}")
            print(f"New content:\n{new_content}\n")

            confirm = input("Type 'yes' to confirm: ").strip().lower()
            if confirm != 'yes':
                print("❌ Operation cancelled")
                return False

    # Execute PATCH
    response = requests.patch(
        f'{api_url}/vault/{file_path}',
        headers={
            'Authorization': f'Bearer {api_key}',
            'Operation': operation,  # append, prepend, or replace
            'Target-Type': 'heading',
            'Target': heading,
            'Content-Type': 'text/markdown'
        },
        data=new_content,
        verify=False,
        timeout=10
    )

    if response.status_code in [200, 204]:
        print(f"✅ Section updated: {heading}")
        return True
    else:
        print(f"❌ PATCH failed: {response.status_code}")
        print(f"Error: {response.text}")
        return False
```

## Pattern 5: Append to Daily Note

```python
def append_to_daily_note(content: str, date: str = None):
    """
    Append content to daily note

    Args:
        content: Content to append
        date: Optional date (YYYY-MM-DD), defaults to today
    """

    api_key = os.getenv('OBSIDIAN_SKILL_API_KEY')
    api_url = os.getenv('OBSIDIAN_SKILL_API_URL', 'https://localhost:27124')

    if date is None:
        # Use current date endpoint
        endpoint = f'{api_url}/periodic/daily/'
    else:
        # Use specific date endpoint
        year, month, day = date.split('-')
        endpoint = f'{api_url}/periodic/daily/{year}/{month}/{day}/'

    response = requests.post(
        endpoint,
        headers={
            'Authorization': f'Bearer {api_key}',
            'Content-Type': 'text/markdown'
        },
        data=content,
        verify=False,
        timeout=10
    )

    if response.status_code in [200, 204]:
        date_str = date or "today"
        print(f"✅ Appended to daily note ({date_str})")
        return True
    else:
        print(f"❌ Append failed: {response.status_code}")
        print(f"Error: {response.text}")
        return False
```

## Pattern 6: DELETE File (with Guardrails)

```python
def delete_file_with_guardrails(file_path: str):
    """Delete file with complete guardrail implementation"""

    from typing import Any

    # Helper function for config loading
    def get_config_value(key: str, default: Any = None) -> Any:
        """Load configuration value with fallback priority"""
        # Implementation from Configuration section
        # ... (see Configuration Loading Implementation above)
        pass

    api_key = os.getenv('OBSIDIAN_SKILL_API_KEY')
    api_url = os.getenv('OBSIDIAN_SKILL_API_URL', 'https://localhost:27124')

    # G1: Check if DELETE is allowed
    if not get_config_value('allowDelete', False):
        print("❌ DELETE operations are disabled.")
        print("To enable DELETE operations, set one of:")
        print("  - Environment variable: OBSIDIAN_SKILL_ALLOW_DELETE=true")
        print("  - In .env file: allowDelete=true")
        print("  - In ~/.cc_obsidian/config.json: \"allowDelete\": true")
        return False

    # G2: Get file content for preview
    response = requests.get(
        f"{api_url}/vault/{file_path}",
        headers={'Authorization': f'Bearer {api_key}'},
        verify=False,
        timeout=10
    )

    if response.status_code == 200:
        content = response.text
        preview = content[:200] + "..." if len(content) > 200 else content
        word_count = len(content.split())
        line_count = len(content.splitlines())
    else:
        preview = "[Could not retrieve preview]"
        word_count = "unknown"
        line_count = "unknown"

    # G2: Show confirmation prompt
    print(f"""
⚠️  DESTRUCTIVE OPERATION - FILE DELETION

Operation: DELETE
Target: {file_path}
Current size: {line_count} lines ({word_count} words)

--- Content preview ---
{preview}
--- End preview ---

⚠️  This operation CANNOT be undone.
⚠️  A backup will be created (if backup.enabled: true)
""")

    # G2: Get confirmation (force_confirm=True means NEVER skip)
    confirm = input("Type 'DELETE' (in caps) to confirm, or 'cancel' to abort: ").strip()

    # G7: Check for abort keywords
    if confirm.lower() in ["no", "cancel", "stop", "abort"]:
        print("❌ Operation cancelled")
        return False

    if confirm != "DELETE":
        print("❌ Confirmation failed - must type 'DELETE' exactly")
        return False

    # Execute deletion
    response = requests.delete(
        f"{api_url}/vault/{file_path}",
        headers={'Authorization': f'Bearer {api_key}'},
        verify=False,
        timeout=10
    )

    if response.status_code == 204:
        print(f"✅ File deleted: {file_path}")
        return True
    else:
        print(f"❌ Delete failed: {response.status_code}")
        print(f"Error: {response.text}")
        return False
```

---

# SECTION 5: ERROR HANDLING

## Error 1: API Unavailable (Connection Refused)

**Symptoms**: `requests.exceptions.ConnectionError`, "Connection refused"

**Cause**: Obsidian Local REST API plugin not running

**Resolution**:
1. Check if Obsidian is running
2. Verify Local REST API plugin is enabled: Settings → Community Plugins → Local REST API
3. Confirm correct port: HTTPS 27124 (default) or HTTP 27123
4. Test: `curl -k -H "Authorization: Bearer $OBSIDIAN_SKILL_API_KEY" https://localhost:27124/`

**User Message**:
```
❌ Cannot connect to Obsidian Local REST API

Troubleshooting:
1. Is Obsidian running?
2. Is the Local REST API plugin enabled?
3. Check Settings → Community Plugins → Local REST API
4. Verify port: https://localhost:27124

Test connection:
curl -k -H "Authorization: Bearer $OBSIDIAN_SKILL_API_KEY" https://localhost:27124/
```

## Error 2: Authentication Failed (401 Unauthorized)

**Symptoms**: HTTP 401 status code, "Unauthorized" or "Invalid API key"

**Cause**: Missing or incorrect API key

**Resolution**:
1. Check API key in Obsidian: Settings → Local REST API → Show API Key
2. Verify configuration (check all sources):
   - `echo $OBSIDIAN_SKILL_API_KEY`
   - `.env` file in project
   - `~/.cc_obsidian/config.json`
3. Regenerate API key if needed

**User Message**:
```
❌ API key authentication failed

Your API key may be missing or incorrect.

To fix:
1. Get your API key from Obsidian:
   Settings → Community Plugins → Local REST API → Show API Key

2. Set in one of these locations:
   - Environment variable: export OBSIDIAN_SKILL_API_KEY="your-key"
   - Project .env: apiKey=your-key
   - User config: ~/.cc_obsidian/config.json

Currently checking:
  - OBSIDIAN_SKILL_API_KEY env var: [status]
  - .env file: [status]
  - config.json: [status]
```

## Error 3: File Not Found (404)

**Symptoms**: HTTP 404 status code, "File does not exist"

**Cause**: File doesn't exist or path format incorrect

**Resolution**:
1. Verify path format: `folder/note.md` (no leading slash)
2. Check file exists in vault
3. Ensure `.md` extension included
4. Confirm no typos in path

**User Message**:
```
❌ File not found: {path}

Check:
1. Path format: folder/subfolder/note.md (no leading slash)
2. File exists in vault
3. .md extension included
4. No typos in path

Correct format: ✅ Projects/meeting-notes.md
Wrong format: ❌ /Projects/meeting-notes.md
```

## Error 4: Bad Request (400)

**Symptoms**: HTTP 400 status code, "Bad Request"

**Cause**: Invalid parameters, malformed content, or incorrect headers

**Resolution**:
1. Check Content-Type header matches body format
2. Verify all required headers present (especially for PATCH)
3. Validate JSON syntax if using application/json
4. Ensure markdown content is valid
5. Check PATCH target exists and is unique

**User Message**:
```
❌ Bad request: {details}

Common causes:
1. Missing or incorrect Content-Type header
2. Malformed JSON or markdown content
3. PATCH operation missing required headers:
   - Operation: append/prepend/replace
   - Target-Type: heading/block/frontmatter
   - Target: identifier
4. Invalid target or ambiguous target
```

## Error 5: Method Not Allowed (405)

**Symptoms**: HTTP 405 status code, "Method not allowed"

**Cause**: Path references a directory instead of a file

**Resolution**:
1. Ensure path points to a file, not a directory
2. Add filename to path: `folder/` → `folder/note.md`
3. Use GET `/vault/{path}/` to list directory contents

**User Message**:
```
❌ Method not allowed: path references a directory

Your path points to a directory, but this operation requires a file.

Fix:
- Current path: Projects/ (directory)
- Correct path: Projects/meeting-notes.md (file)

To list directory contents, use: GET /vault/Projects/
```

---

# SECTION 6: OBSIDIAN SYNTAX & CONVENTIONS

## Path Format Rules (CRITICAL)

- ✅ **Relative to vault root**: `folder/subfolder/note.md`
- ❌ **No leading slash**: `/folder/note.md` is WRONG
- ✅ **Forward slashes only**: `folder/note.md` not `folder\note.md`
- ✅ **Always include extension**: `note.md` not `note`
- ✅ **URL-encode non-ASCII**: PATCH targets with special characters must be URL-encoded

**Examples**:
```
Correct: Projects/Work/meeting-notes.md
Wrong:   /Projects/Work/meeting-notes.md (leading slash)
Wrong:   Projects/Work/meeting-notes (missing .md)
Wrong:   Projects\Work\meeting-notes.md (backslashes)
```

## Obsidian-Specific Syntax (Must Preserve)

### Wikilinks
```markdown
[[Note Name]]                    # Link to note
[[Note Name|Display Text]]       # Link with custom text
[[Note Name#Heading]]           # Link to heading
[[Note Name#^block-id]]         # Link to block
```

### Tags
```markdown
#tag                            # Simple tag
#nested/tag                     # Nested tag
#tag-with-dashes                # Tag with dashes
```

### Block References
```markdown
Some content here ^block-id     # Block with reference ID
```

### Embeds
```markdown
![[Note Name]]                  # Embed note
![[Image.png]]                  # Embed image
![[Note#Heading]]               # Embed section
```

### Callouts
```markdown
> [!note]
> This is a note callout

> [!warning]
> This is a warning callout

> [!tip] Custom Title
> This is a tip with custom title
```

### Frontmatter
```markdown
---
title: My Note
tags: [project, important]
created: 2025-11-10
status: in-progress
---

Content starts here
```

## Important Obsidian Behaviors

1. **Case Sensitivity**: File paths are case-sensitive on some systems
2. **Spaces in Names**: Allowed but must be preserved exactly
3. **Special Characters**: Obsidian allows most special characters in filenames
4. **Folders**: Created automatically when creating notes with paths
5. **Templates**: If a folder has a template, Obsidian may auto-apply it

---

# SECTION 7: USER INTERACTION GUIDELINES

## Communication Style

- **Concise**: Claude Code is CLI-based - avoid walls of text
- **Technical**: Users are developers - use precise language
- **Helpful**: Provide actionable guidance, not just errors
- **Transparent**: Show what operations will do before executing

## When to Ask for Clarification

1. **Ambiguous file paths**: "Did you mean Projects/meeting.md or Archive/meeting.md?"
2. **Multiple matching files**: "Found 3 notes with 'meeting' - which one?"
3. **Destructive operations**: "This will delete X files - confirm?"
4. **Complex operations**: "Should I append or replace the section?"

## How to Present Options

```
Found multiple options:
1. Projects/meeting-notes.md (modified today)
2. Archive/meeting-notes.md (modified last week)

Which file? (1/2): _
```

## Progress Indicators

For multi-step operations:
```
Creating daily note...
✅ Daily note created
Appending tasks...
✅ Tasks added
Opening in Obsidian...
✅ Complete
```

## Success/Failure Messages

**Success**: Clear, specific, actionable
```
✅ File created: Projects/meeting-notes.md
✅ Appended 3 tasks to daily note
✅ Searched 42 notes, found 5 matches
```

**Failure**: Clear error, cause, and fix
```
❌ File not found: Projects/meeting.md
Cause: File doesn't exist
Fix: Create with PUT or check path
```

## When to Abort Operations

Immediately abort if:
- User says "no", "cancel", "stop", "abort"
- Configuration is invalid or missing
- API is unavailable
- File path is invalid
- Operation would cause unintended data loss

---

# SECTION 8: CONTEXT OPTIMIZATION WITH SUB-AGENTS

## When to Use General-Purpose Sub-Agents

Use the `Task` tool with `subagent_type: general-purpose` for these scenarios:

### 1. File Discovery (Multiple Rounds of Search)

**Scenario**: User asks "Find all notes about project X" but you don't know exact file names

**Reason**: Searching vault may require multiple API calls, grepping results, filtering

**Solution**: Delegate to sub-agent

**Example**:
```python
Task(
    subagent_type="general-purpose",
    description="Search Obsidian vault for notes",
    prompt="""
    Search the Obsidian vault for all notes related to "project X".

    Steps:
    1. Use POST /search/simple/ endpoint with query "project X"
    2. Review results and extract relevant file paths
    3. Return a list of file paths that match

    API Config:
    - Base URL: {api_url}
    - Headers: Authorization: Bearer {api_key}
    - Verify: False (self-signed cert)

    Return format:
    {
        "matching_files": ["path/to/note1.md", "path/to/note2.md"],
        "total_matches": 2
    }
    """
)
```

### 2. Bulk Read Operations (>5 Files)

**Scenario**: User asks "Summarize all my meeting notes from last month"

**Reason**: Reading many files consumes your context window

**Solution**: Delegate reading and initial processing to sub-agent, get summary back

### 3. Dataview Query Analysis

**Scenario**: User asks "What's the best Dataview query to find X?"

**Reason**: May require trial-and-error with different query syntax

**Solution**: Let sub-agent experiment with queries, return working query

### 4. Complex File Analysis (Large Files)

**Scenario**: User asks "Analyze my entire research note (5000 lines) and extract insights"

**Reason**: Large file content would consume significant context

**Solution**: Sub-agent reads and processes, returns condensed insights

## What NOT to Delegate

**DO NOT use sub-agents for**:
- ❌ Single file operations (just do it directly)
- ❌ Destructive operations (DELETE, PUT, PATCH replace) - skill must handle confirmations
- ❌ Configuration loading (skill handles this)
- ❌ Simple searches (<5 results expected)
- ❌ Operations requiring user confirmation (skill must show prompts)

## Sub-Agent Response Handling

When sub-agent returns, you (the skill) must:
1. **Validate results** - Check that sub-agent completed task successfully
2. **Apply guardrails** - If sub-agent found files to delete/modify, show confirmations
3. **Execute final operations** - Sub-agent does discovery, skill does API calls with safety checks
4. **Report to user** - Present results in user-friendly format

**Example Flow**:
```python
# User asks: "Delete all draft notes from 2023"

# Step 1: Delegate search to sub-agent
result = Task(
    subagent_type="general-purpose",
    description="Find draft notes from 2023",
    prompt="Search vault for files with 'draft' in name and created in 2023, return list of paths"
)

# Step 2: Skill validates and shows confirmation (NOT delegated)
draft_files = result['files']  # ['drafts/2023-01-01.md', 'drafts/2023-01-15.md']

print(f"Found {len(draft_files)} draft files from 2023:")
for f in draft_files:
    print(f"  - {f}")

# Step 3: Skill applies G1 + G2 guardrails (DELETE confirmation)
# Step 4: Skill executes DELETE (NOT delegated)
```

---

# CRITICAL SAFETY RULES - SUMMARY

**NEVER SKIP THESE**:

1. **DELETE Operations**: Check config (`allowDelete`), ALWAYS require explicit confirmation (type `DELETE`), NEVER skippable even with `DANGEROUSLY_SKIP_CONFIRMATIONS=true`

2. **PUT Operations**: Check if file exists first, show "ALL CONTENT WILL BE LOST" warning if exists, suggest safer alternatives (POST/PATCH), require explicit confirmation (type `REPLACE`)

3. **PATCH Replace Operations**: If `Operation: replace`, show current section content, require confirmation. If `Operation: append` or `prepend`, safe to proceed without confirmation

4. **Bulk Operations**: Count files, if >5 show list and require confirmation

5. **Command Execution**: GET command name/description first, check for dangerous keywords, require confirmation with command details

6. **Active File Operations**: GET `/active/` first to show file path, display prominently, confirm with user before proceeding

7. **Environment Variable Check**: Always check `os.getenv('OBSIDIAN_SKILL_DANGEROUSLY_SKIP_CONFIRMATIONS')` at runtime. If set to 'true', skip confirmations where allowed (but NEVER for DELETE)

8. **User Abort**: IMMEDIATELY stop if user says "no", "cancel", "stop", "abort". Never proceed after negative response

---

# FINAL NOTES

- **Token Efficiency**: Use sub-agents for bulk operations and file discovery
- **Error Handling**: Always include try/except blocks and timeout parameters
- **SSL Certificates**: Always use `verify=False` for localhost HTTPS (self-signed cert)
- **Path Format**: Critical - no leading slashes, always include `.md` extension
- **Backup System**: Automatic backups are created before destructive operations if `backupEnabled: true`
- **Configuration Priority**: Environment variables > .env file > config.json
- **Obsidian Syntax**: Preserve wikilinks, tags, callouts, frontmatter exactly as-is

**This skill enables powerful automation - use it responsibly with proper guardrails!**
