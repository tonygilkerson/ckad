NOW := $(shell echo "`date +%Y-%m-%d`")

#
# Display help
# 
define help_info
	@echo "\nUsage:\n"
	@echo ""
	@echo ""
	@echo "  $$ make test                         - Run all KUTTL tests locally, this will create a kwok-cluster"
	@echo "  $$ make testCI                       - Run all KUTTL tests in CI, this assumes the kwok-cluster is already running as a CI service"
	@echo ""
endef

help:
	$(call help_info)

publish:
	mkdocs build --clean
	mkdocs gh-deploy

