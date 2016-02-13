sap.ui.define([
	"sap/ui/core/mvc/Controller",
	"sap/ui/core/routing/History"
], function (Controller, History) {
	"use strict";

	return Controller.extend("com.penninkhof.espui.controller.BaseController", {

		getRouter : function () {
			return sap.ui.core.UIComponent.getRouterFor(this);
		},

		getComponent: function() {
			return sap.ui.component(sap.ui.core.Component.getOwnerIdFor(this.getView()));
		},

		onNavBack: function (event) {
			var oHistory, sPreviousHash;

			oHistory = History.getInstance();
			sPreviousHash = oHistory.getPreviousHash();

			if (sPreviousHash !== undefined) {
				window.history.go(-1);
			} else {
				this.getRouter().navTo("appHome", {}, true /*no history*/);
			}
		},
		
		initConnectedIcon: function() {
			var eventBus = this.getComponent().getEventBus();
			eventBus.subscribe("device", "online", function() {
				this.getView().byId("connectedIcon").setSrc("sap-icon://connected");
			}, this);
			eventBus.subscribe("device", "offline", function() {
				this.getView().byId("connectedIcon").setSrc("sap-icon://disconnected");
			}, this);
		}

	});

});