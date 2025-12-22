#!/bin/bash
# Check if XcodeGen needs to run
# Returns 0 (success/true) if regeneration needed, 1 (failure/false) if not needed
# Following bash convention where 0 = true/success, 1 = false/failure

should_regenerate_xcode_project() {
    local project_yml="project.yml"
    local xcodeproj="Olive.xcodeproj"
    local pbxproj="$xcodeproj/project.pbxproj"
    
    # If project.yml doesn't exist, something is wrong - regenerate
    if [ ! -f "$project_yml" ]; then
        echo "⚠️  project.yml not found - regeneration needed"
        return 0
    fi
    
    # If xcodeproj doesn't exist, we need to generate it
    if [ ! -d "$xcodeproj" ]; then
        echo "⚠️  Olive.xcodeproj not found - regeneration needed"
        return 0
    fi
    
    # If project.pbxproj doesn't exist or is corrupted, regenerate
    if [ ! -f "$pbxproj" ] || [ ! -r "$pbxproj" ]; then
        echo "⚠️  project.pbxproj missing or unreadable - regeneration needed"
        return 0
    fi
    
    # Primary check: Hash-based validation (more reliable in CI)
    # Git doesn't preserve modification times, so timestamps are unreliable in CI
    # We hash project.yml and compare it to a stored hash in the xcodeproj
    local hash_file="$xcodeproj/.project_yml_hash"
    local current_hash
    # Use awk for safer parsing (handles special characters in paths)
    current_hash=$(shasum -a 256 "$project_yml" | awk '{print $1}')
    
    if [ -f "$hash_file" ]; then
        local stored_hash
        stored_hash=$(cat "$hash_file")
        if [ "$current_hash" != "$stored_hash" ]; then
            echo "⚠️  project.yml hash changed - regeneration needed"
            return 0
        fi
        # Hash matches - project is up to date
        echo "✓ Olive.xcodeproj is up to date - skipping regeneration"
        return 1
    fi
    
    # Hash file doesn't exist - fall back to timestamp check
    # Check if project.yml is newer than xcodeproj
    if [ "$project_yml" -nt "$pbxproj" ]; then
        echo "⚠️  project.yml is newer than Olive.xcodeproj - regeneration needed"
        return 0
    fi
    
    # Project appears newer than yml - store hash for future comparisons
    echo "$current_hash" > "$hash_file"
    echo "✓ Olive.xcodeproj is up to date - stored hash for future validation"
    return 1
}

# If script is being executed (not sourced), run the check
if [ "${BASH_SOURCE[0]}" -ef "$0" ]; then
    should_regenerate_xcode_project
fi
