VERSION=`git rev-parse --short HEAD`

.PHONY: help
help: ## - Show targets
	@printf "\033[32musage: make [target]\n\n\033[0m"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: build
build: ## - Build go-microepoch Docker image (this also updates staging image on docker registry if it is built on Travis)
	@printf "\033[32mBuild go-microepoch Docker image\n\033[0m"
	@bash kubeEnv.sh
	@docker build -f Dockerfile -t bitadvise.com/go-microepoch:$(VERSION) .
	@set -e; if [ "$$TRAVIS_BRANCH" = "staging" ]; then\
		docker tag bitadvise.com/go-microepoch:$(VERSION) bitadvise.com/go-microepoch:staging && docker push bitadvise.com/go-microepoch:staging;\
		kubectl config use-context staging;\
		kubectl get deployments;\
		kubectl patch deployment epoch-test -p \
  			"{\"spec\":{\"template\":{\"metadata\":{\"labels\":{\"date\":\"`date +'%s'`\"}}}}}";\
  		kubectl rollout status deployment epoch-test --timeout=15s;\
	fi

.PHONY: build-no-cache
build-no-cache: ## - Build go-microepoch Docker image with --no-cache option enabled
	@printf "\033[32mBuild go-microepoch Docker image with --no-cache\n\033[0m"
	@docker build --no-cache -f Dockerfile -t bitadvise.com/go-microepoch:$(VERSION) .
	
.PHONY: analyze
analyze: ## - Analyze with SonarQube
	@printf "\033[32mAnalyze with SonarQube\n\033[0m"
	@bash sonarEnv.sh
	@sonar-scanner -Dsonar.projectKey=omersiar_go-microepoch -Dsonar.organization=omersiar-github -Dsonar.sources=. -Dsonar.host.url=https://sonarcloud.io -Dsonar.login=$(SONAR_TOKEN) -Dsonar.branch.name=$(TRAVIS_BRANCH)

.PHONY: run
run: ## - Run go-microepoch and publish on TCP 8080 port (detached)
	@printf "\033[32mRun go-microepoch and publish on to TCP 8080 port\n\033[0m"
	@docker run -d -p 8080:8080 go-microepoch:latest
	
.PHONY: deploy
deploy: ## - Deploy image to bitadvise.com Registry and update K8s app image (Production)
	@printf "\033[32mDeploy image to bitadvise.com Registry and update K8s app image (Production)\n\033[0m"
	@docker push bitadvise.com/go-microepoch:$(VERSION)
	@kubectl config use-context production
	@kubectl get deployments
	@kubectl set image deployment epoch-live go-microepoch=bitadvise.com/go-microepoch:$(VERSION)
	@kubectl rollout status deployment epoch-live --timeout=15s
