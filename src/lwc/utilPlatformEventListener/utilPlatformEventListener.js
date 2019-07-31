
import {LightningElement, track, api} from 'lwc';
import { subscribe, unsubscribe, onError, setDebugFlag, isEmpEnabled } from 'lightning/empApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { fireEvent } from 'c/pubsubNoPageRef';

export default class PlatformEventListener extends LightningElement {
    @api channelName = '/event/DeploymentEvent__e'; //Default
    subscription = {};

    @api isShowToastEnabled = false;
    @api isConsoleLogEnabled = false;
    @api isDebugFlagEnabled = false;

    @api _deploymentIds = new Set();
    _deploymentResponses = new Map();

    connectedCallback() {
        this.handleSubscribe();
        setDebugFlag(this.isDebugFlagEnabled);
    }

    @api
    registerDeploymentId(deploymentId) {
        if (this._deploymentResponses.has(deploymentId)) {
            this.handleEventReceived(this._deploymentResponses.get(deploymentId));
        } else {
            this._deploymentIds.add(deploymentId);
        }
    }

    showToast(response){
        const status =
            response.data.payload.Status__c || response.data.payload.npsp__Status__c;
        const deploymentId =
            response.data.payload.DeploymentId__c || response.data.payload.npsp__DeploymentId__c;
        const evt = new ShowToastEvent({
            title: 'Deployment completed with Status: ' + status,
            message: 'Deployment Id: ' + deploymentId,
            variant: 'success',
        });
        this.dispatchEvent(evt);
    }

    log(response) {
        const status =
            response.data.payload.Status__c || response.data.payload.npsp__Status__c;
        const deploymentId =
            response.data.payload.DeploymentId__c || response.data.payload.npsp__DeploymentId__c;
        console.log('Deployment Event received! ' +
            'Deployment Id: ' + deploymentId +
            ' with Status: ' + status);
    }

    isMonitored(deploymentId) {
        return this._deploymentIds
            && this._deploymentIds.has(deploymentId);
    }

    handleSubscribe() {
        let x = this;

        // Callback invoked whenever a new event message is received
        const messageCallback = function (response) {
            x.handleEventReceived(response);
        };

        // Invoke subscribe method of empApi. Pass reference to messageCallback
        subscribe(this.channelName, -1, messageCallback).then(response => {
            // Response contains the subscription information on successful subscribe call
            this.subscription = response;
        });
    }

    handleEventReceived(response) {
        const deploymentId =
            response.data.payload.DeploymentId__c || response.data.payload.npsp__DeploymentId__c;
        if (this.isMonitored(deploymentId)) {
            if (this.isShowToastEnabled) {
                fireEvent(this.pageRef, 'deploymentResponse', { response: response });
            }
            if (this.isConsoleLogEnabled) {
                this.log(response);
            }
        }

        //Store the response, in case we were unable to verify the deploymentId yet
        this._deploymentResponses.set(deploymentId, response);
    }

    static onError(error) {
        console.log('Received error from server: ', JSON.stringify(error));
        // Error contains the server-side error
    }
}
