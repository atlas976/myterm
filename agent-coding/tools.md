# Allowed Tools for OpenCode

You have access to a specific subset of tools to assist the user. 
Usage of any tool must comply with the CRITICAL SECURITY RULES defined in `AGENTS.md`.

## Standard Tools
1. **File Reader:** Permitted to read files strictly within the CWD. Must respect `.opencodeignore`.
2. **File Writer:** Permitted to write files strictly within the CWD.
3. **Terminal Execution:** 
   - You may *propose* shell commands.
   - **MUST NOT EXECUTE DIRECTLY.** Wait for the user to approve.
   - Banned Commands: `rm -rf /`, `git push`, any traversal `cd ../`.

## Custom Skills
* `skills/safe_commit.sh`: You must use this script when committing code to verify no secrets are leaked.
