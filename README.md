# wppier/wp-tools

You should to tell `wp-tools` where to find it's environment variables and
additional wp-config settings.
```
ENV_FILE
CUSTOM_CONFIG_FILE
```
You can then mount the actual files using Docker Swarm Secrets, a shared volume
or other method of your choice.

## `ENV_FILE`
Defaults are loaded from `/usr/local/etc/defaults.env`

## `CUSTOM_CONFIG_FILE`
This file is included in wp-config right before WordPress is bootstrapped.
