run:
	bundle exec main.rb

submodule:
	@read -p "Enter name of the data source(ex: matomo, decidim,...): " SOURCE_NAME; \
 	read -p "Enter SSH address of the git repository: " GIT_REPO; \
 	git submodule add --name $$SOURCE_NAME $$GIT_REPO cards/$$SOURCE_NAME/; \
	cp -r cards/template/* cards/$$SOURCE_NAME/;

update-modules:
	git submodule update --remote

reset-modules:
	git submodule update --init

verify-modules:
	ruby bin/verification_script.rb
