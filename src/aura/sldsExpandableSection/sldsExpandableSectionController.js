({
    toggle: function(component, event, helper) {
        var expanded = component.get("v.expanded");
        component.set("v.expanded", !expanded);
    },
})