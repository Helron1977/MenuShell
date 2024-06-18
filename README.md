# MenuShell Script

This is a simple Bash script that generates a menu based on a configuration file and allows the user to perform various actions such as listing files, viewing logs, editing files, and copying files between directories.

## Usage

1. Clone the repository:

git clone https://github.com/Helron1977/MenuShell.git


2. Navigate to the repository directory:

cd bash-menu-script


3. Make the script executable:

chmod +x menu.sh


4. Run the script:

./menu.sh


## Configuration

The script reads a configuration file (`menu.conf` by default) to generate the menu options. The configuration file should have the following format:

Comment lines start with a '#' character
Each line represents a menu option and has the following format:
<Label>:<action> [%1] [%2]

The `<label>` is the text that will be displayed in the menu, and the `<action>` is the command that will be executed when the user selects the option.
Keyword in actions can be set.
Optionnal parameter can be add with a caracter %. a prompt will ask the user to type the param before the eval of the string

## Customization

You can customize the script by modifying the following files:

* `menu.sh`: the main script file
* `entete.txt`: the header text that is displayed at the top of the menu
* `menu.conf`: the default configuration file used to generate the menu options

## Contributing

Contributions are welcome! If you find any issues or have suggestions for improvements, please open an issue or submit a pull request.

## License

This project is licensed under the MIT License. See the `LICENSE` file for details.

