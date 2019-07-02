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
        const deploymentResponse = this._deploymentResponses.get(deploymentId);
        if (deploymentResponse) {
            this.handleEventReceived(deploymentResponse);
        } else {
            this._deploymentIds.add(deploymentId);
        }
        console.log('end of registerDeploymentId - this._deploymentIds: ', this._deploymentIds);
    }

    showToast(response){
        const evt = new ShowToastEvent({
            title: 'Deployment completed with Status: ' + response.status.name(),
            message: JSON.stringify(response),
            variant: 'success',
        });
        this.dispatchEvent(evt);
    }

    log(response) {
        console.log('Deployment Event received! Message: ', JSON.stringify(response));
    }

    isMonitored(deploymentId) {
        return this._deploymentIds
            && this._deploymentIds.has(deploymentId);
    }

    handleSubscribe() {
        let x = this;

        // Callback invoked whenever a new event message is received
        const messageCallback = function (response) {
            console.log('*** ' + 'Received Platform Event' + ' ***');
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
        console.log('*** in platformEventListener.handleEventReceived, this.monitoredIds: ' + this._deploymentIds + ' ***');
        const deploymentId = response.data.payload.DeploymentId__c;
        console.log('deploymentId: ', deploymentId);
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
        console.log('this._deploymentResponses: ', this._deploymentResponses);
        console.log('*** ' + 'end handle events received' + ' ***');
    }

    static onError(error) {
        console.log('Received error from server: ', JSON.stringify(error));
        // Error contains the server-side error
    }
}