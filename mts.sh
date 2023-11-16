#!/bin/bash

keyboard="default"
timestamp=$(date +"%Y_%m_%d_%H_%M_%S")
text_content=""
content_dir="content_files"

# Create the content directory if it doesn't exist
mkdir -p "$content_dir"

# Processing command-line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --keyboard) keyboard="$2"; shift ;;
        --text) text_file="$2"; shift ;;
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

measure_typing_speed() {
    local start=$(date +%s.%N)
    local content_file="${content_dir}/${keyboard}_content_${timestamp}.txt"
    local summary_file="${content_dir}/summary.txt"

    read -p "Start typing and press Enter when finished: " typed_text
    local end=$(date +%s.%N)
    local duration=$(awk "BEGIN {print $end - $start}")

    echo "$typed_text" > "$content_file"
    echo "$content_file | ${duration}s" >> "$summary_file"

    echo "Typing time: $duration seconds."
    echo "Result saved in file: $content_file"
    echo "Summary saved in file: $summary_file"
}

measure_typing_speed

