sap.ui.define([
	"com/penninkhof/espui/controller/BaseController",
	"sap/m/MessageBox"
], function(Controller, MessageBox) {
	"use strict";

	return Controller.extend("com.penninkhof.espui.controller.Main", {
		
		onInit: function() {
			this.i18n = this.getComponent().getModel("i18n").getResourceBundle();
			this.model = this.getComponent().getModel("status");
			this.initConnectedIcon();			
			this.getComponent().getModel("app").attachRequestCompleted(function(event) {
				var menu = event.getSource().getProperty("/MainMenu");
				for (var i = 0; i < menu.length; i++) {
					var menuItem = menu[i];
					var tile = this.getView().byId("mainMenu").getTiles()[i];
					for (var property in menuItem) {
					    if (menuItem.hasOwnProperty(property) && tile.getMetadata().hasProperty(property)) {
							var binding = menuItem[property].match(/{(.*?)}/);
							if (binding && binding.length > 0) {
								binding = binding[1];
								tile.bindProperty(property, binding);
							} else {
								tile.setProperty(property, menuItem[property]);					         	
							}
						}
					}
				}
			}, this);
		},

		onTilePress: function(event) {
			var menuItem = event.getSource().getBindingContext("app").getObject();
			if (menuItem.target) {
				this.getRouter().navTo(
					menuItem.target
				);
			} else if (menuItem.action) {
				if (menuItem.action.command === "switch") {
					this.toggleSwitch(menuItem.action.id);
				}
			}
		},
		
		toggleSwitch: function(id) {
			// var newState = this.getView().getModel("status").getProperty("/state/relay" + id) === "off" ? "on" : "off";
			var that = this;
			var cmd = {};
			cmd["relay" + id] = this.getView().getModel("status").getProperty("/state/relay" + id) === "off" ? "on" : "off";
			$.ajax({
				method: "POST",
				dataType: "json",
				contentType: 'application/json; charset=UTF-8',
				url: this.getComponent().getMetadata().getManifestEntry("sap.app").dataSources.status.uri,
				data: JSON.stringify(cmd),
				success: function(data) {
					that.model.setData(data);
				},
				error: function(jqXHR, textStatus, errorThrown) {
					MessageBox.error(that.i18n.getText("switchError") + "\n" + errorThrown);
				}
			});
		}
		
	});

});