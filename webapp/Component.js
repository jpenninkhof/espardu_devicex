sap.ui.define([
	"sap/ui/core/UIComponent",
	"sap/ui/Device",
	"com/penninkhof/espui/model/models"
], function(UIComponent, Device, models) {
	"use strict";

	return UIComponent.extend("com.penninkhof.espui.Component", {

		metadata: {
			manifest: "json"
		},

		/**
		 * The component is initialized by UI5 automatically during the startup of the app and calls the init method once.
		 * @public
		 * @override
		 */
		init: function() {
			// call the base component's init function
			UIComponent.prototype.init.apply(this, arguments);

			// set the device model
			this.setModel(models.createDeviceModel(), "device");

            // create the views based on the url/hash
            this.getRouter().initialize();

            // Start the timer to update the status model
            this.startUpdater();

		},

		// Automatically refreshes the status model every second
		startUpdater: function() {
			var that = this;
			$.ajax({
				url: this.getMetadata().getManifestEntry("sap.app").dataSources.status.uri,
				dataType: 'json',
				success: function(data) {
					that.getModel("status").setData(data);
					that.getEventBus().publish("device", "online");
				},
				error: function() {
					that.getEventBus().publish("device", "offline");
				},
				timeout: 2000
			}).always(function() {
				setTimeout(
					function() {
						that.startUpdater();
					},
					1000
				);
			});
		}

	});

});
