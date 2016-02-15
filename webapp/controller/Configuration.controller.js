sap.ui.define([
	"com/penninkhof/espui/controller/BaseController",
	"sap/m/MessageBox"
], function(Controller, MessageBox) {
	"use strict";

	return Controller.extend("com.penninkhof.espui.controller.Configuration", {

		onInit: function() {
			this.view = this.getView();
			this.model = this.getComponent().getModel("config");
			this.i18n = this.getComponent().getModel("i18n").getResourceBundle();
			this.initConnectedIcon();
		},

		validate: function() {
			var valid = true;
			if (!this.model.getProperty("/ssid")) {
				this.view.byId("ssid").setValueState("Error").setValueStateText(this.i18n.getText("ssidIsRequired"));
				valid = false;
			}
			if (this.model.getProperty("/psk") !== this.model.getProperty("/psk2")) {
				this.view.byId("psk").setValueState("Error").setValueStateText(this.i18n.getText("pskNotTheSame"));
				this.view.byId("psk2").setValueState ("Error").setValueStateText(this.i18n.getText("pskNotTheSame"));
				valid = false;
			}
			if (!this.model.getProperty("/hostname")) {
				this.view.byId("hostname").setValueState("Error").setValueStateText(this.i18n.getText("hostnameIsRequired"));
				valid = false;
			}
			if (!this.model.getProperty("/friendlyName")) {
				this.model.setProperty("/friendlyName", this.model.getProperty("/hostname"));
				if (!this.model.getProperty("/friendlyName")) {
					this.view.byId("friendlyName").setValueState("Error").setValueStateText(this.i18n.getText("friendlyNameIsRequired"));
					valid = false;
				}
			}
			if (!this.model.getProperty("/mqttPort")) {
				this.model.setProperty("/mqttPort", "1883");
			}
			if (!this.model.getProperty("/mqttTopic")) {
				if (this.model.getProperty("/hostname")) {
					this.model.setProperty("/mqttTopic", "/devicex/" + this.model.getProperty("/hostname"));
				}
			}
			return valid;
		},

		onAccept: function(event) {
			var that = this;
			if (this.validate()) {
				$.ajax({
					method: "POST",
					dataType: "json",
					contentType: 'application/json; charset=UTF-8',
					url: this.getComponent().getMetadata().getManifestEntry("sap.app").dataSources.config.uri,
					data: JSON.stringify(this.model.getData()),
					success: function(data) {
						that.getComponent().getEventBus().publish("device", "offline");
						that.model.setData(data);
						MessageBox.success(that.i18n.getText("configSavedSuccess"), {
							onClose: function() {
								that.onNavBack(event);
							}
						});
					},
					error: function(jqXHR, textStatus, errorThrown) {
						MessageBox.error(that.i18n.getText("configSavedError") + "\n" + errorThrown);
					}
				});

			} else {
				MessageBox.alert(this.i18n.getText("invalidEntry"));
			}
		}

	});

});
