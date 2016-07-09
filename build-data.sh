#!/bin/bash

SRC=webapp
DEST=dist
#UI5_VERSION=1.34.12
UI5_VERSION=1.36.15
UI5_TARBALL=openui5-runtime-$UI5_VERSION.zip
UI5_URL=https://openui5.hana.ondemand.com/downloads/$UI5_TARBALL

function process_file {
	if [[ $1 != "Gruntfile.js" ]] && [[ $1 != *".git"* ]]  && [[ $1 != *"-dbg."* ]] && [[ $1 != *"-preload."* ]];
	then
		EXTENSION="${1##*.}"
		TARGET=${1/$SRC/$DEST}
		TARGETDIR=$(dirname "$TARGET")
		mkdir -p $TARGETDIR
		case $EXTENSION in
			js)
				NAME=${TARGET##*/}
				BASE=${NAME%.$EXTENSION}
				DEBUG=${TARGET/./-dbg.}
				echo Copying $1 to $DEBUG
				cp -R $1 $DEBUG
				echo Minifying $DEBUG TO $TARGET
				uglifyjs $DEBUG > $TARGET
				;;
			css)
				NAME=${TARGET##*/}
				BASE=${NAME%.$EXTENSION}
				DEBUG=${TARGET/./-dbg.}
				echo Copying $1 to $DEBUG
				cp -R $1 $DEBUG
				echo Minifying $DEBUG TO $TARGET
				uglifycss $DEBUG > $TARGET
				;;
			xml)
				NAME=${TARGET##*/}
				BASE=${NAME%.$EXTENSION}
				DEBUG=${TARGET/./-dbg.}
				echo Copying $1 to $DEBUG
				cp -R $1 $DEBUG
				echo Minifying $DEBUG TO $TARGET
				pretty -t xml -m $DEBUG > $TARGET
				;;
			json)
				NAME=${TARGET##*/}
				BASE=${NAME%.$EXTENSION}
				DEBUG=${TARGET/./-dbg.}
				echo Copying $1 to $DEBUG
				cp -R $1 $DEBUG
				echo Minifying $DEBUG TO $TARGET
				pretty -t json -m $DEBUG > $TARGET
				;;
			html)
				NAME=${TARGET##*/}
				BASE=${NAME%.$EXTENSION}
				DEBUG=${TARGET/./-dbg.}
				echo Copying $1 to $DEBUG
				cp -R $1 $DEBUG
				echo Minifying $DEBUG TO $TARGET
				html-minifier --minify-js --minify-css --collapse-whitespace --remove-comments $DEBUG > $TARGET
				;;
			*)
				echo Copying: $1
				cp $1 $TARGET
				;;
		esac
	fi
}

function add_comp_module(){
	echo -n '		"'$1'": ' >> $TARGET
	cat $2 | python -c 'import json,sys; sys.stdout.write(json.dumps(sys.stdin.read()))' >> $TARGET
	echo ',' >> $TARGET
}

function add_comp_lastmodule() {
	echo -n '		"'$1'": ' >> $TARGET
	cat $2 | python -c 'import json,sys; sys.stdout.write(json.dumps(sys.stdin.read()))' >> $TARGET
	echo >> $TARGET
}

function add_module(){
	echo -n '"'$1'":' >> $2
	EXTENSION="${1##*.}"
	case $EXTENSION in
		js)
			uglifyjs $DEST/openui5/resources/$1 | python -c 'import json,sys; sys.stdout.write(json.dumps(sys.stdin.read()))' >> $2
			;;
		*)
			cat $DEST/openui5/resources/$1 | python -c 'import json,sys; sys.stdout.write(json.dumps(sys.stdin.read()))' >> $2
			;;
	esac
	echo ',' >> $2
}

