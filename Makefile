
# TODO: use make's conditionals instead of sh's
# http://www.gnu.org/software/make/manual/html_node/Conditional-Syntax.html

VIM_BUNDLE := "vim" \
              "vimrc" \
              "gvimrc" \
              "vimpagerrc"

# Function to deploy config files. Takes 1 argument: name-of-bundle.
# It will loop through all bundle items and create symlinks according to.
# So, existed files and dirs will be overwritten with symlinks.

deploy = \
	@for item in $(1); do \
		if [ -e "${PWD}/$$item" ]; then \
			if [ -d "${PWD}/$$item" ]; then \
				if [ -d "${HOME}/.$$item" ]; then \
					cp -r "${PWD}/$$item/." "${HOME}/.$$item/"; \
				else \
					echo "BUG: never exec here !"; \
				fi; \
			elif [ -f "${PWD}/$$item" ]; then \
				if [ -f "${HOME}/.$$item" ]; then \
					rm -rf "${HOME}/.$$item"; \
					cp "${PWD}/$$item" "${HOME}/.$$item"; \
				else \
					cp "${PWD}/$$item" "${HOME}/.$$item"; \
				fi \
			else \
				echo "BUG: never exec here !"; \
			fi; \
		else \
			echo "$$item is NOT here !"; \
		fi; \
	done

# ln -Ffs "${PWD}/$$item" "${HOME}/.$$item"; \

# Confirmation prompt requires answer "yes" to continue.

reinstall:
	@while true; do \
		echo "It might hurt your feelings. Are you sure ot continue? (yes/no)"; \
		read answer; \
		if [ $$answer != "yes" ]; then \
			echo "Nothing was made. Bye."; \
			exit; \
		else \
			echo "REMOVE .vim, and INSTALL new vundle"; \
			if [ -d "${HOME}/.vim" ]; then \
				rm -rf "${HOME}/.vim"; \
			fi; \
			mkdir -p "${HOME}/.vim"; \
			$(MAKE) vimbundle; \
			rm -rf "${HOME}/.vim/bundle/vundle"; \
			git clone https://github.com/gmarik/vundle.git ~/.vim/bundle/vundle; \
			exit; \
		fi; \
		break; \
	done

install:
	@while true; do \
		echo "It might hurt your feelings. Are you sure ot continue? (yes/no)"; \
		read answer; \
		if [ $$answer != "yes" ]; then \
			echo "Nothing was made. Bye."; \
			exit; \
		else \
			echo "REMOVE .vim, and INSTALL new vundle"; \
			if [ -d "${HOME}/.vim" ]; then \
				rm -rf "${HOME}/.vim"; \
			fi; \
			mkdir -p "${HOME}/.vim"; \
			$(MAKE) vimbundle; \
			exit; \
		fi; \
		break; \
	done

# Install vim related config files.

vimbundle:
	$(call deploy,$(VIM_BUNDLE));
	@ echo "vim bundle installed!";

all:
	${MAKE} install;

.PHONY: all vim install reinstall

