all: SoundMain.swf

FLEX_HOME=$(HOME)/lib/flex

SoundMain.swf: SoundMain.as
	@$(FLEX_HOME)/bin/mxmlc -static-link-runtime-shared-libraries \
				-swf-version=12 \
				-target-player=10.2.0 \
				-output=SoundMain.swf \
				SoundMain.as

setupflex:
	@wget http://fpdownload.adobe.com/pub/flex/sdk/builds/flex4.5/flex_sdk_4.5.0.20967_mpl.zip
	@unzip -d $(HOME)/lib/flex flex_sdk_4.5.0.20967_mpl.zip
	@rm flex_sdk_4.5.0.20967_mpl.zip

.PHONY: all setupflex
