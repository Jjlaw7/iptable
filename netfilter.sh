#!/bin/bash
#FLUSH ALL
#bloque tout
iptables -F INPUT
iptables -F OUTPUT
iptables -F FORWARD     #gère les paquets qui traverse le systèmes
iptables -t nat -F PREROUTING #modif des paquets dès quil arrive sur linterface avant avant toute décision de routa
iptables -t nat -F POSTROUTING #modif avant qu'il quitte
                        #-F flush: vide les règles de la chaine
#post: source nat modifie laddress source d1 paquet dans le nat et destination modifie destina
#1.2 up looback #2.4 source nat #3.2pc internet par parefeu #4.2 ping dmz en http
#5.4.ok ping parefeu nimporte pou #6.1 uniq client ext se connect ssh vpn
#7. pc sur le web,ip, accès site en utilisant wan vpn, Dnat #8. client ex connect ssh 61337
iptables -t nat -A POSTROUTING -s resea_client/24 -o enp0s3 -j SNAT --to-source <ip_pc> #(2)
#INPUT
iptables -A INPUT -i lo -j ACCEPT #(1) Ajoute la règle i spécifie l'interface ou appliqué
# Autoriser le trafic entrant sur le port 80 (HTTP)
iptables -I INPUT -p tcp -m tcp --dport 80 -j ACCEPT
iptables -A INPUT -m conntrack --ctstate ESTABLISHED, RELATED -j ACCEPT #(2)
iptables -A INPUT -j ACCEPT -p icmp
iptables -A INPUT -p tcp -s 10.1.41.10 -i enpos3 --dport 22 -j ACCEPT #client externe (6)
iptables -A INPUT -j REJECT

#FORWARD
iptables -A FORWARD -m conntrack --ctstate ESTABLISHED, RELATED -j ACCEPT #(2)
iptables -A FORWARD -s 192.168.1.0/24 -i enp0s8 -o enp0s3 -j ACCEPT -p udp --dport 53 #(3) ou input
  #pareils tcp 443/80 (net_Reseau_Client) #(a)a ajouter i interfce entree j cible o sortie #(3)
iptables -A FORWARD -s reseau_cl/24 -d reseau_dmz/24 -i enp0s8 -o enp0s8 -j ACCEPT -p tcp --match$#(4)
iptables -A FORWARD -i enp0s3 -p tcp -d add_ip_dmz --dport 80 -j ACCEPT
$-match multiport --dport 21,80#(4)
iptables -A FORWARD -i enp0s3 -p tcp -d add_ip_dmz --dport 80 -j ACCEPT
iptables -A OUTPUT -j REJECT

#OUTPUT
iptables -A OUTPUT -o lo -j ACCEPT #(1)
iptables -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT #(2)
iptables -A OUTPUT -j REJECT

#nat
iptables -t nat -A POSTROUTING -s net_Reseau_Client/24 -o enp0s3 -j SNAT --to-source 10.1.41.11 #externe
iptables -t nat -l

#Dnat
iptables -t nat -A PREROUTING -p tcp --dst 10.1.41.11 --dport 80 -j DNAT --to-destination 172.16.0.$ #dmz(7)
  #redirection vers l'ip interne du serveur
iptables -t nat -A PREROUTING -p tcp --dst 10.1.41.11 --dport 61337 -j DNAT --to-destination 172.16$ #dmz (8)

$.16.0.10:80
iptables -t nat -A PREROUTING -p tcp --dst 10.1.41.11 --dport 61337 -j DNAT --to-destination 172.1#dmz

iptables -t nat -A PREROUTING -p tcp --dst 10.1.41.11 --dport 80 -j DNAT --to-destination 172.16.0
$172.16.0.10:22


#chat avancée
# Règles pour le seul client côté WAN pouvant se connecter en SSH et sur le serveur web utilisant le port 61337
iptables -A INPUT -p tcp -s <IP_client_WAN> --dport 61337 -j ACCEPT
iptables -A INPUT -p tcp -s <IP_client_WAN> --dport 22 -j ACCEPT
iptables -A INPUT -p tcp -s <IP_client_WAN> --dport 80 -j ACCEPT
# Autoriser le ping depuis le serveur web-ssh vers le pare-feu
iptables -A INPUT -p icmp --icmp-type echo-request -s <IP_serveur_web-ssh> -j ACCEPT
# Afficher le nombre de paquets liés à la navigation web sécurisée
iptables -nvL FORWARD | grep -E '(:443|:80)' | awk '{print $1 " paquets de navigation web sécurisée"}'
