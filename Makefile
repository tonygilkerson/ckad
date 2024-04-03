NOW := $(shell echo "`date +%Y-%m-%d`")

#
# Display help
# 
define help_info
	@echo "\nUsage:\n"
	@echo ""
	@echo "  $$ make dev  - Start mkdocs dev sandbox"
	@echo "  $$ make pub  - Publish doc to Gighub pages"
	@echo ""
endef

help:
	$(call help_info)

dev:
	@source ".venv/bin/activate"; mkdocs serve


pub:
	mkdocs build --clean
	mkdocs gh-deploy

