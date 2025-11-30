#!/bin/bash
set -e

# Function to modify Docker files based on commands
modify_dockerfile() {
    local dockerfile="$1"
    local commands_file="$2"

    if [ ! -f "$dockerfile" ]; then
        echo "Error: Dockerfile $dockerfile not found."
        return 1
    fi

    if [ ! -f "$commands_file" ]; then
        echo "Error: Commands file $commands_file not found."
        return 1
    fi

    echo "Modifying $dockerfile using commands from $commands_file"

    # Create temporary file
    local temp_file=$(mktemp)
    cp "$dockerfile" "$temp_file"

    # Process each command in the commands file
    while IFS= read -r line || [ -n "$line" ]; do
        # Skip empty lines and comments
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue

        # Parse command format: ACTION:PATTERN:REPLACEMENT
        IFS=':' read -r action pattern replacement <<< "$line"

        echo "  Processing: $action for pattern '$pattern'"

        case "$action" in
            "REMOVE")
                # Remove lines matching pattern
                sed -i.bak "/${pattern}/d" "$temp_file"
                ;;
            "COMMENT")
                # Comment out lines matching pattern - simple single line
                sed -i.bak "s/^\(.*${pattern}.*\)$/# \1/" "$temp_file"
                ;;
            "COMMENT_BLOCK")
                # Comment out multi-line blocks - handle both pattern in RUN line and in preceding comments
                python3 << EOF
import re

# Read the file
with open("$temp_file", 'r') as f:
    lines = f.readlines()

# Find lines that match the pattern
pattern = r"$pattern"
result_lines = []
i = 0

while i < len(lines):
    line = lines[i].rstrip('\n')

    # Check if this line matches our pattern
    if re.search(pattern, line):
        # Found a match - determine if it's in a comment or RUN command

        if line.strip().startswith('#') or 'Install' in line:
            # Pattern is in a comment line, look for the next RUN command
            result_lines.append(lines[i])  # Keep the comment line as-is
            i += 1

            # Look forward for the next RUN command
            while i < len(lines):
                current_line = lines[i].rstrip('\n')

                if re.match(r'^[\\s]*RUN\\s', current_line):
                    # Found the RUN command - comment out the entire block
                    while i < len(lines):
                        run_line = lines[i].rstrip('\n')
                        if not run_line.startswith('#'):
                            result_lines.append('# ' + run_line + '\n')
                        else:
                            result_lines.append(lines[i])

                        # Stop if this line doesn't end with backslash (end of block)
                        if not run_line.rstrip().endswith('\\\\'):
                            break
                        i += 1
                    break
                else:
                    # Not a RUN command yet, keep looking
                    result_lines.append(lines[i])
                    i += 1
        else:
            # Pattern is in a RUN command - comment out from this line
            run_start = i

            # Look backwards to find the actual start of the RUN block
            for j in range(i-1, -1, -1):
                prev_line = lines[j].rstrip('\n')
                if re.match(r'^[\\s]*RUN\\s', prev_line):
                    run_start = j
                    break
                if not prev_line.rstrip().endswith('\\\\'):
                    break

            # Comment out the entire RUN block from start
            for j in range(run_start, len(lines)):
                current_line = lines[j].rstrip('\n')
                if not current_line.startswith('#'):
                    result_lines.append('# ' + current_line + '\n')
                else:
                    result_lines.append(lines[j])

                # Stop if this line doesn't end with backslash (end of block)
                if not current_line.rstrip().endswith('\\\\'):
                    i = j
                    break

        i += 1
    else:
        # Regular line, just copy it
        result_lines.append(lines[i])
        i += 1

# Write back to file
with open("$temp_file", 'w') as f:
    f.writelines(result_lines)
EOF
                ;;
            "ADD_AFTER")
                # Add replacement after line matching pattern
                sed -i.bak "/${pattern}/a\\
${replacement}" "$temp_file"
                ;;
            "ADD_BEFORE")
                # Add replacement before line matching pattern
                sed -i.bak "/${pattern}/i\\
${replacement}" "$temp_file"
                ;;
            "REPLACE")
                # Replace entire line matching pattern
                sed -i.bak "s/.*${pattern}.*/${replacement}/" "$temp_file"
                ;;
            *)
                echo "  Warning: Unknown action '$action', skipping"
                continue
                ;;
        esac

        # Remove backup file if it exists
        rm -f "${temp_file}.bak"

    done < "$commands_file"

    # Replace original file with modified version
    mv "$temp_file" "$dockerfile"
    echo "  Successfully modified $dockerfile"
}

# Main execution
if [ $# -lt 2 ]; then
    echo "Usage: $0 <dockerfile> <commands_file>"
    echo ""
    echo "Commands file format (one command per line):"
    echo "  REMOVE:pattern"
    echo "  COMMENT:pattern                 # Comments single lines matching pattern"
    echo "  COMMENT_BLOCK:pattern           # Comments multi-line blocks (use with caution!)"
    echo "  ADD_AFTER:pattern:new_line"
    echo "  ADD_BEFORE:pattern:new_line"
    echo "  REPLACE:pattern:new_line"
    echo ""
    echo "SAFETY RECOMMENDATIONS:"
    echo "  - Use specific patterns to avoid unintended modifications"
    echo "  - Test patterns on sample files before production use"
    echo "  - COMMENT_BLOCK affects entire multi-line commands - use sparingly"
    echo ""
    echo "Safe Examples:"
    echo "  COMMENT:apt-get install.*nuget              # Only nuget install lines"
    echo "  REPLACE:ARG NODE_VERSION=22.19.0:ARG NODE_VERSION=18.0.0  # Specific version"
    echo ""
    echo "Risky Examples (too broad):"
    echo "  COMMENT_BLOCK:RUN apt-get update            # Would affect ALL apt-get update commands!"
    exit 1
fi

modify_dockerfile "$1" "$2"
