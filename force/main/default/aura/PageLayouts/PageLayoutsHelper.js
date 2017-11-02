({
	/*
	 * Create a PageLayoutService.Request object
	 */
	buildLayoutRequest: function (component) {
		// For now, needs to be converted to JSON and deserialized
		// on the server. This is a workaround to avoid internal server
		// errors on sending custom classes as arguments to the server.
		return {
			requestString: JSON.stringify({
				Strategy: component.get('v.strategy'),
				ObjectType: component.get('v.objectType'),
				LayoutName: component.get('v.layoutName'),
				Operation: component.get('v.operation'),
				Behavior: component.get('v.behavior'),
				Field: component.get('v.field'),
				AnchorType: component.get('v.anchorType'),
				AnchorField: component.get('v.anchorField')
			})
		};
	},

	/*
	 * Promisified wrapper to make a server call to the Apex controller
	 */
	enqueueAction: function (component, name, params) {
		return new Promise(function (resolve, reject) {
			// Get the AuraEnabled method on the Apex controller
			var action = component.get(name);

			// Apply the parameters if there are any
			if (params) {
				action.setParams(params);
			}

			// Handle the method result
			action.setCallback(this, function (response) {
				var state = response.getState(),
					error = response.getError() || 'Unknown error';

				// On success, return the result
				if (state === 'SUCCESS') {
					resolve(response.getReturnValue());
				} else {
					// On failure, try to get the first (usually most
					// useful) error message
					if (error && error[0] && error[0].message) {
						error = error[0].message;
					}

					// On failure, reject the promise
					console.error(error); // eslint-disable-line no-console
					reject(error);
				}
			});

			// Add the action to the queue
			$A.enqueueAction(action);
		});
	},

	/*
	 * Called on changes to ObjectType to discover all applicable SObjectFields
	 */
	getFields: function (component) {
		var me = this,
			params = {
				objectType: component.get('v.objectType')
			};

		return me
			// Call server side method to find all SObjectFields for the current SObjectType.
			// Ideally, we would do this client side, but Lightning components
			// don't yet have global variables for describes.
			.enqueueAction(component, 'c.getFields', params)
			.then(function (result) {
				// Populate the fields and anchorFields picklists
				component.set('v.fields', result);
				component.set('v.field', me.head(result));
			});
	},

	/*
	 * Called on init to discover all SObjectTypes
	 */
	getObjectTypes: function (component) {
		var me = this;

		return me
			// Call server side method to find all SObjectTypes.
			// Ideally, we would do this client side, but Lightning components
			// don't yet have global variables for describes.
			.enqueueAction(component, 'c.getObjectTypes')
			.then(function (result) {
				// Populate the ObjectTypes picklist
				component.set('v.objectTypes', result);
				component.set('v.objectType', me.head(result));
				component.set('v.hasReadObjectTypes', true);
			})
			.then(function () {
				// Attempt to set the ObjectType from the current page
				return me.updateObjectTypeFromLocation(component, window.location.hash);
			});
	},

	/*
	 * Displays toast notifications on receiving PageLayoutUpdate__e events
	 */
	handleMonitoredEvent: function (event) {
		var platformEvent = event.getParam('event'),
			result = JSON.parse(platformEvent.data.payload.DeployResult__c),
			type = result.success ? 'Success' : 'Error',
			message = result.success ? 'Successfully updated page layout' : 'Error updating page layout';

		if (result.messages && result.messages[0] && result.messages[0].problem) {
			message = result.messages[0].problem;
		}

		this.showToast(type, message);
	},

	/*
	 * Gets value from first element in array
	 */
	head: function (array) {
		if (array && array[0] && array[0].value) {
			return array[0].value;
		}
		return null;
	},

	/*
	 * Inits non-dynamic comboboxes
	 */
	initComboboxes: function (component) {
		var me = this;
		me.populateCombobox(component, 'v.strategies', [
			'Strategy_Classic',
			'Strategy_Native'
		]);
		me.populateCombobox(component, 'v.operations', [
			'Operation_Add',
			'Operation_Remove'
		]);
		me.populateCombobox(component, 'v.behaviors', [
			'Behaviour_Edit',
			'Behaviour_Required',
			'Behaviour_Readonly'
		]);
		me.populateCombobox(component, 'v.anchorTypes', [
			'Anchor_Type_Start',
			'Anchor_Type_After',
			'Anchor_Type_Before',
			'Anchor_Type_End'
		]);
	},

	/*
	 * Sets combobox options from a set of label names
	 */
	populateCombobox: function (component, name, values) {
		values = values || [];
		component.set(name, values.map(function (value) {
			var label = $A.get("$Label." + value) || value;
			return { value: value, label: label };
		}));
	},

	/*
	 * Builds and fires toast
	 */
	showToast: function (type, message) {
		var toast = $A.get("e.force:showToast");
		toast.setParams({
			message: message || type, // when there's no message, use type as fallback
			type: type
		});
		toast.fire();
	},

	/*
	 * Marks fields as disabled when they aren't applicable
	 */
	updateEditability: function (component) {
		var operation = component.get('v.operation'),
			anchorType = component.get('v.anchorType'),
			isRemoval = operation === 'Operation_Remove',
			isPageAnchored = anchorType === 'Anchor_Type_Start'
				|| anchorType === 'Anchor_Type_End';

		// Behavior controls whether you can/must edit a newly added field.
		// Not applicable on field removals.
		component.find('behavior').set('v.disabled', isRemoval);

		// Anchors define where to place a newly added field.
		// Not appicable on field removals.
		component.find('anchorType').set('v.disabled', isRemoval);

		// Anchor fields define which field to inject the newly added field before or after.
		// Not applicable on field removals, nor on field additions where the field is dumped
		// at the start or end of the page.
		component.find('anchorField').set('v.disabled', isRemoval || isPageAnchored);
	},

	/*
	 * The heart of this Lightning Component;
	 * updates SObject page layouts using the Metadata API
	 */
	updateLayout: function (component) {
		var me = this,
			params = me.buildLayoutRequest(component),
			message, type;

		return me
			.enqueueAction(component, 'c.updateLayout', params)
			.then(function (result) {
				// on success, build the toast parameters
				message = result.Message;
				type = 'Success';
			})
			.catch(function (error) {
				// on failure, build the toast parameters
				message = error;
				type = 'Error';
			})
			.then(function () {
				// build and fire the toast notification
				me.showToast(type, message);
			});
	},

	/*
	 * Guess the default Page Layout name for the current SObjectType
	 */
	updateLayoutName: function (component) {
		var objectType = component.get('v.objectType'),
			// Default layouts are usually of the form "Account-Account layout"
			layoutName = objectType + '-' + objectType + ' Layout';

		// Set the value of the LayoutName text field
		component.set('v.layoutName', layoutName);
	},

	/*
	 * Attempt to use the current ObjectType from the current page.
	 * For example, if I'm on an Account record, I probably want to change Account layouts.
	 */
	updateObjectTypeFromLocation: function (component, location) {
		var me = this,
			hasReadObjectTypes = component.get('v.hasReadObjectTypes'),
			pattern, match;

		// Don't bother attempting to set ObjectType until we've
		// populated the ObjectTypes picklist
		if (!hasReadObjectTypes) {
			return Promise.resolve();
		}

		return Promise
			.resolve()
			.then(function () {
				// Attempt to read objectType from the current record id
				// Url is of the form "sObject/0013D00000LvX46QAF/view"
				pattern = new RegExp('sObject\/([A-Za-z0-9]{18})\/');
				match = location.match(pattern);
				if (match && match[1]) {
					// Call server side method to resolve SObjectType from Id.
					// Ideally, we would do this client side, but Lightning components
					// don't yet have global variables for describes
					return me.enqueueAction(component, 'c.getObjectType', { recordId: match[1]});
				}

				// Attempt to read objectType from the current page
				// Url is of the form "/sObject/Account/list?filterName=Recent"
				pattern = new RegExp('sObject\/([A-Za-z0-9_]+)\/');
				match = location.match(pattern);
				if (match && match[1]) {
					return match[1];
				}

				return null;
			})
			.then(function (objectType) {
				// Set the value of the objectType picklist
				if (objectType) {
					component.set('v.objectType', objectType);
				}
			});
	}
})
