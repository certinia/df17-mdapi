({
	/*
	 * Create a PageLayoutService.Request object
	 */
	buildLayoutRequest: function (component) {
		// For now, needs to be converted to JSON and deserialized
		// on the server. This is a workaround to avoid internal server
		// errors on sending custom classes as arguments to the server.
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
				}

				// On failure, try to get the first (usually most
				// useful) error message
				if (error && error[0] && error[0].message) {
					error = error[0].message;
				}

				// On failure, reject the promise
				console.error(error); // eslint-disable-line no-console
				reject(error);
			});

			// Add the action to the queue
			$A.enqueueAction(action);
		});
	},

	/*
	 * Called on changes to ObjectType to discover all applicable SObjectFields
	 */
	getFields: function (component) {
		var params = {
				objectType: component.get('v.objectType')
			};

		return this
			// Call server side method to find all SObjectFields for the current SObjectType.
			// Ideally, we would do this client side, but Lightning components
			// don't yet have global variables for describes.
			.enqueueAction(component, 'c.getFields', params)
			.then(function (result) {
				// Populate the fields and anchorFields picklists
				component.set('v.fields', result);
			});
	},

	/*
	 * Called on init to discover all SObjectTypes
	 */
	getObjectTypes: function (component) {
		return this
			// Call server side method to find all SObjectTypes.
			// Ideally, we would do this client side, but Lightning components
			// don't yet have global variables for describes.
			.enqueueAction(component, 'c.getObjectTypes')
			.then(function (result) {
				// Populate the ObjectTypes picklist
				component.set('v.objectTypes', result);
			});
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
			toast, message, type;

		return me
			.enqueueAction(component, 'c.updateLayout', me.buildLayoutRequest())
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
				// if there's no message, just use type as a fallback (Error/Success)
				message = message || type;

				// build and fire the toast notification
				toast = $A.get("e.force:showToast");
				toast.setParams({ message: message, type: type });
				toast.fire();
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
			pattern, match;

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
