({
	onAnchorTypeChanged: function (component, event, helper) {
		helper.updateEditability(component);
	},

	onInit: function (component, event, helper) {
		helper.getObjectTypes(component);
		helper.updateEditability(component);
	},

	onObjectTypeChanged: function (component, event, helper) {
		helper.getFields(component);
		helper.updateLayoutName(component);
	},

	onOperationChanged: function (component, event, helper) {
		helper.updateEditability(component);
	},

	onUpdateClicked: function (component, event, helper) {
		helper.updateLayout(component);
	}
})