function add_lastmodule(){
	echo -n '"'$1'":' >> $2
	EXTENSION="${1##*.}"
	case $EXTENSION in
		js)
			uglifyjs $DEST/openui5/resources/$1 | python -c 'import json,sys; sys.stdout.write(json.dumps(sys.stdin.read()))' >> $2
			;;
		*)
			cat $DEST/openui5/resources/$1 | python -c 'import json,sys; sys.stdout.write(json.dumps(sys.stdin.read()))' >> $2
			;;
	esac
	echo >> $2
}

function build_component {
	TARGET=$DEST/Component-preload.js
	echo Constructing $TARGET
	echo 'jQuery.sap.registerPreloadedModules({' > $TARGET
	echo '	"version": "2.0",' >> $TARGET
	echo '	"name": "nl/sita/salesexcellence/visitreports/Component-preload",' >> $TARGET
	echo '	"modules": {' >> $TARGET
	add_comp_module "com/penninkhof/espui/controller/App.controller.js" $SRC/"controller/App.controller.js"
	add_comp_module "com/penninkhof/espui/controller/BaseController.js" $SRC/"controller/BaseController.js"
	add_comp_module "com/penninkhof/espui/controller/Configuration.controller.js" $SRC/"controller/Configuration.controller.js"
	add_comp_module "com/penninkhof/espui/controller/Diagnostics.controller.js" $SRC/"controller/Diagnostics.controller.js"
	add_comp_module "com/penninkhof/espui/controller/Main.controller.js" $SRC/"controller/Main.controller.js"
	add_comp_module "com/penninkhof/espui/view/App.view.xml" $SRC/"view/App.view.xml"
	add_comp_module "com/penninkhof/espui/view/Configuration.view.xml" $SRC/"view/Configuration.view.xml"
	add_comp_module "com/penninkhof/espui/view/Diagnostics.view.xml" $SRC/"view/Diagnostics.view.xml"
	add_comp_module "com/penninkhof/espui/view/Main.view.xml" $SRC/"view/Main.view.xml"
	add_comp_module "com/penninkhof/espui/model/models.js" $SRC/"model/models.js"
	add_comp_lastmodule "com/penninkhof/espui/Component.js" $SRC/"Component.js"
	echo '	}' >> $TARGET
	echo '});' >> $TARGET
}

