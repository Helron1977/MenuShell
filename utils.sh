#!/bin/bash
# Utils.sh

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

# Function to generate menu config for subdirectories
generate_subdir_config() {
    local directory="$1"
    local config_file="$2"
    local subdirs
    subdirs=$(find "$directory" -mindepth 1 -type d)
    if [ -n "$subdirs" ]; then
        for subdir in $subdirs; do
            subdir=$(basename "$subdir")
            echo "List $subdir:List $directory/$subdir" >> "$config_file"
        done
    fi
}

# Function to handle files in a directory
handle_files() {
    local directory="$1"
    local config_file="$2"
    local files
    files=$(find "$directory" -maxdepth 1 -type f \( -name "*.log" -o -name "*.zip" \))
    for file in $files; do
        file=$(basename "$file")
        echo "Display $file:Display $directory/$file" >> "$config_file"
        echo "Edit $file:Edit $directory/$file" >> "$config_file"
    done
}

# Function to add common actions to the config file
add_common_actions() {
    local parent_menu_file="$1"
    local directory="$2"
    local config_file="$3"
    echo "Return to previous menu:$parent_menu_file" >> "$config_file"
    echo "Set current directory as source:source=$directory" >> "$config_file"
    echo "Set current directory as target:target=$directory" >> "$config_file"
    echo "Copy files from source directory to target directory:cp \$source \$target" >> "$config_file"
}

generate_menu_config() {
    local directory="$1"
    local parent_menu_file="$2"
    local config_file="${directory##*/}.conf"
    check_directory_exists "$directory" || return 1
    echo "# Menu generated from subdirectories, .log and .zip files of $directory" > "$config_file"
    generate_subdir_config "$directory" "$config_file"
    handle_files "$directory" "$config_file"
    add_common_actions "$parent_menu_file" "$directory" "$config_file"
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
    buttons+="A:Add,D:Delete,X:Quit"
 
    # Display the message with buttons and capture the user's response
    response=$(xmessage -geometry +0+0 -buttons "$buttons" -print "$(printf "$prompt")")
    echo "$response"
}

add_item_to_menu() {
    local menu_file="$1"
    local libelle=""
    local action=""
    local line_index=0
    local nb_head_comment_lines=0

    # count the head comment lines
    nb_head_comment_lines=$(count_head_comment_lines "$menu_file")

    # ask the user to enter the libelle and the action
    read -p "Enter the libelle: " libelle
    read -p "Enter the action: " action
    read -p "Enter the index: " line_index

    # adjust the line index to account for the head comment lines
    line_index=$((line_index + nb_head_comment_lines))

    # check if the index is valid
    if [ $line_index -gt $(wc -l < "$menu_file") ]; then
        echo "Invalid index"
        return 1
    else
        # add the new item to the menu file
        awk -v line_index="$line_index" -v libelle="$libelle" -v action="$action" '
            NR == line_index { print libelle ":" action }
            { print }
        ' "$menu_file" > temp && mv temp "$menu_file"

        # display the menu again
        echo "Updated menu:"
        cat "$menu_file"
    fi
}

delete_item_from_menu() {
    local menu_file="$1"
    local line_index=0
    local nb_head_comment_lines=0
    # count the head comment lines
    nb_head_comment_lines=$(count_head_comment_lines "$menu_file")
    # ask the user to enter the index
    read -p "Enter the index: " line_index
    # adjust the line index to account for the head comment lines
    line_index=$((line_index + nb_head_comment_lines))
    # check if the index is valid
    if [ $line_index -gt $(wc -l < "$menu_file") ]; then
        echo "Invalid index"
        return 1
    else
        # delete the item from the menu file
        sed -i "${line_index}d" "$menu_file"
        # display the menu again
        echo "Updated menu:"
        cat "$menu_file"
    fi
}



# Function to display a menu and handle user input
count_head_comment_lines() {
    local menu_file="$1"
    local nb_head_comment_lines=0

    # count the head comment lines
    while IFS= read -r line; do
        if [[ $line =~ ^#.* ]]; then
            ((nb_head_comment_lines++))
        else
            break
        fi
    done < "$menu_file"

    echo "$nb_head_comment_lines"
}


# Function to build button labels array from options
build_button_labels() {
    local options=("$@")
    local button_labels=()
    for i in "${!options[@]}"; do
        IFS=: read -r libelle action <<< "${options[$i]}"
        button_labels+=("$libelle")
    done
    echo "${button_labels[@]}"
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
