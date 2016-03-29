({
	// a naming exclusion checkbox has been modified, notify our container
    onCheck : function(component, event, helper) {
		helper.fireContactChangedEvent(component, event);
	}
})