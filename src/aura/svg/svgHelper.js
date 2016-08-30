({
    renderIcon: function(component) {
        var spritename = component.get("v.spriteName");
        var symbolid = component.get("v.symbolId");
        var iconname = component.get("v.iconName");
        var classname = component.get("v.className");
        var category = component.get("v.category");
        var size = component.get("v.size");
        var prefix = component.get("v.prefix");
        var containerclass = component.get("v.containerClass");
        var action = component.get("c.getSvgIconMarkupAura");
        var containerClassName = [
            prefix+"icon_container",
            prefix+"icon-"+category+"-"+name,
            containerclass
            ].join(' ');

        component.set("v.containerClass", containerClassName);
        action.setParams({
            "spriteName": spritename,
            "symbolId": symbolid,
            "category": category,
            "iconName": iconname,
            "size": size,
            "className": classname,
            "prefix": prefix
        });

        var self = this;
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                var svgMarkup = response.getReturnValue();
                var svgContainer = component.find("svg_container");
                svgContainer.getElement().innerHTML = svgMarkup;
            } else if (component.isValid() && state === "ERROR") {
                self.reportError(component, response);
            }
        });

        $A.enqueueAction(action);
    }
})