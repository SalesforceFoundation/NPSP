import {LightningElement, track, api} from 'lwc';
import { subscribe, unsubscribe, onError, setDebugFlag, isEmpEnabled } from 'lightning/empApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { fireEvent } from 'c/pubsubNoPageRef';
import getNamespaceWrapper from '@salesforce/apex/BDI_ManageAdvancedMappingCtrl.getNamespaceWrapper';

import stgUnknownError from '@salesforce/label/c.stgUnknownError';

const channelNameContexts = {
    IS_FULL_NAME: 'isFullName',
    IN_NAMESPACE_CONTEXT_IS_NAMESPACED: 'inNamespaceContextIsNamespaced',
    IN_NAMESPACE_CONTEXT_NOT_NAMESPACED: 'inNamespaceContextNotNamespaced',
    NOT_IN_NAMESPACE_CONTEXT: 'notInNamespaceContext',
    UNDEFINED: 'undefined',
    DEFAULT: 'default'
}

export default class PlatformEventListener extends LightningElement {

    /*******************************************************************************
    * @description Public property for the default channel name or platform event
    * name to subscribe to. Parent component can set the value to a channel name or
    * platform event name.
    */
    @api channelName;

    _fullChannelName;
    nsWrapper;
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
        this.nsWrapper = await getNamespaceWrapper();

        this.handleChannelName();
        this.handleSubscribe();
        setDebugFlag(this.isDebugFlagEnabled);
    }

    classifyChannelName() {
        let isFullName = this.channelName && this.channelName.includes('/event/');

        let isNamespaceContext = this.nsWrapper.currentNamespace && this.nsWrapper.currentNamespace !== '';
        let isChannelNamespaced = this.channelName && this.channelName.includes(`${this.nsWrapper.currentNamespace}__`);

        if (isFullName) {
            return channelNameContexts.IS_FULL_NAME;
        } else if (isNamespaceContext && isChannelNamespaced) {
            return channelNameContexts.IN_NAMESPACE_CONTEXT_IS_NAMESPACED;
        } else if (isNamespaceContext && !isChannelNamespaced) {
            return channelNameContexts.IN_NAMESPACE_CONTEXT_NOT_NAMESPACED;
        } else if (this.channelName && !isNamespaceContext) {
            return channelNameContexts.NOT_IN_NAMESPACE_CONTEXT
        } else if (!this.channelName) {
            return channelNameContexts.UNDEFINED;
        }

        return channelNameContexts.DEFAULT;
    }

    handleChannelName() {
        let category = this.classifyChannelName();

        switch (category) {
            case channelNameContexts.IS_FULL_NAME:
                this._fullChannelName = this.channelName;
                break;

            case channelNameContexts.IN_NAMESPACE_CONTEXT_IS_NAMESPACED:
                this._fullChannelName = `/event/${this.channelName}`;
                break;

            case channelNameContexts.IN_NAMESPACE_CONTEXT_NOT_NAMESPACED:
                this._fullChannelName = `/event/${this.nsWrapper.currentNamespace}__${this.channelName}`;
                break;

            case channelNameContexts.NOT_IN_NAMESPACE_CONTEXT:
                this._fullChannelName = `/event/${this.channelName}`;
                break;

            case channelNameContexts.UNDEFINED:
                this.handleError({
                    name: 'Error',
                    message: `Invalid or missing channel '${this.channelName}'`
                });
                break;

            default: {
                let namespace = this.getNamespacePrefixString();
                this._fullChannelName = `/event/${namespace}DeploymentEvent__e`;
            }
        }
    }

    getNamespacePrefixString(){
        return this.nsWrapper.currentNamespace && this.nsWrapper.currentNamespace !== '' ? this.nsWrapper.currentNamespace + '__' : '';
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
        let nsPrefix = this.getNamespacePrefixString();

        const status = response.data.payload[nsPrefix + 'Status__c'];
        const deploymentId = response.data.payload[nsPrefix + 'DeploymentId__c'];

        const evt = new ShowToastEvent({
            title: 'Deployment completed with Status: ' + status,
            message: 'Deployment Id: ' + deploymentId,
            variant: 'success',
        });
        this.dispatchEvent(evt);
    }

    log(response) {
        let nsPrefix = this.getNamespacePrefixString();
        
        const status = response.data.payload[nsPrefix + 'Status__c'];
        const deploymentId = response.data.payload[nsPrefix + 'DeploymentId__c'];
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
    }

    handleEventReceived(response) {
        let nsPrefix = this.getNamespacePrefixString();
        const deploymentId = response.data.payload[nsPrefix + 'DeploymentId__c'];

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
        this.handleError(error);
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
        if (error && error.status && error.body) {
            this.errorToast(`${error.status} ${error.statusText}`, error.body.message, 'error', 'sticky');
        } else if (error && error.name && error.message) {
            this.errorToast(`${error.name}`, error.message, 'error', 'sticky');
        } else {
            this.errorToast(stgUnknownError, '', 'error', 'sticky');
        }
    }
}
