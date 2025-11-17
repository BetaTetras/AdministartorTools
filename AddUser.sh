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
# Gestion d'erreur : L'utilsateur n'est pas en sudo
if [ "$EUID" -ne 0 ]; then
    echo "[#] Erreur : ce script dois être lancé en sudo !"
    exit 1
fi

# Gestion d'erreur : L'utilsateur n'entre pas le bon nombre de paramétre
if [ $# -ne 3 ]; then
    echo "[#] Erreur : Le nombre de paramétre a rentrée est 3:"
    echo "[?] Information : Utilisation = sudo ./NewUser *Nom* *Mot de passe* *0/1*"
    exit 1
fi

Nom="$1"
MDP="$2"
Sudo="$3"
Input=""

# Gestion d'erreur : L'utilsateur ne mes pas un nombre booléen pour le param des sudoeur 
if [ "$Sudo" != "0" ] && [ "$Sudo" != "1" ]; then
    echo "[#] Erreur : Le paramétre de sudoeur dois étre une valeur binaire (0 ou 1)"
    exit 1
fi

# Gestion d'erreur : L'utilsateur mes un nom deja utilisé
if cut -d: -f1 /etc/passwd | grep -q "^$Nom$"; then
    echo "[#] Erreur : l'utilisateur $Nom existe déja"
    exit 1
fi

#################### Affichage récapitulatif ####################
echo "-=-=-=- NewUser v1 -=-=-=-"
echo "Utilisateur : $Nom"
echo "Mot de passe : $MDP"
echo -n "Sudoeur : "
if [ "$Sudo" == "1" ]; then
    echo "Oui"
else
    echo "Non"
fi
echo
echo -n "Valider ? [Y/n] :"
# Gestion d'information : L'utilsateur n'a pas entrée de paramétre valide [Y ou n]
Input=$(input_verification)
if [ "$Input" == "n" ]; then
    exit 0
fi

echo "-=-=-=-=-=-=- -=-=-=-=-=-"
echo
#################### Scripting ####################
echo "##### Création de l'utilisateur #####"
useradd -m $Nom
echo "[!] Action : Création de l'utilisateur '$Nom' "

chpasswd <<< "$Nom:$MDP"
echo "[!] Action : Affectation du MDP '$MDP' a $Nom"

if [ "$Sudo" == "1" ]; then
    usermod -aG sudo "$Nom"
    echo "[!] Action : Sudoeur [ON]"
else
    echo "[!] Action : Sudoeur [OFF]"    
fi

echo
echo "##### Création des droit mariadb #####"
ID=$(id -u $Nom)
if [ "$Sudo" == "1" ]; then
    Sudo="OUI"
else
    Sudo="NON";
fi
mysql Sys_User -e "INSERT INTO Users (ID,Nom,MotDePasse,DateCreation,NombreDeConnection,Root) VALUES($ID,'$Nom','$MDP',CURRENT_DATE,0,'$Sudo');"
echo "[!] Action : Ajout de l'utilisateur dans la base sys"

mysql Sys_User -e "CREATE USER '$Nom'@'10.66.66.%' IDENTIFIED BY '$MDP';"
echo "[!] Action : Création de l'utilisateur"

echo -n "[?] information : Droit d'accés au base 'uni_%' : "
Input=$(input_verification)

if [ "$Sudo" != "OUI" ]; then
    mysql Sys_User -e "GRANT ALL PRIVILEGES ON \`${Nom}_%\`.* TO '$Nom'@'10.66.66.%';FLUSH PRIVILEGES;"
    if [ "$Input" == "Y" ]; then
        mysql Sys_User -e "GRANT ALL PRIVILEGES ON \`Uni_%\`.* TO '$Nom'@'10.66.66.%'; FLUSH PRIVILEGES;"
        echo "[!] Action : Droit sur les bases 'Uni_%'"
    else
        echo "[!] Action : Blocage des bases 'Uni_%'"
    fi
else
    mysql Sys_User -e "GRANT ALL PRIVILEGES ON *.* TO '$Nom'@'10.66.66.%' WITH GRANT OPTION;FLUSH PRIVILEGES;"
fi
mysql -e "CREATE DATABASE \`${Nom}_exemple\`;"
echo "[!] Action : Création de la base '${Nom}_exemple'"