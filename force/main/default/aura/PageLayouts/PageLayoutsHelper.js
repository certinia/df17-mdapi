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
			var objectTypes = response.getReturnValue();
			component.set('{!v.objectTypes}', objectTypes);
		});

		$A.enqueueAction(action);
	}
})