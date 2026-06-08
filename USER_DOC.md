# User documentation

This document explains how to use the Inception stack as an end user or
administrator.

## Services provided

- A WordPress website served over HTTPS at https://mlorenzo.42.fr
- A WordPress administration dashboard
- A MariaDB database (internal only), with persistent storage for the database
  and the website files

## Start and stop the project

From the root of the repository:

    make          build and start everything
    make down     stop and remove the containers
    make stop     pause the containers without removing them
    make start    start the paused containers again
    make status   show whether the containers are running

## Access the website and the admin panel

- Website: https://mlorenzo.42.fr
  The certificate is self-signed, so the browser shows a warning; accept it to
  continue.
- Administration panel: https://mlorenzo.42.fr/wp-admin
  Log in with the administrator account.
- The domain must resolve to the local machine. Make sure /etc/hosts contains:

    127.0.0.1 mlorenzo.42.fr

## Locate and manage credentials

Passwords are stored as Docker secrets, in the secrets folder at the root of the
repository. They are not committed to git; each file contains a single password:

    secrets/db_root_password.txt    MariaDB root password
    secrets/db_password.txt         WordPress database user password
    secrets/wp_admin_password.txt   WordPress admin account password
    secrets/wp_user_password.txt    WordPress second user password

The non-secret account information (the admin user name, the second user name,
the emails, the database name and user) is in srcs/.env.

The two WordPress accounts are:

- Administrator: user name set by WP_ADMIN_USER in srcs/.env (it does not
  contain "admin"). Use it to reach the dashboard.
- Second user: user name set by WP_USER in srcs/.env, a normal (non-admin)
  account that can write comments.

To change a password, edit the matching file in the secrets folder, then run
make re to rebuild with the new value.

## Check that the services are running

    make status

All three containers (mariadb, wordpress, nginx) should be Up, and mariadb
should show "healthy".

    make logs

Shows the live logs of every container.

To check the website answers over HTTPS:

    curl -k https://mlorenzo.42.fr

To confirm http is refused (only 443 is open):

    curl -I http://mlorenzo.42.fr

To confirm only TLS 1.2 and 1.3 are accepted:

    openssl s_client -connect mlorenzo.42.fr:443 -tls1_2   (should connect)
    openssl s_client -connect mlorenzo.42.fr:443 -tls1_1   (should fail)
