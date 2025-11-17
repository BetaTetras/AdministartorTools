#!/bin/bash

input_verification(){
    local Input
    while true; do
        read Input
        if [ "$Input" == "Y" ] || [ "$Input" == "n" ]; then
            echo "$Input"
            return
        fi
        echo "[?] Information : Les choix acceptée ici est sois 'Y' sois 'n' (Attention a la case)"
    done
}

#################### Gestion d'erreur des paramétre ####################
if [ "$EUID" -ne 0 ]; then
    echo "[#] Erreur : ce script dois être lancé en sudo !"
    exit 1
fi

# Gestion d'erreur : L'utilsateur n'entre pas le bon nombre de paramétre
if [ $# -ne 1 ]; then
    echo "[#] Erreur : Le nombre de paramétre a rentrée est 3:"
    echo "[?] Information : Utilisation = sudo ./NewUser *Nom* *Mot de passe* *0/1*"
    exit 1
fi

Nom="$1"

if [ $(cut -d: -f1 /etc/passwd | grep -q "^$Nom$") == 0 ]; then
    echo "[#] Erreur : l'utilisateur $Nom n'existe pas"
    exit 1
fi

#################### Affichage récapitulatif ####################
echo "-=-=-=- DelUser v1 -=-=-=-"
echo "Utilisateur : $Nom"
echo 
echo -n "Etes-vous sur de vouloire suprimmer cette utilisateur [Y/n] :"
Input=$(input_verification)
if [ $Input == "n" ]; then
    exit 0
fi
echo "-=-=-=-=-=-=- -=-=-=-=-=-"
echo

#################### Scripting ####################
echo "##### Suppresion de l'utilisateur #####"

deluser --remove-home $Nom
echo "[!] Action : Supression de l'utilisateur '$Nom' "
echo "[!] Action : Supression du /home de l'utilisateur '$Nom' "

mysql Sys_User -e "DROP USER '$Nom'@'10.66.66.%';"
echo "[!] Action : Supression du compte mariadb de '$Nom' "

mysql Sys_User -e "DELETE FROM Users WHERE Nom='$Nom';"
echo "[!] Action : Supression de sa trace de '$Nom' dans la bd 'Sys_User'"

DBS=$(mysql -sN -e "SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME LIKE '${Nom}_%';")
echo
for db in $DBS; do
    echo "[!] Action : Supression de '$db' "
    mysql -e "DROP DATABASE \`$db\`;"
done
