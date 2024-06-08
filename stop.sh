#!/bin/bash

# Vider toutes les règles dans les tables filter, nat, mangle, et raw
iptables -F
iptables -t nat -F
iptables -t mangle -F
iptables -t raw -F

# Supprimer toutes les chaînes personnalisées dans les tables filter, nat, mangle, et raw
iptables -X
iptables -t nat -X
iptables -t mangle -X
iptables -t raw -X

# Réinitialiser les politiques par défaut sur ACCEPT
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT

# Si vous utilisez nftables, vider les règles nftables
