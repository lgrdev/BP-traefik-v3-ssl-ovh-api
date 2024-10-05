# Traefik v3 avec SSL et API OVH

Ce projet fournit une configuration de base pour déployer **Traefik v3** avec un support SSL via Let's Encrypt et l'intégration de l'API OVH pour la gestion des certificats DNS. Il inclut également l'utilisation de l'authentification basique via `htpasswd`.

## Arborescence des fichiers

Voici la structure des fichiers et dossiers du projet :

```
.
├── .htpasswd/             # Contient les fichiers d'authentification pour sécuriser l'accès
├── config/                # Fichiers de configuration de Traefik
│   ├── traefik.yaml       # Configuration statique de Traefik
│   └── dynamic.yaml       # Configuration dynamique (middlewares, routers, etc.)
├── letsencrypt/           # Contient le fichier acme.json pour les certificats SSL
├── secrets/               # Stocke les secrets pour l'API OVH
│   └── ovh*.secret        # Fichiers secrets contenant les clés pour l'API OVH
```

### Contenu des répertoires

- **`.htpasswd/`** : Ce répertoire contient les fichiers d'authentification générés par `htpasswd`, qui sont utilisés pour sécuriser l'accès à certaines routes dans Traefik (par exemple, l'accès au tableau de bord ou à des services sensibles).
  
- **`config/`** :
  - `traefik.yaml` : Fichier de configuration statique de Traefik où sont définies les options de base (API, points d'entrée, certificats SSL, etc.).
  - `dynamic.yaml` : Fichier de configuration dynamique pour les middlewares, routeurs, et autres règles spécifiques à appliquer lors de l'exécution de Traefik.
  
- **`letsencrypt/`** : Ce répertoire contient le fichier `acme.json` utilisé par Let's Encrypt pour gérer les certificats SSL. Veillez à restreindre les permissions d'accès à ce fichier pour des raisons de sécurité (`chmod 600 letsencrypt/acme.json`).

- **`secrets/`** : Ce répertoire contient les fichiers de secrets liés à l'API OVH, nécessaires pour l'intégration avec Let's Encrypt pour le défi DNS. Ces fichiers doivent être sécurisés et ne doivent pas être exposés publiquement.

## Prérequis

- **Accès à l'API OVH** : Vous devez créer une application OVH et obtenir les identifiants pour pouvoir gérer vos entrées DNS via l'API.
- **Docker** : Pour déployer votre infrastructure.

## Configuration

Exécuter le fichier setup.sh
```bash
bash setup.sh
```

### .env file

Remplissez le fichier .env avec votre nom de domaine et l'email propriétaire de celui-ci.
```bash
#############################################################
# This file is a template for the .env file that should be #

# domain name for the acme challenge (ex : sample.com)
ACME_DOMAIN_NAME=

# email for the acme challenge (ex : test@sample.com)
ACME_EMAIL=
```

### Secrets OVH

Les fichiers secrets dans le répertoire `secrets/` contiennent vos identifiants API OVH :

- **`ovh_application_key.secret`**
- **`ovh_application_secret.secret`**
- **`ovh_consumer_key.secret`**
- **`ovh_endpoint.secret`**
  
Ces fichiers sont utilisés par Traefik pour interagir avec l'API OVH et valider le défi DNS pour Let's Encrypt. Assurez-vous que ces fichiers sont sécurisés et non accessibles publiquement.

## Authentification avec htpasswd

Pour ajouter une protection par authentification de base sur certaines routes, vous devez générer un fichier `htpasswd` contenant les utilisateurs et mots de passe chiffrés. Utilisez la commande suivante pour générer un utilisateur :

```bash
htpasswd -c .htpasswd/users <username>
```

Ce fichier sera ensuite référencé dans la configuration dynamique de traefik pour ajouter une couche de sécurité supplémentaire.


### Traefik YAML Files

- **`traefik.yaml`** : Ce fichier contient la configuration statique de Traefik, y compris l'activation de l'API Traefik, les points d'entrée (ports HTTP et HTTPS), ainsi que la gestion des certificats SSL via Let's Encrypt.
- **`dynamic.yaml`** : Ce fichier gère la configuration dynamique des middlewares et routeurs, comme les listes blanches IP, les redirections HTTPS, et les règles d'authentification.

### Sécurisation des accès

Par défaut, les accès à mes différents sites privés sont sécurisés via une liste blanche d'adresse IP

#### Par liste blanche d'adresse IP

Modifier le fichier config/dynamic.yaml

pour les connexions HTTP ou HTTPS : exemple dashboard de traefik.
j'ai créé 2 listes blanches. 
1. **webSecureByIp** qui n'autorise que mon adresse ip fixe
2. **webSecureByIpLarge** qui autorise plusieurs adresses ip.
   
```yaml
    webSecureByIp:
      ipAllowList:
        sourceRange:
          - 127.0.0.1
# ajouter ici votre IP  - 1.1.1.1

    webSecureByIpLarge:
      ipAllowList:
        sourceRange:
          - 127.0.0.1
          - 192.168.0.1/24
# ajouter ici votre IP  - 1.1.1.1

```


pour les connexions TCP : exemple mariadb, postgresql, mongo, ..
```yaml
## TCP
# Accepts request from defined IP
tcp:
  middlewares:
    tcpSecureByIp:
      ipAllowList:
        sourceRange:
          - 127.0.0.1
# ajouter ici votre IP  - 1.1.1.1
# ajouter ici votre IP  - 1.1.1.1
```

#### Par Mot de passe

à utiliser si vous n'avez pas d'adresse IP fixe.

## modification du docker-compose.yaml

Par défaut, le dashboard traefik est sécurisé via une liste blanche d'IP.
en commantant et décommentant les lignes dans le docker-compose.yaml, il est possible de passer en basic auth.

```yaml
    labels:
      - 'traefik.enable=true'
      - 'traefik.docker.network=traefik_proxy'
      - 'traefik.http.routers.traefik.entrypoints=websecure'
# uncomment the following line to enable basic auth      
#      - "traefik.http.middlewares.traefik.basicauth.usersfile=.htpasswd/users"
# comment the following line to disable white list by IP
      - 'traefik.http.routers.traefik.middlewares=webSecureByIp@file'
      - 'traefik.http.routers.traefik.rule=Host(`traefik.${ACME_DOMAIN_NAME}`)'
      - 'traefik.http.routers.traefik.service=api@internal'
      - 'traefik.http.routers.traefik.tls.certresolver=lets-encrypt'
      - 'traefik.http.routers.traefik.tls.options=mintls12@file'
```

## Déploiement

Une fois tous les fichiers configurés, vous pouvez démarrer Traefik. Si vous utilisez Docker, assurez-vous que les volumes montés correspondent à la structure de votre projet et que les certificats et secrets sont bien pris en charge.

Exemple de commande Docker pour lancer Traefik :
```bash
docker compose up -d
```

## Ressources supplémentaires

- [Documentation officielle de Traefik v3](https://doc.traefik.io/traefik/)
- [API OVH](https://api.ovh.com/)

## Contribuer

Si vous souhaitez contribuer à ce projet, n'hésitez pas à proposer des modifications via des **pull requests** ou à ouvrir des **issues** pour signaler des bugs ou proposer des améliorations.

