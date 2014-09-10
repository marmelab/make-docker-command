make-docker-command
===================

Seamlessly execute commands (composer, bower, compass) in isolation using docker and make.

```bash
# Install bower dependencies, without installing npm or bower locally
$ make bower install

# compile compass stylesheets, without installing ruby or compass locally
$ make compass build

# install composer dependencies faqster using HHVM, without installing HHVM locally
$ make composer install
```

make-docker-command doesn't change the syntax of your favorite commands: just prepend `make`, and the command runs in a docker container. It uses docker images hosted on Docker Hub, and generates files with the right user credentials.

make-docker-command currently supports the following dockerized commands:

* composer
* phpunit
* bower
* compass

**Tip**: For command invocations with an option (like `--prefer-source`), use `make --` instead of `make`:

```bash
$ make -- composer install --prefer-source
```

make-docker-command requires Docker 1.2, and works both on Linux and OSX.

## Sharing SSH Keys

Some commands may require SSH keys to connect to a secured repository (e.g. GitHub). make-docker-command will use the identity and hosts file declared in the `DOCKER_SSH_IDENTITY` and `DOCKER_SSH_KNOWN_HOSTS` environment variables (default to `~/.ssh/id_rsa` and `~/.ssh/known_hosts`).

If you don't want to enter a passphrase each time use these keys, create a new SSH key pair without passphrase and authorize it on GitHub:

```bash
$ cd ~/.ssh
$ mkdir docker_identity && cd docker_identity
$ ssh-keygen -t rsa -f id_rsa -N ''
$ ssh-keyscan -t rsa github.com > known_hosts
```

Then modify the environment variable to let `make-docker-command` use the new key:

```bash
$ export DOCKER_SSH_IDENTITY="~/.ssh/docker_identity/id_rsa"
$ export DOCKER_SSH_KNOWN_HOSTS="~/.ssh/docker_identity/known_hosts"
```

## Performance

Commands executed in a docker container run in about the same time on Linux. On OS X, commands with lots of disk I/Os are much slower when run inside a container. This is currently addressed by the Docker core team.

## Supported Commands

### composer

Install composer dependencies using the [marmelab/composer-hhvm](https://registry.hub.docker.com/u/marmelab/composer-hhvm/) docker image, running composer on HHVM (faster than PHP).

```bash
$ make composer install
```

The composer cache persists between runs. The `vendor` directory is created using the current user name and group. Private repositories are fetched using the SSH identity file. 

### phpunit

Run PHP unit tests using the [marmelab/phpunit-hhvm](https://registry.hub.docker.com/u/marmelab/phpunit-hhvm/) docker image, running phpunit on HHVM (faster than PHP).

```bash
$ make phpunit
```

### bower

Uses the [marmelab/bower](https://registry.hub.docker.com/u/marmelab/bower/) docker image, running bower on npm.

```bash
$ make bower install
```

The bower cache persists between runs. The `bower_components` directory is created using the current user name and group. Private repositories are fetched using the SSH identity file. 

### compass

Uses the [marmelab/compass](https://registry.hub.docker.com/u/marmelab/compass/) docker image, running bower on ruby.

```bash
$ make compass build
```

## Troubleshooting

### Not using sudo / root

The user executing `make command` must be a member of the `docker` group to avoid using sudo:

```bash
$ sudo groupadd docker
$ sudo gpasswd -a my_user docker
$ sudo service docker restart
```

### WARNING: No swap limit support

This warning shouldn't prevent the command from running, but the message means that your system needs an additional LXC configuration. See [the official Docker documentation](http://docs.docker.com/installation/ubuntulinux/#memory-and-swap-accounting) for the solution.

### Permission Problem For Executing HHVM

On hosts using AppArmor, docker containers can't execute commands as non-root, even if the executable bit is set for all. Try the following commands on the host:

```bash
$ apt-get install apparmor-utils
$ aa-complain /usr/bin/lxc-start
$ aa-complain /usr/bin/docker
```

### OS X

Docker on OS X is still rough in the edges, and you'll need [a custom version of boot2docker](https://medium.com/boot2docker-lightweight-linux-for-docker/boot2docker-together-with-virtualbox-guest-additions-da1e3ab2465c), allowing volume mounting, to get this working.

make-docker-command will only work when called from under the `/Users/` directory (because that's the only directory shered between the host and the VM).

## License

make-docker-command is available under the MIT license, courtesy of marmelab. 

Comments and pull requests are welcome.
