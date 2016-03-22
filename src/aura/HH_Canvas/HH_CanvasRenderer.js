({
    
	afterRender : function(component, helper) {
	    this.superAfterRender();
        helper.initJQueryHandlers(component);
	},
    
})