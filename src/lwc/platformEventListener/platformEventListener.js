/**
 * Created by kenneth.lewis on 2019-06-27.
 */

import {LightningElement, track, api} from 'lwc';
import { subscribe, unsubscribe, onError, setDebugFlag, isEmpEnabled } from 'lightning/empApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

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
        const evt = new ShowToastEvent({
            title: 'Deployment completed with Status: ' + response.data.payload.Status__c,
            message: 'Deployment Id: ' + response.data.payload.DeploymentId__c,
            variant: 'success',
        });
        this.dispatchEvent(evt);
    }

    log(response) {
        console.log('Deployment Event received! ' +
            'Deployment Id: ' + response.data.payload.DeploymentId__c +
            ' with Status: ' + response.data.payload.Status__c);
    }

    isMonitored(deploymentId) {
        return this._deploymentIds
            && this._deploymentIds.has(deploymentId);
    }

    handleSubscribe() {
        let x = this;

        // Callback invoked whenever a new event message is received
        const messageCallback = function (response) {
            // console.log('*** ' + 'Received Platform Event' + ' ***');
            // console.log('JSON.stringify(response): ', JSON.stringify(response));
            //TODO: see if we can import DeploymentEvent__e schema
            x.handleEventReceived(response);
        };

        // Invoke subscribe method of empApi. Pass reference to messageCallback
        subscribe(this.channelName, -1, messageCallback).then(response => {
            // Response contains the subscription information on successful subscribe call
            console.log('Successfully subscribed to : ', JSON.stringify(response.channel));
            this.subscription = response;
        });
    }

    handleEventReceived(response) {
        const deploymentId = response.data.payload.DeploymentId__c;
        if (this.isMonitored(deploymentId)) {
            if (this.isShowToastEnabled) {
                this.showToast(response);
            }
            if (this.isConsoleLogEnabled) {
                this.log(response);
            }
        }

        //Store the response, in case we were unable to verify the deploymentId yet
        this._deploymentResponses.put(deploymentId, response);
    }

    static onError(error) {
        console.log('Received error from server: ', JSON.stringify(error));
        // Error contains the server-side error
    }
}