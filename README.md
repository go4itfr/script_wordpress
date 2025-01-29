#Sur votre ordinateur de bureau - Copier le script vers votre serveur

rsync -avz -e "ssh -p votre_port_ouvert" ~/install_nomdufichier_script_wordpress.sh identifiant_VPS@IP_VPS:~/

#Localise que le fichier est bien la

ls -l ~/install_webpartner.sh

#Ajoute les permissions d'éxécution

sudo chmod +x ~/install_webpartner.sh

#Executer le script

sudo ./install_webpartner.sh



