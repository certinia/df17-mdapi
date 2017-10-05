({
	onCometdLoaded: function (component, event, helper) {
		var cometd = new org.cometd.CometD(),
			sessionId = component.get('v.sessionId');

		component.set('v.cometd', cometd);

		if (sessionId !== null) {
			helper.connectCometd(component);
		}
	},

	onInit: function (component, event, helper) {
		var action = component.get('c.getSessionId');
		component.set('v.cometdSubscriptions', []);

		// Disconnect CometD when leaving page
		window.addEventListener('unload', function (event) {
			helper.disconnectCometd(component);
		});

		action.setCallback(this, function (response) {
			if (component.isValid() && response.getState() === 'SUCCESS') {
				component.set('v.sessionId', response.getReturnValue());
				if (component.get('v.cometd') !== null) {
					helper.connectCometd(component);
				}
			}
		});

		$A.enqueueAction(action);
	}

});
