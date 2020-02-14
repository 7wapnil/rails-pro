branch := $(shell git rev-parse --abbrev-ref HEAD)

# Start standalone feature based on master branch
feature:
	git checkout master
	git pull origin master --rebase
	git checkout -b $(ARGS)

# Start feature based on epic(base) branch
# Usage: make epic-feature B=epic-feature-name new-feature
epic-feature:
	git fetch
	git checkout $B
	git pull origin $B --rebase
	git checkout -b $(ARGS)

# Local merge to develop branch
# Usage: make merge-to-develop
merge-to-develop:
	@$(eval current_branch := $(branch))
	git checkout develop
	git pull origin develop --rebase
	git merge --no-ff $(current_branch)
	git checkout $(current_branch)

merge-to-master:
	@echo
	@echo "Click 'Merge pull request' in GitHub UI"
	@echo

# Quickly commit something before checking out
# Usage: make commit-wip Codestyle fixes
commit-wip:
	git add .
	git commit -m WIP --message=$(ARGS)

# Creates branch for staging containing develop + current branch
staging!:
	git fetch
	git checkout -b staging-$(branch)
	git merge develop

# BASIC STUFF:

branch:
	git checkout $(ARGS) || git checkout -b $(ARGS)

stash:
	git stash save --keep-index --include-untracked

push:
	git push origin $(branch)

push!:
	git push --force origin $(branch)

pull:
	git pull origin $(branch)

master:
	git checkout master
