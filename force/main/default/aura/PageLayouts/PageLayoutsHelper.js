({
	buildLayoutRequest: function (component) {
		return JSON.stringify({
			Strategy: component.get('v.strategy'),
			ObjectType: component.get('v.objectType'),
			LayoutName: component.get('v.layoutName'),
			Operation: component.get('v.operation'),
			Behavior: component.get('v.behavior'),
			Field: component.get('v.field'),
			AnchorType: component.get('v.anchorType'),
			AnchorField: component.get('v.anchorField')
		});
	},

	enqueueAction: function (component, name, params) {
		return new Promise(function (resolve, reject) {
			var action = component.get(name);

			if (params) {
				action.setParams(params);
			}

			action.setCallback(this, function (response) {
				var state = response.getState(),
					error = response.getError() || 'Unknown error';

				if (state === 'SUCCESS') {
					resolve(response.getReturnValue());
				}

				if (error && error[0] && error[0].message) {
					error = error[0].message;
				}

				reject(error);
			});

			$A.enqueueAction(action);
		});
	},

	getObjectTypes: function (component) {
		return this
			.enqueueAction(component, 'c.getObjectTypes')
			.then(function (result) {
				component.set('v.objectTypes', result);
			});
	},

	getFields: function (component) {
		var params = {
				objectType: component.get('v.objectType')
			};

		return this
			.enqueueAction(component, 'c.getFields', params)
			.then(function (result) {
				var first;
				component.set('v.fields', result);

				if (result && result[0] && result[0].value) {
					first = result[0].value;
					component.set('v.field', first);
					component.set('v.anchorField', first);
				}
			});
	},

	updateLayout: function (component) {
		var me = this,
			toast = $A.get("e.force:showToast"),
			message, type;

		return me
			.enqueueAction(component, 'c.updateLayout', me.buildLayoutRequest())
			.then(function (result) {
				message = result.Message;
				type = 'Success';
			})
			.catch(function (error) {
				message = error;
				type = 'Error';
			})
			.then(function () {
				message = message || type;
				toast.setParams({ message: message, type: type });
				toast.fire();
			});
	},

	updateLayoutName: function (component) {
		var objectType = component.get('v.objectType'),
			layoutName = objectType + '-' + objectType + ' Layout';

		component.set('v.layoutName', layoutName);
	},

	updateEditability: function (component) {
		var operation = component.get('v.operation'),
			anchorType = component.get('v.anchorType'),
			isRemoval = operation === 'Operation_Remove',
			isPageAnchored = anchorType === 'Anchor_Type_Start'
				|| anchorType === 'Anchor_Type_End';

		component.find('behavior').set('v.disabled', isRemoval);
		component.find('anchorType').set('v.disabled', isRemoval);
		component.find('anchorField').set('v.disabled', isRemoval || isPageAnchored);
	},

	updateObjectTypeFromLocation: function (component, location) {
		var objectType = component.get('v.objectType'),
			locationPattern = /sObject\/([A-Z_]*)/gi,
			locationMatch = locationPattern.exec(location),
			parsedObjectType = locationMatch[1];

		if (parsedObjectType && parsedObjectType !== objectType) {
			component.set('v.objectType', parsedObjectType);
		}
	}
})
