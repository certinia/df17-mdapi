({
	updateLayout: function (component) {
		var action = component.get('c.updateLayout'),
			layoutRequest = {
				Strategy: component.get('v.strategy'),
				ObjectType: component.get('v.objectType'),
				LayoutName: component.get('v.layoutName'),
				Operation: component.get('v.operation'),
				Behavior: component.get('v.behavior'),
				Field: component.get('v.field'),
				AnchorType: component.get('v.anchorType'),
				AnchorField: component.get('v.anchorField')
			};

		action.setParams({
			requestString: JSON.stringify(layoutRequest)
		});

		action.setCallback(this, function (response) {
			var state = response.getState(),
				toast = $A.get("e.force:showToast"),
				success = false,
				result,
				message,
				type;

			if (state === 'SUCCESS') {
				result = response.getReturnValue() || {};
				success = result.Success;
				message = result.Message;
			} else if (state === 'ERROR') {
				result = response.getError();
				if (result && result[0] && result[0].message) {
					message = result[0].message;
				}
			} else {
				message = 'Unknown state: ' + state;
			}

			if (success) {
				message = message || 'Success';
				type = 'success';
			} else {
				message = message || 'Error';
				type = 'error';
			}

			toast.setParams({
				message: message,
				type: type
			});
			toast.fire();
		});

		$A.enqueueAction(action);
	},

	getObjectTypes: function (component) {
		var action = component.get('c.getObjectTypes');

		action.setCallback(this, function (response) {
			var objectTypes = response.getReturnValue(),
				first = objectTypes && objectTypes[0] && objectTypes[0].value ? objectTypes[0].value : null;

			component.set('v.objectTypes', objectTypes);
			component.set('v.objectType', first);
		});

		$A.enqueueAction(action);
	},

	getFields: function (component) {
		var action = component.get('c.getFields'),
			objectType = component.get('v.objectType');

		action.setParams({
			objectType: objectType
		});

		action.setCallback(this, function (response) {
			var fields = response.getReturnValue(),
				first = fields && fields[0] && fields[0].value ? fields[0].value : null;

			component.set('v.fields', fields);
			component.set('v.field', first);
			component.set('v.anchorField', first);
		});

		$A.enqueueAction(action);
	},

	updateLayoutName: function (component) {
		var objectType = component.get('v.objectType'),
			layoutName = objectType + '-' + objectType + ' Layout';

		component.set('v.layoutName', layoutName);
	}
})