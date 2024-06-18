#!/bin/bash

# Fonction pour vérifier l'existence d'un répertoire
check_directory_exists() {
    local directory="$1"
    if [ ! -d "$directory" ]; then
        xmessage -center "Le répertoire $directory n'existe pas."
        return 1
    fi
}

# Fonction pour lire le fichier de configuration et extraire les options de menu
read_config_file() {
    local config_file="$1"
    local options=()

    while IFS=: read -r libelle action; do
        if [[ $libelle == \#* || -z $libelle ]]; then
            continue
        fi
        options+=("$libelle:$action")
    done < "$config_file"

    # Joindre les options en une chaîne de caractères séparée par des nouvelles lignes
    local joined_options
    joined_options=$(printf "%s\n" "${options[@]}")

    echo "$joined_options"
}

# Fonction pour générer un fichier de configuration de menu à partir d'un répertoire
generate_menu_config() {
    local directory="$1"
    local parent_menu_file="$2"
    local config_file="${directory##*/}.conf"
    check_directory_exists "$directory" || return 1
    echo "# Menu généré à partir des sous-dossiers, fichiers .log et .zip de $directory" > "$config_file"

    # Check if there are any subdirectories
    if [ "$(find "$directory" -mindepth 1 -type d | wc -l)" -gt 0 ]; then
        for subdir in "$directory"/*/; do
            subdir=$(basename "$subdir")
            echo "Lister $subdir:Lister $directory/$subdir" >> "$config_file"
        done
    fi

    for file in "$directory"/*.{log,zip}; do
        if [ -f "$file" ]; then
            file=$(basename "$file")
            echo "Afficher $file:Afficher $directory/$file" >> "$config_file"
            echo "Editer $file:Editer $directory/$file" >> "$config_file"
        fi
    done

    if [ "$parent_menu_file" != "menu.conf" ]; then
        echo "Retour au menu précédent:$parent_menu_file" >> "$config_file"
    fi
    echo "Définir le répertoire actuel comme source:source=$directory" >> "$config_file"
    echo "Définir le répertoire actuel comme cible:cible=$directory" >> "$config_file"
    echo "Copier les fichiers du répertoire source vers le répertoire cible:cp \$source \$cible" >> "$config_file"
}

# Fonction pour afficher un message avec xmessage et capturer la réponse de l'utilisateur
show_message_with_buttons() {
    local prompt="$1"
    shift
    local button_labels=("$@")
    local buttons=""

    # Ajouter les boutons pour chaque option du menu
    for (( index = 0; index < ${#button_labels[@]}; index++ )); do
        buttons+="$(($index + 1)):${button_labels[$index]},"
    done

    # Ajouter explicitement le bouton "Quitter" avec l'indice approprié
    buttons+="X:Quitter"

    # Afficher le message avec xmessage en position (0, 0)
    response=$(xmessage -geometry +0+0 -buttons "$buttons" -print "$(printf "$prompt")")
    echo "$response"
}

# Fonction pour afficher le menu dans xmessage
display_menu() {
    local menu_file=$1
    local parent_menu_file=$2
    # Lire les options à partir du fichier de configuration
    local options_str
    options_str=$(read_config_file "$menu_file")
    # Convertir la chaîne d'options en tableau
    IFS=$'\n' read -r -d '' -a options <<< "$options_str"
    local prompt=""
    local button_labels=()
    # Lire le contenu du fichier entete.txt
    entete_content=$(<entete.txt)
    # Construire le prompt et les libellés de boutons pour chaque option du menu
    for i in "${!options[@]}"; do
        IFS=: read -r libelle action <<< "${options[$i]}"
        prompt+="$((i+1)). $libelle\n"
        button_labels+=("$libelle")
    done
    # Ajouter l'en-tête au prompt
    prompt="$entete_content\n$prompt"
    # Afficher le menu avec xmessage
    local choice_index
    choice_index=$(show_message_with_buttons "$prompt" "${button_labels[@]}")
    if [[ -n "$choice_index" ]]; then
        # Vérifier si l'utilisateur a choisi "Quitter" en appuyant sur 'q'
        if [[ "$choice_index" == "X" ]]; then
            exit
        fi
        local choice=$((choice_index))
        local selected_option="${options[$((choice-1))]}"
        IFS=: read -r libelle action <<< "$selected_option"
        handle_action "$action" "$menu_file" "$parent_menu_file"
    else
        echo "Option invalide. Veuillez entrer un numéro valide."
    fi
}

# Fonction pour gérer l'action sélectionnée
handle_action() {
    local action=$1
    local menu_file=$2
    local parent_menu_file=$3
    # Check if the action contains a '%' character
    if [[ $action == *"%"* ]]; then
        # Extract all occurrences of '%' followed by a number
        arg_indices=($(echo "$action" | grep -oP '%\d+' | grep -oP '\d+'))
        # Prompt the user to enter a value for each argument
        for index in "${arg_indices[@]}"; do
            read -p "Enter a value for argument $index: " arg_value
            # Replace the '%' followed by the index with the user's input
            action=${action//%$index/$arg_value}
        done
    fi
    case $action in
        "Lister "*)
            folder_to_list="${action#Lister }"
            config_file="${folder_to_list##*/}.conf"
            generate_menu_config "$folder_to_list" "$menu_file"
            display_menu "$config_file" "$menu_file"
            ;;
        "Afficher "*)
            file_to_display="${action#Afficher }"
            less "$file_to_display"
            display_menu "$menu_file" "$parent_menu_file"
            ;;
        "Editer "*)
            file_to_edit="${action#Editer }"
            vi "$file_to_edit"
            display_menu "$menu_file" "$parent_menu_file"
            ;;
        *.conf)
            display_menu "$action" "$menu_file"
            ;;
        *)
            echo "Exécution de $action dans le terminal..."
            eval "$action"
            echo "========================================"
            display_menu "$menu_file" "$parent_menu_file"
            ;;
    esac
}

# Exemple d'utilisation : afficher un menu à partir du fichier de configuration "menu.conf"
clear
display_menu "menu.conf"
