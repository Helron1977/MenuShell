#!/bin/bash


# Fonction pour vérifier l'existence d'un répertoire
check_directory_exists() {
    local directory="$1"
    if [ ! -d "$directory" ]; then
        echo "Le répertoire $directory n'existe pas."
        return 1
    fi
}


# Fonction pour lire le fichier de configuration et extraire les options de menu
read_config_file() {
    local config_file="$1"     # fichier de configuration passé en argument
    local options_ref=$2       # Nom de la variable passée en argument

    local line                 # Variable temporaire pour stocker chaque ligne du fichier

    # Boucle pour lire chaque ligne du fichier de configuration
    while IFS=: read -r line; do
        # Ignorer les lignes commençant par '#' (commentaires) et les lignes vides
        if [[ ${line:0:1} == '#' || -z $line ]]; then
            continue
        fi
        # Ajouter l'option lue (libelle:action) au tableau options
        eval "$options_ref+=(\"$line\")"
    done < "$config_file"       # Redirection de l'entrée standard depuis le fichier de configuration
}

generate_menu_config() {
    local directory="$1"                # Stocke le répertoire passé en argument
    local parent_menu_file="$2"         # Stocke le fichier de menu parent passé en argument
    local config_file="${directory##*/}.conf"  # Obtient le nom du fichier de configuration à partir du nom du répertoire

    # Vérifier si le répertoire existe
    check_directory_exists "$directory" || return 1

    # Créer le fichier de configuration du menu avec les sous-dossiers du répertoire spécifié
    echo "# Menu généré à partir des sous-dossiers de $directory" > "$config_file"
    for subdir in "$directory"/*/; do
        subdir=$(basename "$subdir")       # Obtient le nom du sous-dossier
        # Ajoute une entrée au fichier de configuration (Lister <nom_sous-dossier>:<chemin_complet_sous-dossier>)
        echo "Lister $subdir:Lister $directory/$subdir" >> "$config_file"
    done
    # Ajoute une entrée de retour au menu parent au fichier de configuration
    echo "Retour au menu précédent:$parent_menu_file" >> "$config_file"
    echo "Définir le répertoire actuel comme source:source=$directory" >> "$config_file"
    echo "Définir le répertoire actuel comme cible:cible=$directory" >> "$config_file"
    echo "Copier les fichiers du répertoire source vers le répertoire cible:cp \$source \$cible" >> "$config_file"
}

display_menu() {
    local menu_file=$1          # Stocke le nom du fichier de menu passé en argument
    local parent_menu_file=$2   # Stocke le nom du fichier de menu parent passé en argument

    declare -a options         # Déclare un tableau pour stocker les options de menu

    # Appel de la fonction pour lire le fichier de configuration et remplir le tableau options
    read_config_file "$menu_file" options

    local choice   # Stocke le choix de l'utilisateur

    # Boucle pour afficher le menu et gérer les choix de l'utilisateur
    while true; do
        # Affichage du menu
        echo -e "\e[47m\e[30m\e[1mEntrez le numéro de votre choix : \e[0m"
        for i in "${!options[@]}"; do
            IFS=: read -r libelle action <<< "${options[$i]}"  # Lit chaque ligne du tableau options (libelle:action)
            echo "$((i+1)). $libelle"                          # Affiche le libellé de l'option avec un numéro
        done

        # Demande à l'utilisateur de choisir une option
        echo -e "\nEntrez le numéro de votre choix :"
        read choice

        # Vérifie si le choix est valide et exécute l'action correspondante
        if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#options[@]} )); then
            selected_option="${options[$((choice-1))]}"   # Récupère l'option sélectionnée du tableau options
            IFS=: read -r libelle action <<< "$selected_option"  # Sépare le libellé et l'action de l'option sélectionnée
            case $action in
                "Lister "*)
                    folder_to_list="${action#Lister }"   # Obtient le chemin du dossier à lister à partir de l'action
                    # Génère un nouveau menu à partir du dossier à lister et affiche ce nouveau menu
                    generate_menu_config "$folder_to_list" "$menu_file"
                    display_menu "${folder_to_list##*/}.conf" "$menu_file"  # Affiche le menu généré
                    ;;

                *.conf)
                    display_menu "$action" "$menu_file"  # Affiche le menu spécifié par le fichier de configuration
                    ;;
                *)
                    eval "$action"   # Exécute l'action spécifiée (commande ou script)
                    ;;
            esac
        else
            echo "Option invalide. Veuillez entrer un numéro valide."
        fi
    done
}

# Exemple d'utilisation : afficher un menu à partir du fichier de configuration "menu.conf"
clear
display_menu "menu.conf"
