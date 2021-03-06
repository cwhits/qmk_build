export ROOTDIR := $(shell pwd)
export PATH := /home/nickb/gcc-arm/gcc-arm-none-eabi-9-2019-q4-major/bin/:$(PATH)

BOARD_DEFS := \
	iris!tzarc-iris_rev4!keebio/iris/rev4/keymaps/tzarc!tzarc \
	ctrl!tzarc-ctrl!massdrop/ctrl/keymaps/tzarc!tzarc \
	luddite!tzarc-luddite!40percentclub/luddite/keymaps/tzarc!tzarc \
	mysterium-nick!tzarc-mysterium!coseyfannitutti/mysterium/keymaps/tzarc!tzarc \
	mysterium-dad!tzarc-mysterium-dad!coseyfannitutti/mysterium/keymaps/tzarc-dad!tzarc-dad \
	chocopad!tzarc-chocopad!keebio/chocopad/keymaps/tzarc!tzarc \
	cyclone!tzarc-cyclone!handwired/tzarc/cyclone!tzarc \
	onekey_l152!alternates/nucleo64_l152re!handwired/onekey/nucleo64_l152re!reset \
	onekey_g431!alternates/nucleo64_g431rb!handwired/onekey/nucleo64_g431rb!reset \
	onekey_g474!alternates/nucleo64_g474re!handwired/onekey/nucleo64_g474re!reset \
	onekey_l082!alternates/nucleo32_l082kz!handwired/onekey/nucleo32_l082!reset \
	split_l082!alternates/nucleo32_l082kz_split!handwired/splittest/nucleo32_l082!default \
	test_proton_c!alternates/proton_c_test!handwired/onekey/proton_c_test!reset \
	split_proton_c!alternates/proton_c_split!handwired/splittest/proton_c_split!default \
	split_g431!alternates/g431_split!handwired/splittest/g431_split!default \
	split_f411!alternates/f411_split!handwired/splittest/f411_split!default \
	spi_eeprom_promicro!alternates/spi_eeprom_test/promicro_test!handwired/onekey/spi_eeprom_test_promicro!eep_rst \
	spi_eeprom_proton_c!alternates/spi_eeprom_test/proton_c_test!handwired/onekey/spi_eeprom_test_proton_c!eep_rst \
	spi_eeprom_f103!alternates/spi_eeprom_test/f103_test!handwired/onekey/spi_eeprom_test_f103!eep_rst \
	spi_eeprom_f401!alternates/spi_eeprom_test/f401_test!handwired/onekey/spi_eeprom_test_f401!eep_rst \

EXTRA_LINK_DEFS := \
	layout-tkl_ansi-tzarc!layouts/community/tkl_ansi/tzarc \
	layout-60_ansi-tzarc!layouts/community/60_ansi/tzarc \
	users-tzarc!users/tzarc \

git-submodule: clean
	cd $(ROOTDIR)/qmk_firmware \
		&& git fetch --all --tags \
		&& git reset --hard origin/$(shell cd $(ROOTDIR)/qmk_firmware && git rev-parse --abbrev-ref HEAD)

all: bin

arm: cyclone onekey_l152 onekey_g431 onekey_g474 onekey_l082 split_l082

nick: cyclone iris luddite mysterium-nick chocopad ctrl

