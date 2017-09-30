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

		component.set('v.message', '');
		component.set('v.messageSeverity', '');

		action.setParams({
			requestString: JSON.stringify(layoutRequest)
		});

		action.setCallback(this, function (response) {
			var state = response.getState(),
				messageSeverity = 'Info',
				message,
				responseMessages;

			if (state === 'SUCCESS') {
				messageSeverity = 'Info';
				responseMessages = response.getReturnValue();

				if (responseMessages && responseMessages.message) {
					message = responseMessages.message;
				} else {
					message = 'Success';
				}
			} else if (state === 'ERROR') {
				messageSeverity = 'Error';
				responseMessages = response.getError();

				if (responseMessages && responseMessages[0] && responseMessages[0].message) {
					message = responseMessages[0].message;
				} else {
					message = 'Unknown error';
				}

			} else {
				messageSeverity = 'Error';
				component.set('v.response', 'Unknown state: ' + state);
			}

			component.set('v.message', message);
			component.set('v.messageSeverity', messageSeverity);
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
	}
})