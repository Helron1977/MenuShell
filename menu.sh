#!/bin/bash

# Function to check if a directory exists
check_directory_exists() {
    local directory="$1"
    if [ ! -d "$directory" ]; then
        xmessage -center "The directory $directory does not exist."
        return 1
    fi
}

# Function to read the configuration file and extract menu options
read_config_file() {
    local config_file="$1"
    local options=()
    while IFS=: read -r libelle action; do
        if [[ $libelle == \#* || -z $libelle ]]; then
            continue
        fi
        options+=("$libelle:$action")
    done < "$config_file"
    local joined_options
    joined_options=$(printf "%s\n" "${options[@]}")
    echo "$joined_options"
}

generate_menu_config() {
    local directory="$1"
    local parent_menu_file="$2"
    local config_file="${directory##*/}.conf"
    check_directory_exists "$directory" || return 1
    echo "# Menu generated from subdirectories, .log and .zip files of $directory" > "$config_file"
    local subdirs
    subdirs=$(find "$directory" -mindepth 1 -type d)
    if [ -n "$subdirs" ]; then
        for subdir in $subdirs; do
            subdir=$(basename "$subdir")
            echo "List $subdir:List $directory/$subdir" >> "$config_file"
        done
    fi
    local files
    files=$(find "$directory" -maxdepth 1 -type f \( -name "*.log" -o -name "*.zip" \))
    for file in $files; do
        file=$(basename "$file")
        echo "Display $file:Display $directory/$file" >> "$config_file"
        echo "Edit $file:Edit $directory/$file" >> "$config_file"
    done
    echo "Return to previous menu:$parent_menu_file" >> "$config_file"
    echo "Set current directory as source:source=$directory" >> "$config_file"
    echo "Set current directory as target:target=$directory" >> "$config_file"
    echo "Copy files from source directory to target directory:cp \$source \$target" >> "$config_file"
}

# Function to display a message with xmessage and capture the user's response
show_message_with_buttons() {
    local prompt="$1"
    shift
    local button_labels=("$@")
    local buttons=""
    for (( index = 0; index < ${#button_labels[@]}; index++ )); do
        buttons+="$(($index + 1)):${button_labels[$index]},"
    done
    buttons+="X:Quit"
    response=$(xmessage -geometry +0+0 -buttons "$buttons" -print "$(printf "$prompt")")
    echo "$response"
}

# Function to handle arguments in an action
handle_arguments() {
    local action=$1
    # Extract all occurrences of '%' followed by a number
    local arg_indices=($(echo "$action" | grep -oP '%\d+' | grep -oP '\d+'))
    # Prompt the user to enter a value for each argument
    for index in "${arg_indices[@]}"; do
        read -p "Enter a value for argument $index: " arg_value
        # Replace the '%' followed by the index with the user's input
        action=${action//%$index/$arg_value}
    done
    echo "$action"
}

# Function to evaluate an action
eval_action() {
    local action=$1
    # Check if the action contains a '%' character
    if [[ $action == *"%"* ]]; then
        action=$(handle_arguments "$action")
    fi
    echo "Executing $action in terminal..."
    eval "$action"
    echo "========================================"
}



# Function to display the menu in xmessage
display_menu() {
    local menu_file="$1"
    local parent_menu_file="$2"
    local options_str
    options_str=$(read_config_file "$menu_file")
    IFS=$'\n' read -r -d '' -a options <<< "$options_str"
    local prompt=""
    local button_labels=()
    local entete_content=$(<entete.txt)
    for i in "${!options[@]}"; do
        IFS=: read -r libelle action <<< "${options[$i]}"
        prompt+="$((i+1)). $libelle\n"
        button_labels+=("$libelle")
    done
    prompt="$entete_content\n$prompt"
    local choice_index
    choice_index=$(show_message_with_buttons "$prompt" "${button_labels[@]}")
    if [[ -n "$choice_index" ]]; then
        if [[ "$choice_index" == "X" ]]; then
            exit
        fi
        local choice=$choice_index
        local selected_option="${options[$((choice-1))]}"
        IFS=: read -r libelle action <<< "$selected_option"
        case $action in
            "List "*)
                folder_to_list="${action#List }"
                config_file="${folder_to_list##*/}.conf"
                generate_menu_config "$folder_to_list" "$menu_file"
                display_menu "$config_file" "$menu_file"
                ;;
            "Display "*)
                file_to_display="${action#Display }"
                less "$file_to_display"
                display_menu "$menu_file" "$parent_menu_file"
                ;;
            "Edit "*)
                file_to_edit="${action#Edit }"
                vi "$file_to_edit"
                display_menu "$menu_file" "$parent_menu_file"
                ;;
            *.conf)
                display_menu "$action" "$menu_file"
                ;;
            *)
                eval_action "$action"
                display_menu "$menu_file" "$parent_menu_file"
                ;;
        esac
    else
        echo "Invalid option. Please enter a valid number."
    fi
}

# Start the script
clear
display_menu "menu.conf"
