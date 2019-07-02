({
    handleDeploymentNotification: function (component, event) {
        console.log('in top-level AURA component, handleDeploymentNotification');
        let deploymentId = event.getParam('deploymentId');
        console.log('event.getParam(deploymentId): ', deploymentId);
        component.find("platformEventListener").registerDeploymentId(deploymentId);
    }
})