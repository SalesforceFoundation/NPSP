
import {LightningElement, track, api} from 'lwc';
import { subscribe, unsubscribe, onError, setDebugFlag, isEmpEnabled } from 'lightning/empApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { fireEvent } from 'c/pubsubNoPageRef';
import getNamespacePrefix from '@salesforce/apex/BDI_ManageAdvancedMappingCtrl.getNamespacePrefix';

import stgUnknownError from '@salesforce/label/c.stgUnknownError';

export default class PlatformEventListener extends LightningElement {

    /*******************************************************************************
    * @description Public property for the default channel name or platform event
    * name to subscribe to. Parent component can set the value to a channel name or
    * platform event name.
    */
    @api channelName;

    _fullChannelName;
    _namespacePrefix;
    subscription = {};

    @api isShowToastEnabled = false;
    @api isConsoleLogEnabled = false;
    @api isDebugFlagEnabled = false;

    @api _deploymentIds = new Set();
    _deploymentResponses = new Map();

    connectedCallback() {
        this.init();
    }

    init = async() => {
        this._namespacePrefix = await getNamespacePrefix();
        this.handleChannelName();
        this.handleSubscribe();
        setDebugFlag(this.isDebugFlagEnabled);
    }

    classifyChannelName() {
        let isFullName = this.channelName && this.channelName.includes('/event/');
        let isNamespaceContext = this._namespacePrefix && this._namespacePrefix !== '';
        let isChannelNamespaced = this.channelName.includes(this._namespacePrefix);

        if (isFullName) {
            return 'isFullName';
        } else if (isNamespaceContext && isChannelNamespaced) {
            return 'inNamespaceContextIsNamespaced';
        } else if (isNamespaceContext && !isChannelNamespaced) {
            return 'inNamespaceContextNotNamespaced';
        } else if (!isNamespaceContext) {
            return 'notInNamespaceContext'
        } else if (!this.channelName) {
            return 'undefined';
        }

        return 'default';
    }

    handleChannelName() {
        let category = this.classifyChannelName();

        switch (category) {
            case 'fullName':
                this._fullChannelName = this.channelName;
                break;

            case 'inNamespaceContextIsNamespaced':
                this._fullChannelName = `/event/${this.channelName}`;
                break;

            case 'inNamespaceContextNotNamespaced':
                this._fullChannelName = `/event/${this._namespacePrefix}__${this.channelName}`;
                break;

            case 'notInNamespaceContext':
                this._fullChannelName = `/event/${this.channelName}`;
                break;

            case 'undefined':
                this.handleError({
                    name: 'Error',
                    message: `Invalid or missing channel '${this.channelName}'`
                });
                break;

            default:
                this._fullChannelName = '/event/npsp__DeploymentEvent__e';
        }
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
        subscribe(this._fullChannelName, -1, messageCallback).then(response => {
            // Response contains the subscription information on successful subscribe call
            this.subscription = response;
        });
        console.log('Subscribed to channel: ', this._fullChannelName);
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

    /*******************************************************************************
    * @description Creates and dispatches a ShowToastEvent
    *
    * @param {string} title: Title of the toast, dispalyed as a heading.
    * @param {string} message: Message of the toast. It can contain placeholders in
    * the form of {0} ... {N}. The placeholders are replaced with the links from
    * messageData param
    * @param {string} mode: Mode of the toast
    * @param {array} messageData: List of values that replace the {index} placeholders
    * in the message param
    */
    errorToast(title, message, variant, mode, messageData) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: mode,
            messageData: messageData
        });
        this.dispatchEvent(event);
    }

    /*******************************************************************************
    * @description Creates and dispatches an error toast
    *
    * @param {object} error: Event holding error details
    */
    handleError(error) {
        console.log('Error: ', error);
        if (error && error.status && error.body) {
            this.errorToast(`${error.status} ${error.statusText}`, error.body.message, 'error', 'sticky');
        } else if (error && error.name && error.message) {
            this.errorToast(`${error.name}`, error.message, 'error', 'sticky');
        } else {
            this.errorToast(stgUnknownError, '', 'error', 'sticky');
        }
    }
}
