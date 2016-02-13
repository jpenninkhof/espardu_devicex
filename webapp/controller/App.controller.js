sap.ui.define([
	"com/penninkhof/espui/controller/BaseController"
], function(Controller) {
	"use strict";

	return Controller.extend("com.penninkhof.espui.controller.App", {
		
		onAfterRendering: function() {
			$("#splash-screen").remove();
		}
		
	});

});