remove_artifacts:
	rm "$(ROOTDIR)"/*.bin "$(ROOTDIR)"/*.hex "$(ROOTDIR)"/*.dump "$(ROOTDIR)"/.clang-format >/dev/null 2>&1 || true

clean: remove_artifacts
	@$(MAKE) $(MAKEFLAGS) -C "$(ROOTDIR)/qmk_firmware" clean || true

distclean: remove_artifacts
	@$(MAKE) $(MAKEFLAGS) -C "$(ROOTDIR)/qmk_firmware" distclean || true

format_prereq:
	@ln -sf $(ROOTDIR)/qmk_firmware/.clang-format $(ROOTDIR)/.clang-format

format: format_prereq

links: format_prereq

define handle_link_entry
link_source_$1 := $$(word 1,$$(subst !, ,$1))
link_target_$1 := $$(word 2,$$(subst !, ,$1))
link_files_$1 := $$(shell find $$(ROOTDIR)/$$(link_source_$1) -type f \( -name '*.h' -or -name '*.c' \) -and -not -name '*conf.h' -and -not -name 'board.c' -and -not -name 'board.h' | sort)
link_files_all_$1 := $$(shell find $$(ROOTDIR)/$$(link_source_$1) -type f | sort)

links: link_$$(link_source_$1)
link_$$(link_source_$1):
	@if [ ! -L "$(ROOTDIR)/qmk_firmware/$$(link_target_$1)" ] ; then \
		echo "\e[38;5;14mSymlinking: $$(link_source_$1) -> $$(link_target_$1)\e[0m" ; \
		ln -sf $(ROOTDIR)/$$(link_source_$1) $(ROOTDIR)/qmk_firmware/$$(link_target_$1) ; \
	fi

clean: unlink_$$(link_source_$1)
distclean: unlink_$$(link_source_$1)
unlinks: unlink_$$(link_source_$1)
unlink_$$(link_source_$1):
	@if [ -L "$(ROOTDIR)/qmk_firmware/$$(link_target_$1)" ] ; then \
		echo "\e[38;5;14mRemoving symlink: $$(link_source_$1) -> $$(link_target_$1)\e[0m" ; \
		rm $(ROOTDIR)/qmk_firmware/$$(link_target_$1) ; \
	fi

format: format_$$(link_source_$1)
format_$$(link_source_$1): format_prereq
	@for file in $$(link_files_$1) ; do \
		echo "\e[38;5;14mclang-format'ing: $$$$file\e[0m" ; \
		clang-format-7 -i "$$$$file" >/dev/null 2>&1 ; \
	done ; \
	for file in $$(link_files_all_$1) ; do \
		dos2unix "$$$$file" >/dev/null 2>&1 ; \
	done

endef

$(foreach link_entry,$(EXTRA_LINK_DEFS),$(eval $(call handle_link_entry,$(link_entry))))

define handle_board_entry
board_name_$1 := $$(word 1,$$(subst !, ,$1))
board_source_$1 := $$(word 2,$$(subst !, ,$1))
board_target_$1 := $$(word 3,$$(subst !, ,$1))
board_keymap_$1 := $$(word 4,$$(subst !, ,$1))
board_qmk_$1 := $$(shell echo $$(board_target_$1) | sed -e 's@/keymaps/.*@@g')
board_file_$1 := $$(shell echo $$(board_qmk_$1) | sed -e 's@/@_@g' -e 's@:@_@g')
board_files_$1 := $$(shell find $$(ROOTDIR)/$$(board_source_$1) -type f \( -name '*.h' -or -name '*.c' \) -and -not -name '*conf.h' -and -not -name 'board.c' -and -not -name 'board.h' | sort)
board_files_all_$1 := $$(shell find $$(ROOTDIR)/$$(board_source_$1) -type f | sort)

bin_$$(board_name_$1): board_link_$$(board_name_$1) links
	@echo "\e[38;5;14mBuilding: $$(board_qmk_$1)\e[0m"
	$$(MAKE) $$(MAKEFLAGS) -C "$(ROOTDIR)/qmk_firmware" $$(board_qmk_$1):$$(board_keymap_$1)
	@cp $$(ROOTDIR)/qmk_firmware/$$(board_file_$1)* $$(ROOTDIR)

flash_$$(board_name_$1): bin_$$(board_name_$1)
	@echo "\e[38;5;14mFlashing: $$(board_qmk_$1)\e[0m"
	@$$(MAKE) -C "$(ROOTDIR)/qmk_firmware" $$(board_qmk_$1):$$(board_keymap_$1):flash

format_$$(board_name_$1): format_prereq
	@for file in $$(board_files_$1) ; do \
		echo "\e[38;5;14mclang-format'ing: $$$$file\e[0m" ; \
		clang-format-7 -i "$$$$file" >/dev/null 2>&1 ; \
	done
	@for file in $$(board_files_all_$1) ; do \
		dos2unix "$$$$file" >/dev/null 2>&1 ; \
	done

format: format_$$(board_name_$1)

$$(board_name_$1): bin_$$(board_name_$1)
bin: bin_$$(board_name_$1)

board_link_$$(board_name_$1):
	@if [ ! -L "$$(ROOTDIR)/qmk_firmware/keyboards/$$(board_target_$1)" ] ; then \
		echo "\e[38;5;14mSymlinking: $$(board_source_$1) -> $$(board_target_$1)\e[0m" ; \
		if [ ! -d "$$(shell dirname "$$(ROOTDIR)/qmk_firmware/keyboards/$$(board_target_$1)")" ] ; then \
			mkdir -p "$$(shell dirname "$$(ROOTDIR)/qmk_firmware/keyboards/$$(board_target_$1)")" ; \
		fi ; \
		ln -sf "$$(ROOTDIR)/$$(board_source_$1)" "$$(ROOTDIR)/qmk_firmware/keyboards/$$(board_target_$1)" ; \
	fi
	@touch $$(ROOTDIR)/qmk_firmware/keyboards/$$(board_target_$1)

board_unlink_$$(board_name_$1):
	@if [ -L "$$(ROOTDIR)/qmk_firmware/keyboards/$$(board_target_$1)" ] ; then \
		echo "\e[38;5;14mRemoving symlink: $$(board_target_$1)\e[0m" ; \
		rm "$$(ROOTDIR)/qmk_firmware/keyboards/$$(board_target_$1)" ; \
	fi

links: board_link_$$(board_name_$1)
unlinks: board_unlink_$$(board_name_$1)
clean: board_unlink_$$(board_name_$1)
distclean: board_unlink_$$(board_name_$1)
endef

$(foreach board_entry,$(BOARD_DEFS),$(eval $(call handle_board_entry,$(board_entry))))