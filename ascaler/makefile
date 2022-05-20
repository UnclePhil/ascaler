# import secret deploy config
# You can change the default deploy config with `make cnf="deploy_special.env" release`
# don't forget to put this file in .gitignore 
dck ?= ~/.pko_config/.docker/.docker
dckpw ?= ~/.pko_config/.docker/.dockerpw
include $(dck)
export $(shell sed 's/=.*//' $(dck))

# import deploy config
dpl ?= deploy.env
include $(dpl)
export $(shell sed 's/=.*//' $(dpl))

# get the version from the date/time
# VERSION=$(shell date '+%Y%m%d%H%M%S')
VERSION=$(shell date '+%Y%m%d%H%M')


# HELP
# This will output the help for each task
# thanks to https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
.PHONY: help

help: ## This help.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help


# DOCKER TASKS
# Build the containermake build
build: ## Build the container
	docker build --rm --force-rm  -t $(APP_NAME) .

build-nc: ## Build the container without caching
	docker build --no-cache --rm --force-rm  -t $(APP_NAME) .

# Run the container 
run: ## Run container on port configured in `deploy.env`
	docker run -i -t --rm -p=$(APP_PORT):$(APP_PORT) --name="$(APP_NAME)" $(APP_NAME)


up: build run ## Run container on port configured in `deploy.env` (Alias to run)

stop: ## Stop and remove a running container
	docker stop $(APP_NAME); docker rm $(APP_NAME)

release: build-nc publish ## Make a release by building and publishing the `{version}` ans `latest` tagged containers to ECR

# Docker publish
publish: repo-login publish-latest publish-version ## Publish the `{version}` ans `latest` tagged containers to ECR

publish-latest: tag-latest ## Publish the `latest` taged container to ECR
	@echo 'publish latest to $(DREPO)'
	docker push $(DREPO)/$(APP_NAME):latest

publish-version: tag-version ## Publish the `{version}` taged container to ECR
	@echo 'publish $(VERSION) to $(DREPO)'
	docker push $(DREPO)/$(APP_NAME):$(VERSION)

# Docker tagging
tag: tag-latest tag-version ## Generate container tags for the `{version}` ans `latest` tags

tag-latest: ## Generate container `{version}` tag
	@echo 'create tag latest'
	docker tag $(APP_NAME) $(DREPO)/$(APP_NAME):latest

tag-version: ## Generate container `latest` tag
	@echo 'create tag $(VERSION)'
	docker tag $(APP_NAME) $(DREPO)/$(APP_NAME):$(VERSION)



# login to docker hub
repo-login: 
	cat $(dckpw)| docker login -u $(DUSER) --password-stdin

version: ## Output the current version
	@echo $(VERSION)
	
