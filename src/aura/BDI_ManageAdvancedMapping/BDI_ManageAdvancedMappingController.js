({
    handleDeploymentNotification: function (component, event) {
        let deploymentId = event.getParam('deploymentId');
        component.find("platformEventListener").registerDeploymentId(deploymentId);
    }
})