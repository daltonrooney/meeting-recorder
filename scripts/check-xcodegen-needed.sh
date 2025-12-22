#!/bin/bash
# Check if XcodeGen needs to run
# Returns 0 (true) if XcodeGen needs to run, 1 (false) otherwise

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
    
    # Primary check: timestamp comparison
    # Note: git doesn't preserve modification times, so this may be unreliable in CI
    if [ "$project_yml" -nt "$pbxproj" ]; then
        echo "⚠️  project.yml is newer than Olive.xcodeproj - regeneration needed"
        return 0
    fi
    
    # Fallback check: hash-based validation
    # More reliable in CI environments where timestamps are unreliable
    # We hash project.yml and compare it to a stored hash in the xcodeproj
    # If the hash file doesn't exist or doesn't match, regenerate
    local hash_file="$xcodeproj/.project_yml_hash"
    local current_hash
    current_hash=$(shasum -a 256 "$project_yml" | cut -d' ' -f1)
    
    if [ -f "$hash_file" ]; then
        local stored_hash
        stored_hash=$(cat "$hash_file")
        if [ "$current_hash" != "$stored_hash" ]; then
            echo "⚠️  project.yml hash changed - regeneration needed"
            return 0
        fi
    else
        # Hash file doesn't exist - store current hash for future comparisons
        # Don't require regeneration if project is newer than yml
        if [ "$pbxproj" -nt "$project_yml" ]; then
            echo "$current_hash" > "$hash_file"
            echo "✓ Olive.xcodeproj is up to date - stored hash for future validation"
            return 1
        else
            echo "⚠️  Hash file missing and timestamps inconclusive - regeneration needed"
            return 0
        fi
    fi
    
    echo "✓ Olive.xcodeproj is up to date - skipping regeneration"
    return 1
}

# If script is being executed (not sourced), run the check
if [ "${BASH_SOURCE[0]}" -ef "$0" ]; then
    should_regenerate_xcode_project
fi
