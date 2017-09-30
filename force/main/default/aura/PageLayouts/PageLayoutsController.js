({
	onUpdateClicked: function (component, event, helper) {
		helper.updateLayout(component);
	},

	onInit: function (component, event, helper) {
		helper.getObjectTypes(component);
	},

	onObjectTypeChanged: function (component, event, helper) {
		helper.getFields(component);
		helper.updateLayoutName(component);
	}
})