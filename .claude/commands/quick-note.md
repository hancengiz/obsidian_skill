---
description: Capture a quick note to today's daily note
argument-hint: [note content]
allowed-tools:
  - Task(*)
  - Read(*)
  - Write(*)
  - Bash(*)
---

## Context

- **Today's Date:** `date "+%Y-%m-%d"`
- **Note Content:** `$ARGUMENTS`
- **Vault Folder:** `Daily/`
- **File Format:** Markdown (appended to existing daily note)
- **Obsidian Skill:** Available for API operations

## Your Task

Capture a quick note to today's daily note with timestamp and clean formatting.

### Process

1. **Get or Create Daily Note**
   - Check if daily note exists for today
   - Path: `Daily/YYYY-MM-DD.md`
   - If not exists, create with header
   - If exists, append to it

2. **Format the Quick Note**
   - Add timestamp (HH:MM)
   - Clean up the content
   - Add to appropriate section (or create "Quick Notes" section)
   - Maintain Obsidian formatting (wikilinks, markdown, etc.)

3. **Append to Daily Note**
   - Use Obsidian skill PATCH operation to append
   - Target: Today's daily note
   - Operation: `append`
   - Content: Formatted quick note entry

4. **Confirm Success**
   - Show the user the note was captured
   - Display timestamp and content preview
   - Offer link to today's daily note

---

## Example Daily Note Structure

```markdown
---
title: Daily Note - 2024-11-11
date: 2024-11-11
tags:
  - daily
  - 2024-11
type: daily
---

# 2024-11-11

## Quick Notes

- **14:30** - Remember to update the documentation
- **15:45** - Need to review the installation script changes
- **16:20** - Idea: Add capture command to the skill

## Tasks
- [ ] Test the capture workflow
- [ ] Review pull requests

## Events
- Team standup at 10:00
- Code review session at 14:00

## Reflections
Good progress on the installer script fixes today.
```

---

## Implementation

### Step 1: Get or Create Daily Note
Use the **Obsidian Vault Skill** to check if today's daily note exists:

```
request: Get or create Daily/[YYYY-MM-DD].md
If it doesn't exist, create it with the structure shown above.
```

### Step 2: Append Quick Note
Use the skill's PATCH operation to append to the "Quick Notes" section:

```
request: Append to Daily/[YYYY-MM-DD].md
Target: Quick Notes heading
Content: - **[HH:MM]** - [Your note content]
```

The skill will:
- Get current time (HH:MM format)
- Append to the "Quick Notes" section under the appropriate heading
- Maintain the daily note structure
- Preserve existing content

### Step 3: Confirm
The skill will return confirmation showing:
- ✓ Timestamp added
- ✓ Content appended
- ✓ Daily note path

---

## Tips

- **Quick captures are for temporary thoughts** that might be developed later
- **Use timestamps** to track when you captured the thought
- **Review daily** to process and organize quick notes
- **Move important items** to dedicated notes or projects
- **Archive old daily notes** when no longer needed

---

## Quick Examples

### Example 1: Simple Reminder
```
Input: "Remember to update the documentation"
Output: Added to Daily/2024-11-11.md
         - **14:30** - Remember to update the documentation
```

### Example 2: Follow-up Task
```
Input: "Need to review the installation script changes"
Output: Added to Daily/2024-11-11.md
         - **15:45** - Need to review the installation script changes
```

### Example 3: Quick Idea
```
Input: "Add capture command to the skill"
Output: Added to Daily/2024-11-11.md
         - **16:20** - Add capture command to the skill
```
