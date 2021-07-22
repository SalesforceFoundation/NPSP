({
    init: function (component, event, helper) {
        let pageRef = component.get("v.pageReference");

        const recordId = pageRef.state.c__recordId;
        component.set("v.recordId", recordId);
    },
    
    refresh: function (component, event, helper) {
        $A.get("e.force:refreshView").fire();
    },
})
