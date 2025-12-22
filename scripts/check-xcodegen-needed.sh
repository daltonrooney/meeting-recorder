#!/bin/bash
# Check if XcodeGen needs to run
# Returns 0 (true) if XcodeGen needs to run, 1 (false) otherwise

should_regenerate_xcode_project() {
    local project_yml="project.yml"
    local xcodeproj="Olive.xcodeproj"
    
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
    
    # Check if project.yml is newer than xcodeproj
    if [ "$project_yml" -nt "$xcodeproj/project.pbxproj" ]; then
        echo "⚠️  project.yml is newer than Olive.xcodeproj - regeneration needed"
        return 0
    fi
    
    echo "✓ Olive.xcodeproj is up to date - skipping regeneration"
    return 1
}

# If script is being executed (not sourced), run the check
if [ "${BASH_SOURCE[0]}" -ef "$0" ]; then
    should_regenerate_xcode_project
fi
