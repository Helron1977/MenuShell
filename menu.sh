#!/bin/bash
source ./utils.sh

# Function to display the menu in xmessage
display_menu() {
    local menu_file="$1"
    local parent_menu_file="$2"
    local options_str
    # Read the options from the menu configuration file
    options_str=$(read_config_file "$menu_file")
    # If there are no options, display a message and exit
    if [ -z "$options_str" ]; then
        echo "No options found in $menu_file"
        exit 1
    fi
    # Split the options string into an array of options
    IFS=$'\n' read -r -d '' -a options <<< "$options_str"
    local prompt=""
    local button_labels=()
    
    local entete_content=$(<entete.txt)
    # Add each option to the prompt and the button labels:action array
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
        elif [[ "$choice_index" == "A" ]]; then
                add_item_to_menu "$menu_file"
                display_menu "$menu_file"
        elif [[ "$choice_index" == "D" ]]; then
                delete_item_from_menu "$menu_file"
                display_menu "$menu_file"
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
