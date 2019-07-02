({
    handleDeploymentNotification: function (component, event) {
        console.log('BDI_ManageAdvancedMappingController | handleDeploymentNotification()');
        let deploymentId = event.getParam('deploymentId');
        component.find("platformEventListener").registerDeploymentId(deploymentId);
    }
})