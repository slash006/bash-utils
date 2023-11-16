#!/bin/bash

keyboard="default"
timestamp=$(date +"%Y_%m_%d_%H_%M_%S")
text_content=""
content_dir="content_files"
output_json="false"
json_file="${content_dir}/typing_results.json"

# Create the content directory if it doesn't exist
mkdir -p "$content_dir"

# Check if jq is installed
check_jq_installed() {
    if ! command -v jq &> /dev/null; then
        echo "jq is not installed. Would you like to install it now? (y/n)"
        read -r install_choice
        if [[ $install_choice == "y" ]]; then
            # Assuming a Debian/Ubuntu-based system
            sudo apt-get install jq
        fi
    fi
}

show_summary() {
    local text_fragment="$1"
    if [[ -z $text_fragment ]]; then
        # Show summary for all texts
        jq '.[] | .text as $text | .results | max_by(.speed | tonumber) | [$text, .keyboard, .speed]' "$json_file"
    else
        # Show summary for a specific text fragment
        jq --arg text_fragment "$text_fragment" '.[] | select(.text | contains($text_fragment)) | .text as $text | .results | max_by(.speed | tonumber) | [$text, .keyboard, .speed]' "$json_file"
    fi
}

# Processing command-line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --keyboard) keyboard="$2"; shift ;;
        --text) text_file="$2"; shift ;;
	--show-summary)
            show_summary "$2"
            exit 0
        ;;
        --output-result)
            if [[ $2 == "json" ]]; then
                output_json="true"
            fi
            shift
        ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

# Load the content of the text file if the --text parameter was provided
if [[ -n $text_file && -f $text_file ]]; then
    text_content=$(cat "$text_file")
    echo "Text to transcribe:"
    echo "$text_content"
fi

# Function to update JSON file with results
update_json_file() {
    echo "init update json file $json_file"
    local text=$1
    local keyboard=$2
    local speed=$3
    local timestamp=$4
    local temp_json=$(mktemp)

    # Check if the JSON file already exists, if not, create it
    if [[ ! -f $json_file ]]; then
        echo "[]" > "$json_file"
    fi

    # Check if the text already exists in the JSON file
    if jq -e --arg text "$text" '.[] | select(.text == $text)' "$json_file" > /dev/null; then
        # Update the existing entry
        jq --arg text "$text" --arg keyboard "$keyboard" --arg speed "$speed" --arg timestamp "$timestamp" '
            map(if .text == $text then .results += [{"keyboard": $keyboard, "speed": $speed, "timestamp": $timestamp}] else . end)
        ' "$json_file" > "$temp_json" && mv "$temp_json" "$json_file"
    else
        # Add a new entry
	      echo "adding new json entry"
        jq --arg text "$text" --arg keyboard "$keyboard" --arg speed "$speed" --arg timestamp "$timestamp" '
            . += [{"text": $text, "results": [{"keyboard": $keyboard, "speed": $speed, "timestamp": $timestamp}]}]
        ' "$json_file" > "$temp_json" && mv "$temp_json" "$json_file"
    fi
}


# Function to handle JSON output
handle_json_output() {
    echo "check if handle json"
    if [[ $output_json == "true" ]]; then
	      echo "handle json update!"
        update_json_file "$typed_text" "$keyboard" "$duration" "$timestamp"
    fi
}

# Main typing speed measurement function
measure_typing_speed() {
    local start=$(date +%s.%N)
    local content_file="${content_dir}/${keyboard}_content_${timestamp}.txt"
    local summary_file="${content_dir}/summary.txt"

    read -p "Start typing and press Enter when finished: " typed_text
    local end=$(date +%s.%N)
    local duration=$(awk "BEGIN {print $end - $start}")

    # Save the typed text and summary
    echo "$typed_text" > "$content_file"
    echo "$content_file | ${duration}s" >> "$summary_file"

    echo "Typing time: $duration seconds."
    echo "Result saved in file: $content_file"
    echo "Summary saved in file: $summary_file"

    # Handle JSON output
    handle_json_output
}

# Check if jq is installed before proceeding
check_jq_installed

# Run the typing speed measurement function
measure_typing_speed

