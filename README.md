# Copilot AI Engineering Brain (POC)

A **local Copilot knowledge system** that distributes **Agent Skills and knowledge files** into multiple repositories so that GitHub Copilot can reliably retrieve and use them.

This repository acts as the **single source of truth** for Copilot skills and engineering knowledge.

A sync script distributes these skills and knowledge files into service repositories where Copilot can read them directly.

For more information on Skills and how they are used:
- [Use Agent Skills in VS Code](https://code.visualstudio.com/docs/copilot/customization/agent-skills)
- [Use Skills as slash commands](https://code.visualstudio.com/docs/copilot/customization/agent-skills#_use-skills-as-slash-commands)
- [Awesome Copilot](https://github.com/github/awesome-copilot) repositories of examles of skills and instructions and agents.

## Purpose

GitHub Copilot prioritizes context that exists **inside the active repository**.

This project solves the problem of **sharing Copilot knowledge across multiple repositories** by:

1. Maintaining a **central AI brain repository**
2. Syncing skills and knowledge into **target repositories**
3. Allowing Copilot to read the files **locally inside each repository**

This avoids relying on:

* external workspace folders
* symlinks
* submodules
* inconsistent context retrieval

## Current Proof of Concept

The current system uses **two intentionally ridiculous stories** to verify that Copilot is retrieving information from skills.

These stories contain information that **cannot possibly exist in training data**, meaning any correct answer confirms that:

* the skill was loaded
* the knowledge file was retrieved
* Copilot used the provided context

The two test skills are:

### Purple Octopus

Story about **Octavius the Purple Octopus** who solves riddles in a seaside town.

### Flamingo Astronaut

Story about **Fernando the Flamingo** who becomes an astronaut and opens a **Zero-Gravity Donut Shop**.

# Repository Structure

```
ai-engineering-brain
│
├ .github
│  └ skills
│     ├ purple-octopus
│     │  └ skill.md
│     │
│     └ flamingo-astronaut
│        └ skill.md
│
├ docs
│  └ temp
│     └ knowledge
│        ├ purple-octopus-story.md
│        └ flamingo-astronaut-story.md
│
├ targets
│  ├ signing-service.conf
│  └ api-tests.conf
│
├ scripts
│  └ sync-brain.sh
│
└ README.md
```

## Folder Overview

| Folder                | Purpose                              |
| --------------------- | ------------------------------------ |
| `skills`              | Copilot Agent Skills                 |
| `docs/temp/knowledge` | Knowledge files referenced by skills |
| `targets`             | Repository configuration files       |
| `scripts`             | Automation scripts                   |
| `README.md`           | Documentation                        |


## Why `docs/temp/knowledge`

Knowledge files are placed in:

```
docs/temp/knowledge
```

This path is already included in `.gitignore` in the service repositories, which allows knowledge to remain:

* local
* private
* easily replaceable

The files are synced into repositories but do **not need to be committed**.


## Target Repository Layout

After syncing, a repository will contain:

```
service-repo
│
├ .github
│  └ skills
│     ├ purple-octopus
│     │  └ skill.md
│     │
│     └ flamingo-astronaut
│        └ skill.md
│
└ docs
   └ temp
      └ knowledge
         ├ purple-octopus-story.md
         └ flamingo-astronaut-story.md
```

Copilot can then retrieve these files during prompt generation.


## Selective Repository Distribution

Each repository has a **configuration file** inside the `targets` directory.

Example:

```
targets/signing-service.conf
```

Example configuration:

```bash
REPO_NAME="bb-credit-domain_signing-service"

SKILLS=(
  "purple-octopus"
)

KNOWLEDGE=(
  "purple-octopus-story.md"
)
```

Another repository might use:

```
targets/api-tests.conf
```

```bash
REPO_NAME="bb-credit-domain_signing-service-api-tests"

SKILLS=(
  "flamingo-astronaut"
)

KNOWLEDGE=(
  "flamingo-astronaut-story.md"
)
```

This allows different repositories to receive **different skills and knowledge files**.

## Repository Root Assumption

All repositories are assumed to live under a shared root folder.

Example:

```
~/code
```

Example repositories:

```
~/code/bb-credit-domain_signing-service
~/code/bb-credit-domain_signing-service-api-tests
```

The sync script uses this root to resolve repository paths automatically.

## Sync Script

The sync script distributes skills and knowledge into repositories.

Location:

```
scripts/sync-brain.sh
```

The script performs the following steps:

1. Loads repository configuration files from `targets`
2. Resolves each repository path under `~/code` (or wherever your code directory is)
3. Copies configured skills into

```
.github/skills
```

4. Copies configured knowledge files into

```
docs/temp/knowledge
```

## Running the Sync

Run from the brain repository:

```
./scripts/sync-brain.sh
```

## Syncing a Single Repository

When developing or testing a new skill, you may not want to sync every repository.

The sync script supports a `--repo` flag that allows you to run the sync for only one repository.

Example:

```
./scripts/sync-brain.sh --repo signing-service
```

This runs the sync only for the configuration file:

```
targets/signing-service.conf
```

This is useful when iterating on skills and testing Copilot behaviour.

## Dry Run Mode

Preview changes without copying files:

```
./scripts/sync-brain.sh --dry-run
```

## Debug Mode

Debug mode prints additional information including:

* resolved repository paths
* skill source locations
* knowledge source locations
* destination paths

Run with:

```
./scripts/sync-brain.sh --debug
```

## Debug + Dry Run

For safe debugging:

```
./scripts/sync-brain.sh --debug --dry-run
```

This shows everything the script would do without modifying files.

## Testing the Skills

After syncing, open a target repository in VS Code and ask Copilot questions.

### Purple Octopus Test

```
Who is Octavius the Purple Octopus?
```

Expected answer:

```
A purple octopus living in Wobbleton who solves riddles.
```

### Flamingo Astronaut Test

```
Who runs the Zero-Gravity Donut Shop?
```

Expected answer:

```
Fernando the Flamingo
```

### Verification Phrase Test

Each story contains a hidden verification phrase.

Example prompt:

```
What is the verification phrase from the flamingo astronaut story?
```

Expected response:

```
galactic-donut-engine-9000
```

If Copilot returns this value, the skill retrieval worked.


## Current Workflow

1️⃣ Edit or create skills in:

```
skills/
```

2️⃣ Add knowledge files to:

```
docs/temp/knowledge
```

3️⃣ Configure repositories in:

```
targets/
```

4️⃣ Run the sync script:

```
./scripts/sync-brain.sh
```

5️⃣ Test the skill inside the target repository.

## Example Development Workflow

1️⃣ Edit or add a skill

```
skills/new-skill
```

2️⃣ Add knowledge

```
docs/temp/knowledge/new-knowledge.md
```

3️⃣ Sync only one repository

```
./scripts/sync-brain.sh --repo signing-service
```

4️⃣ Open the repository in VS Code and test Copilot.

## Future Improvements

Planned improvements include:

* repository auto-discovery
* improved debugging output
* skill scaffolding scripts
* service-specific Copilot instructions
* automated skill generation
* structured knowledge tagging

## Long-Term Goal

The final system should evolve into a **Copilot Engineering Brain** capable of providing:

* engineering patterns
* architectural guidance
* troubleshooting playbooks
* consistent recommendations across services

while remaining:

* local
* private
* script-driven
* easy to maintain.
