# determine platform
ifeq (Boot2Docker, $(findstring Boot2Docker, $(shell docker info)))
  PLATFORM := OSX
else
  PLATFORM := Linux
endif

# map user and group from host to container
ifeq ($(PLATFORM), OSX)
  CONTAINER_USERNAME = root
  CONTAINER_GROUPNAME = root
  HOMEDIR = /root
  CREATE_USER_COMMAND =
  COMPOSER_CACHE_DIR = ~/tmp/composer
  BOWER_CACHE_DIR = ~/tmp/bower
else
  CONTAINER_USERNAME = dummy
  CONTAINER_GROUPNAME = dummy
  HOMEDIR = /home/$(CONTAINER_USERNAME)
  GROUP_ID = $(shell id -g)
  USER_ID = $(shell id -u)
  CREATE_USER_COMMAND = \
    groupadd -f -g $(GROUP_ID) $(CONTAINER_GROUPNAME) && \
    useradd -u $(USER_ID) -g $(CONTAINER_GROUPNAME) $(CONTAINER_USERNAME) && \
    mkdir --parent $(HOMEDIR) &&
  COMPOSER_CACHE_DIR = /var/tmp/composer
  BOWER_CACHE_DIR = /var/tmp/bower
endif

# map SSH identity from host to container
DOCKER_SSH_IDENTITY ?= ~/.ssh/id_rsa
DOCKER_SSH_KNOWN_HOSTS ?= ~/.ssh/known_hosts
ADD_SSH_ACCESS_COMMAND = \
  mkdir --parent $(HOMEDIR)/.ssh && \
  test -e /var/tmp/id && cp /var/tmp/id $(HOMEDIR)/.ssh/id_rsa ; \
  test -e /var/tmp/known_hosts && cp /var/tmp/known_hosts $(HOMEDIR)/.ssh/known_hosts ; \
  test -e $(HOMEDIR)/.ssh/id_rsa && chmod 600 $(HOMEDIR)/.ssh/id_rsa ;

# utility commands
AUTHORIZE_HOME_DIR_COMMAND = chown -R $(CONTAINER_USERNAME):$(CONTAINER_GROUPNAME) $(HOMEDIR) &&
EXECUTE_AS = sudo -u $(CONTAINER_USERNAME) HOME=/home/dummy 

# If the first argument is one of the supported commands...
SUPPORTED_COMMANDS := composer phpunit compass bower
SUPPORTS_MAKE_ARGS := $(findstring $(firstword $(MAKECMDGOALS)), $(SUPPORTED_COMMANDS))
ifneq "$(SUPPORTS_MAKE_ARGS)" ""
  # use the rest as arguments for the command
  COMMAND_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  # ...and turn them into do-nothing targets
  $(eval $(COMMAND_ARGS):;@:)
endif

composer:
	@mkdir --parent $(COMPOSER_CACHE_DIR)
	@docker run -ti -rm \
		-v `pwd`:/srv \
		-v $(COMPOSER_CACHE_DIR):$(HOMEDIR)/.composer \
		-v $(DOCKER_SSH_IDENTITY):/var/tmp/id \
		-v $(DOCKER_SSH_KNOWN_HOSTS):/var/tmp/known_hosts \
		marmelab/composer-hhvm bash -ci '\
			$(CREATE_USER_COMMAND) \
			$(ADD_SSH_ACCESS_COMMAND) \
			$(AUTHORIZE_HOME_DIR_COMMAND) \
			$(EXECUTE_AS) hhvm /usr/local/bin/composer $(COMMAND_ARGS)'

phpunit:
	@docker run -ti -rm \
		-v `pwd`:/srv \
		marmelab/phpunit-hhvm $(COMMAND_ARGS)

compass:
	@docker run -ti rm \
		-v `pwd`:/srv \
		marmelab/compass $(COMMAND_ARGS)

bower:
	@docker run -ti -rm \
		-v `pwd`:/srv \
		-v $(BOWER_CACHE_DIR):$(HOMEDIR)/.bower \
		-v $(DOCKER_SSH_IDENTITY):/var/tmp/id \
		-v $(DOCKER_SSH_KNOWN_HOSTS):/var/tmp/known_hosts \
		marmelab/bower bash -ci '\
			$(CREATE_USER_COMMAND) \
			$(ADD_SSH_ACCESS_COMMAND) \
			$(AUTHORIZE_HOME_DIR_COMMAND) \
			$(EXECUTE_AS) bower --allow-root \
			--config.interactive=false \
			--config.storage.cache=$(HOMEDIR)/.bower/cache \
			--config.storage.registry=$(HOMEDIR)/.bower/registry \
			--config.storage.empty=$(HOMEDIR)/.bower/empty \
			--config.storage.packages=$(HOMEDIR)/.bower/packages $(COMMAND_ARGS)'
