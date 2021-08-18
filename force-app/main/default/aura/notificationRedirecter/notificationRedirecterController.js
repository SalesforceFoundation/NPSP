/**
 * Created by voduyemi on 8/17/21.
 */

({
    doNavigate: function(component, event, helper) {
        const pageReference =  component.get('v.pageReference');
        const redirectUrl = pageReference.state.c__redirectUrl

        component.find("navigationService").navigate({
            type: "standard__webPage",
            attributes: {
                url: redirectUrl
            }
        }, true);
    }
});