function build_data {
	echo Constructing SPIFFS file system
	rm -rf data/ui5
	rm -rf data/www
	mkdir -p data/ui5/c
	mkdir -p data/ui5/l
	mkdir -p data/ui5/m
	mkdir -p data/www/css
	mkdir -p data/www/i18n
	mkdir -p data/www/data
	mkdir -p data/www/images
	cp $DEST/resources/sap-ui-core.js 												data/ui5
	cp $DEST/resources/sap-ui-version.json 											data/ui5
	cp $DEST/resources/sap/ui/thirdparty/jquery-mobile-custom.js 					data/ui5
	cp $DEST/resources/sap/ui/core/library-preload.json 							data/ui5/c
	cp $DEST/resources/sap/ui/core/themes/sap_bluecrystal/library.css				data/ui5/c
	cp $DEST/resources/sap/ui/core/themes/sap_bluecrystal/library-parameters.json	data/ui5/c
	cp $DEST/resources/sap/m/library-preload.json 									data/ui5/m
	cp $DEST/resources/sap/m/themes/sap_bluecrystal/library.css						data/ui5/m
	cp $DEST/resources/sap/m/themes/sap_bluecrystal/library-parameters.json			data/ui5/m
	cp $DEST/resources/sap/ui/layout/library-preload.json 							data/ui5/l
	cp $DEST/resources/sap/ui/layout/themes/sap_bluecrystal/library.css				data/ui5/l
	cp $DEST/resources/sap/ui/layout/themes/sap_bluecrystal/library-parameters.json	data/ui5/l
	cp $DEST/resources/sap/ui/layout/library.js										data/ui5/l
	cp $DEST/resources/sap/ui/core/themes/base/fonts/SAP-icons.ttf					data/ui5/c
	cp $DEST/css/style.css				 											data/www/css
	cp $DEST/Component-preload.js 													data/www
	cp $DEST/manifest.json		 													data/www
	cp $DEST/i18n/i18n.properties													data/www/i18n
	cp $DEST/data/app.json															data/www/data
	cp $DEST/images/*																data/www/images
	cat $DEST/index.html | sed 's/src="..\/..\/resources\/sap-ui-core.js"/src="https:\/\/openui5.hana.ondemand.com\/resources\/sap-ui-core.js"/' >> data/www/index_sta.html
	cat $DEST/index.html | sed 's/src="..\/..\/resources\/sap-ui-core.js"/src="resources\/sap-ui-core.js"/' >> data/www/index_ap.html
	cp data/www/index_ap.html data/www/index.html
}

function build_ui5 {

	echo Constructing Mini-UI5
	rm -rf $DEST/resources
	mkdir -p $DEST/resources/sap/ui/thirdparty
	mkdir -p $DEST/resources/sap/ui/core
	mkdir -p $DEST/resources/sap/m
	mkdir -p $DEST/resources/sap/ui/layout
	mkdir -p $DEST/resources/sap/ui/core/themes/sap_bluecrystal
	mkdir -p $DEST/resources/sap/ui/layout/themes/sap_bluecrystal
	mkdir -p $DEST/resources/sap/m/themes/sap_bluecrystal
	mkdir -p $DEST/resources/sap/ui/core/themes/base/fonts
	uglifyjs $DEST/openui5/resources/sap-ui-core.js > $DEST/resources/sap-ui-core.js
	uglifyjs $DEST/openui5/resources/sap/ui/thirdparty/jquery-mobile-custom.js > $DEST/resources/sap/ui/thirdparty/jquery-mobile-custom.js
	cp $DEST/openui5/resources/sap-ui-version.json $DEST/resources
	uglifyjs $DEST/openui5/resources/sap/ui/layout/library.js > $DEST/resources/sap/ui/layout/library.js
	uglifyjs $DEST/openui5/resources/sap/ui/core/library.js > $DEST/resources/sap/ui/core/library.js
	uglifyjs $DEST/openui5/resources/sap/m/library.js > $DEST/resources/sap/m/library.js
	cp $DEST/openui5/resources/sap/ui/core/themes/sap_bluecrystal/library.css $DEST/resources/sap/ui/core/themes/sap_bluecrystal
	cp $DEST/openui5/resources/sap/m/themes/sap_bluecrystal/library.css $DEST/resources/sap/m/themes/sap_bluecrystal
	cp $DEST/openui5/resources/sap/ui/core/themes/sap_bluecrystal/library-parameters.json $DEST/resources/sap/ui/core/themes/sap_bluecrystal
	cp $DEST/openui5/resources/sap/m/themes/sap_bluecrystal/library-parameters.json $DEST/resources/sap/m/themes/sap_bluecrystal
	cp $DEST/openui5/resources/sap/ui/layout/themes/sap_bluecrystal/library.css $DEST/resources/sap/ui/layout/themes/sap_bluecrystal
	cp $DEST/openui5/resources/sap/ui/layout/themes/sap_bluecrystal/library-parameters.json $DEST/resources/sap/ui/layout/themes/sap_bluecrystal
	cp $DEST/openui5/resources/sap/ui/core/themes/base/fonts/SAP-icons.ttf $DEST/resources/sap/ui/core/themes/base/fonts

	echo Constructing $DEST/resources/sap/m/library-preload.json
	echo '{"version":"2.0",' > $DEST/resources/sap/m/library-preload.json
	echo '"name":"sap.m.library-preload",' >> $DEST/resources/sap/m/library-preload.json
	echo '"dependencies":["sap.ui.core.library-preload"],' >> $DEST/resources/sap/m/library-preload.json
	echo '"modules":{' >> $DEST/resources/sap/m/library-preload.json
	add_module sap/m/library.js $DEST/resources/sap/m/library-preload.json
	add_module sap/m/Support.js $DEST/resources/sap/m/library-preload.json
	add_module sap/m/Shell.js $DEST/resources/sap/m/library-preload.json
	add_module sap/m/ShellRenderer.js $DEST/resources/sap/m/library-preload.json
	add_module sap/m/messagebundle_nl.properties $DEST/resources/sap/m/library-preload.json
	add_module sap/m/routing/Router.js $DEST/resources/sap/m/library-preload.json
	add_module sap/m/routing/TargetHandler.js $DEST/resources/sap/m/library-preload.json
	add_module sap/m/InstanceManager.js $DEST/resources/sap/m/library-preload.json
	add_module sap/m/NavContainer.js $DEST/resources/sap/m/library-preload.json
	add_module sap/m/SplitContainer.js $DEST/resources/sap/m/library-preload.json
	add_module sap/m/semantic/SemanticPage.js $DEST/resources/sap/m/library-preload.json
	add_module sap/m/semantic/SegmentedContainer.js $DEST/resources/sap/m/library-preload.json
	add_module sap/m/semantic/Segment.js $DEST/resources/sap/m/library-preload.json
	add_module sap/m/semantic/SemanticConfiguration.js $DEST/resources/sap/m/library-preload.json
	add_module sap/m/OverflowToolbarLayoutData.js $DEST/resources/sap/m/library-preload.json
	add_module sap/m/ToolbarLayoutData.js $DEST/resources/sap/m/library-preload.json
	add_module sap/m/Button.js $DEST/resources/sap/m/library-preload.json
	add_module sap/m/Title.js $DEST/resources/sap/m/library-preload.json
	add_module sap/m/ActionSheet.js $DEST/resources/sap/m/library-preload.json
	add_module sap/m/Dialog.js $DEST/resources/sap/m/library-preload.json
	add_module sap/m/Bar.js $DEST/resources/sap/m/library-preload.json
	add_module sap/m/BarInPageEnabler.js $DEST/resources/sap/m/library-preload.json
	add_module sap/m/OverflowToolbar.js $DEST/resources/sap/m/library-preload.json
	add_module sap/m/ToggleButton.js $DEST/resources/sap/m/library-preload.json
	add_module sap/m/Toolbar.js $DEST/resources/sap/m/library-preload.json
	add_module sap/m/ToolbarSpacer.js $DEST/resources/sap/m/library-preload.json
	add_module sap/m/OverflowToolbarAssociativePopover.js $DEST/resources/sap/m/library-preload.json
	add_module sap/m/Popover.js $DEST/resources/sap/m/library-preload.json
	add_module sap/m/PopoverRenderer.js $DEST/resources/sap/m/library-preload.json
	add_module sap/m/OverflowToolbarAssociativePopoverControls.js $DEST/resources/sap/m/library-preload.json
	add_module sap/m/SearchField.js $DEST/resources/sap/m/library-preload.json
	add_module sap/m/Page.js $DEST/resources/sap/m/library-preload.json
	add_module sap/m/OverflowToolbarButton.js $DEST/resources/sap/m/library-preload.json
	add_module sap/m/ButtonRenderer.js $DEST/resources/sap/m/library-preload.json
	add_module sap/m/routing/Targets.js $DEST/resources/sap/m/library-preload.json
	add_module sap/m/routing/Target.js $DEST/resources/sap/m/library-preload.json
	add_module sap/m/App.js $DEST/resources/sap/m/library-preload.json
	add_module sap/m/TileContainer.js $DEST/resources/sap/m/library-preload.json
	add_module sap/m/StandardTile.js $DEST/resources/sap/m/library-preload.json
	add_module sap/m/Tile.js $DEST/resources/sap/m/library-preload.json
	add_module sap/m/AppRenderer.js $DEST/resources/sap/m/library-preload.json
	add_module sap/m/NavContainerRenderer.js $DEST/resources/sap/m/library-preload.json
	add_module sap/m/PageRenderer.js $DEST/resources/sap/m/library-preload.json
	add_module sap/m/BarRenderer.js $DEST/resources/sap/m/library-preload.json
	add_module sap/m/TitleRenderer.js $DEST/resources/sap/m/library-preload.json
	add_module sap/m/TileContainerRenderer.js $DEST/resources/sap/m/library-preload.json
	add_module sap/m/StandardTileRenderer.js $DEST/resources/sap/m/library-preload.json
	add_module sap/m/Label.js $DEST/resources/sap/m/library-preload.json
	add_module sap/m/LabelRenderer.js $DEST/resources/sap/m/library-preload.json
	add_module sap/m/Input.js $DEST/resources/sap/m/library-preload.json
	add_module sap/m/InputRenderer.js $DEST/resources/sap/m/library-preload.json
	add_module sap/m/InputBase.js $DEST/resources/sap/m/library-preload.json
	add_module sap/m/InputBaseRenderer.js $DEST/resources/sap/m/library-preload.json
	add_module sap/m/List.js $DEST/resources/sap/m/library-preload.json
	add_module sap/m/ListBase.js $DEST/resources/sap/m/library-preload.json
	add_module sap/m/GroupHeaderListItem.js $DEST/resources/sap/m/library-preload.json
	add_module sap/m/ListItemBase.js $DEST/resources/sap/m/library-preload.json
	add_module sap/m/StandardListItem.js $DEST/resources/sap/m/library-preload.json
	add_module sap/m/Table.js $DEST/resources/sap/m/library-preload.json
	add_module sap/m/ToolbarRenderer.js $DEST/resources/sap/m/library-preload.json
	add_module sap/m/ToolbarSpacerRenderer.js $DEST/resources/sap/m/library-preload.json
	add_module sap/m/Text.js $DEST/resources/sap/m/library-preload.json
	add_module sap/m/TextRenderer.js $DEST/resources/sap/m/library-preload.json
	add_module sap/m/MessageBox.js $DEST/resources/sap/m/library-preload.json
	add_module sap/m/OverflowToolbarRenderer.js $DEST/resources/sap/m/library-preload.json
	add_module sap/m/DialogRenderer.js $DEST/resources/sap/m/library-preload.json
	add_lastmodule sap/m/TileRenderer.js $DEST/resources/sap/m/library-preload.json
	echo "}}" >> $DEST/resources/sap/m/library-preload.json

	echo Constructing $DEST/resources/sap/ui/core/library-preload.json
	echo '{"version":"2.0",' > $DEST/resources/sap/ui/core/library-preload.json
	echo '"name":"sap.ui.core.library-preload",' >> $DEST/resources/sap/ui/core/library-preload.json
	echo '"modules":{' >> $DEST/resources/sap/ui/core/library-preload.json
	add_module jquery.sap.xml.js $DEST/resources/sap/ui/core/library-preload.json
	add_module sap/ui/core/library.js $DEST/resources/sap/ui/core/library-preload.json
	add_module sap/ui/core/ComponentContainer.js $DEST/resources/sap/ui/core/library-preload.json
	add_module sap/ui/core/EventBus.js $DEST/resources/sap/ui/core/library-preload.json
	add_module sap/ui/core/theming/Parameters.js $DEST/resources/sap/ui/core/library-preload.json
	add_module sap/ui/core/ComponentContainerRenderer.js $DEST/resources/sap/ui/core/library-preload.json
	add_module sap/ui/core/UIComponent.js $DEST/resources/sap/ui/core/library-preload.json
	add_module sap/ui/core/UIComponentMetadata.js $DEST/resources/sap/ui/core/library-preload.json
	add_module sap/ui/core/mvc/View.js $DEST/resources/sap/ui/core/library-preload.json
	add_module sap/ui/core/routing/Router.js $DEST/resources/sap/ui/core/library-preload.json
	add_module sap/ui/core/routing/HashChanger.js $DEST/resources/sap/ui/core/library-preload.json
	add_module sap/ui/core/routing/Route.js $DEST/resources/sap/ui/core/library-preload.json
	add_module sap/ui/core/routing/Target.js $DEST/resources/sap/ui/core/library-preload.json
	add_module sap/ui/core/routing/Views.js $DEST/resources/sap/ui/core/library-preload.json
	add_module sap/ui/core/routing/Targets.js $DEST/resources/sap/ui/core/library-preload.json
	add_module sap/ui/core/PopupSupport.js $DEST/resources/sap/ui/core/library-preload.json
	add_module sap/ui/core/IconPool.js $DEST/resources/sap/ui/core/library-preload.json
	add_module sap/ui/core/messagebundle_nl.properties $DEST/resources/sap/ui/core/library-preload.json
	add_module sap/ui/core/LayoutData.js $DEST/resources/sap/ui/core/library-preload.json
	add_module sap/ui/core/InvisibleText.js $DEST/resources/sap/ui/core/library-preload.json
	add_module sap/ui/core/Renderer.js $DEST/resources/sap/ui/core/library-preload.json
	add_module sap/ui/core/EnabledPropagator.js $DEST/resources/sap/ui/core/library-preload.json
	add_module sap/ui/core/Popup.js $DEST/resources/sap/ui/core/library-preload.json
	add_module sap/ui/core/IntervalTrigger.js $DEST/resources/sap/ui/core/library-preload.json
	add_module sap/ui/core/delegate/ScrollEnablement.js $DEST/resources/sap/ui/core/library-preload.json
	add_module sap/ui/core/delegate/ItemNavigation.js $DEST/resources/sap/ui/core/library-preload.json
	add_module sap/ui/core/CustomData.js $DEST/resources/sap/ui/core/library-preload.json
	add_module sap/ui/core/routing/History.js $DEST/resources/sap/ui/core/library-preload.json
	add_module sap/ui/core/mvc/XMLView.js $DEST/resources/sap/ui/core/library-preload.json
	add_module sap/ui/core/XMLTemplateProcessor.js $DEST/resources/sap/ui/core/library-preload.json
	add_module sap/ui/core/ExtensionPoint.js $DEST/resources/sap/ui/core/library-preload.json
	add_module sap/ui/core/mvc/Controller.js $DEST/resources/sap/ui/core/library-preload.json
	add_module sap/ui/core/mvc/XMLViewRenderer.js $DEST/resources/sap/ui/core/library-preload.json
	add_module sap/ui/core/mvc/ViewRenderer.js $DEST/resources/sap/ui/core/library-preload.json
	add_module sap/ui/core/ValueStateSupport.js $DEST/resources/sap/ui/core/library-preload.json
	add_module sap/ui/core/Icon.js $DEST/resources/sap/ui/core/library-preload.json
	add_module sap/ui/core/IconRenderer.js $DEST/resources/sap/ui/core/library-preload.json
	add_module sap/ui/model/json/JSONModel.js $DEST/resources/sap/ui/core/library-preload.json
	add_module sap/ui/model/json/JSONListBinding.js $DEST/resources/sap/ui/core/library-preload.json
	add_module sap/ui/model/json/JSONPropertyBinding.js $DEST/resources/sap/ui/core/library-preload.json
	add_module sap/ui/model/json/JSONTreeBinding.js $DEST/resources/sap/ui/core/library-preload.json
	add_module sap/ui/model/resource/ResourceModel.js $DEST/resources/sap/ui/core/library-preload.json
	add_module sap/ui/model/resource/ResourcePropertyBinding.js $DEST/resources/sap/ui/core/library-preload.json
	add_module sap/ui/model/json/JSONModel.js $DEST/resources/sap/ui/core/library-preload.json
	add_module sap/ui/model/json/JSONListBinding.js $DEST/resources/sap/ui/core/library-preload.json
	add_module sap/ui/model/json/JSONPropertyBinding.js $DEST/resources/sap/ui/core/library-preload.json
	add_module sap/ui/model/json/JSONTreeBinding.js $DEST/resources/sap/ui/core/library-preload.json
	add_module sap/ui/model/resource/ResourceModel.js $DEST/resources/sap/ui/core/library-preload.json
	add_module sap/ui/model/resource/ResourcePropertyBinding.js $DEST/resources/sap/ui/core/library-preload.json
	add_module sap/ui/thirdparty/jquery-mobile-custom.js $DEST/resources/sap/ui/core/library-preload.json
	add_module sap/ui/thirdparty/signals.js $DEST/resources/sap/ui/core/library-preload.json
	add_module sap/ui/thirdparty/hasher.js $DEST/resources/sap/ui/core/library-preload.json
	add_lastmodule sap/ui/thirdparty/crossroads.js $DEST/resources/sap/ui/core/library-preload.json
	echo "}}" >> $DEST/resources/sap/ui/core/library-preload.json

	echo Constructing $DEST/resources/sap/ui/layout/library-preload.json
	echo '{"version":"2.0",' > $DEST/resources/sap/ui/layout/library-preload.json
	echo '"name":"sap.ui.layout.library-preload",' >> $DEST/resources/sap/ui/layout/library-preload.json
	echo '"dependencies":["sap.ui.core.library-preload"],' >> $DEST/resources/sap/ui/layout/library-preload.json
	echo '"modules":{' >> $DEST/resources/sap/ui/layout/library-preload.json
	add_module sap/ui/layout/form/SimpleForm.js $DEST/resources/sap/ui/layout/library-preload.json
	add_module sap/ui/layout/ResponsiveFlowLayoutData.js $DEST/resources/sap/ui/layout/library-preload.json
	add_module sap/ui/layout/GridData.js $DEST/resources/sap/ui/layout/library-preload.json
	add_module sap/ui/layout/GridRenderer.js $DEST/resources/sap/ui/layout/library-preload.json
	add_module sap/ui/layout/form/Form.js $DEST/resources/sap/ui/layout/library-preload.json
	add_module sap/ui/layout/form/FormContainer.js $DEST/resources/sap/ui/layout/library-preload.json
	add_module sap/ui/layout/form/FormElement.js $DEST/resources/sap/ui/layout/library-preload.json
	add_module sap/ui/layout/form/FormLayout.js $DEST/resources/sap/ui/layout/library-preload.json
	add_module sap/ui/layout/form/ResponsiveGridLayout.js $DEST/resources/sap/ui/layout/library-preload.json
	add_module sap/ui/layout/form/SimpleFormRenderer.js $DEST/resources/sap/ui/layout/library-preload.json
	add_module sap/ui/layout/form/ResponsiveGridLayoutRenderer.js $DEST/resources/sap/ui/layout/library-preload.json
	add_module sap/ui/layout/form/FormRenderer.js $DEST/resources/sap/ui/layout/library-preload.json
	add_module sap/ui/layout/form/FormLayoutRenderer.js $DEST/resources/sap/ui/layout/library-preload.json
	add_lastmodule sap/ui/layout/Grid.js $DEST/resources/sap/ui/layout/library-preload.json
	echo "}}" >> $DEST/resources/sap/ui/layout/library-preload.json

}

find $SRC -type f | while read line ; do process_file $line ; done

wget $UI5_URL -O $DEST/$UI5_TARBALL
unzip -o -q $DEST/$UI5_TARBALL -d $DEST/openui5
build_ui5

build_component
build_data
rm -rf dist
