# MenuShell
## Utilisation
1. Créez un fichier de configuration `menu.conf` avec les options de menu souhaitées.
2. Exécutez le script Bash principal pour afficher le menu et naviguer à travers les options définies.

## Avantages
- **Simplicité** : Facile à mettre en place et à utiliser.
- **Dynamisme** : Génération automatique de menus en fonction de la structure des répertoires.
- **Personnalisation** : Possibilité de définir des actions spécifiques pour chaque option de menu.
- **Extensibilité** : Facile à étendre avec de nouvelles fonctionnalités ou ajouter des menus de scenarios de test.

## Inconvénients
- **Interface en ligne de commande** : Peut ne pas être intuitive pour les utilisateurs non techniques.
- **Dépendance au terminal** : Nécessite un terminal pour fonctionner, limitant son utilisation à des environnements en ligne de commande.

## Fonctionnalités deja prise en charge
- Navigation à travers des répertoires en utilisant un menu textuel.
- Génération dynamique de fichiers de configuration pour les sous-répertoires.
- Actions configurables pour chaque option de menu.
- Copie des répertoires source vers des répertoires cible.

## Améliorations Futures
- Interface utilisateur améliorée avec des outils tels que xdialog ou zenity pour une meilleure expérience visuelle.
- Intégration avec Wetty pour permettre l'accès au menu via un navigateur web.
- Possibilité d'étendre le code pour accepter des paramètres à passer à une commande action.

Ce projet offre une base solide pour un système de menu dynamique en Bash, capable de s'adapter à divers besoins d'administration et de gestion de fichiers.
