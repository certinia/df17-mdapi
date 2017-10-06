({
	connectCometd: function (component) {
		var me = this,
			cometd = component.get('v.cometd'),
			location = window.location,
			cometdUrl = location.protocol + '//' + location.hostname + '/cometd/41.0/';

		cometd.configure({
			url: cometdUrl,
			requestHeaders: { Authorization: 'OAuth ' + component.get('v.sessionId')},
			appendMessageTypeToURL: false
		});

		cometd.websocketEnabled = false;

		// Establish CometD connection
		cometd.handshake(function (handshakeReply) {
			var subscriptions = component.get('v.cometdSubscriptions'),
				newSubscription;

			if (handshakeReply.successful) {
				// Subscribe to platform event
				newSubscription = cometd.subscribe('/event/PageLayoutUpdate__e', function (platformEvent) {
					me.onReceiveNotification(component, platformEvent);
				});

				// Save subscription for later
				subscriptions.push(newSubscription);
				component.set('v.cometdSubscriptions', subscriptions);
			}
		});
	},

	disconnectCometd: function (component) {
		var cometd = component.get('v.cometd');

		// Unsubcribe all CometD subscriptions
		cometd.batch(function () {
			var subscriptions = component.get('v.cometdSubscriptions');
			subscriptions.forEach(function (subscription) {
				cometd.unsubscribe(subscription);
			});
		});
		component.set('v.cometdSubscriptions', []);

		// Disconnect CometD
		cometd.disconnect();
	},

	onReceiveNotification: function (component, platformEvent) {
		this.displayToast(component, platformEvent.data.payload);
	},

	displayToast: function (component, payload) {
		var toastEvent = $A.get('e.force:showToast'),
			result = JSON.parse(payload.DeployResult__c),
			type = result.success ? 'Success' : 'Error',
			message = result.success ? 'Successfully updated page layout' : 'Error updating page layout';

		if (result.messages && result.messages[0] && result.messages[0].problem) {
			message = result.messages[0].problem;
		}

		toastEvent.setParams({
			type: type,
			message: message
		});

		toastEvent.fire();
	}
});
