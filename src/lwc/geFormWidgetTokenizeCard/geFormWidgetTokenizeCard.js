import { LightningElement, track, api } from 'lwc';
import GeLabelService from 'c/geLabelService';
import { registerListener, unregisterListener, fireEvent } from 'c/pubsubNoPageRef';
import TemplateBuilderService from 'c/geTemplateBuilderService';
import getOrgDomain from '@salesforce/apex/GE_GiftEntryController.getOrgDomain';
import { handleError } from 'c/utilTemplateBuilder';
// TODO: maybe import data import token field reference?

export default class geFormWidgetTokenizeCard extends LightningElement {

    CUSTOM_LABELS = GeLabelService.CUSTOM_LABELS;
    
    tokenizeCardPageUrl = '/apex/GE_TokenizeCard';
    @track domain;
    @track visualforceOrigin;
    @track isLoading = true;
    @api cardHolderName;


    get tokenizeCardHeader() {
        return GeLabelService.format(
            this.CUSTOM_LABELS.geHeaderPaymentServices,
            [this.CUSTOM_LABELS.commonPaymentServices]);
    }

    async connectedCallback() {
        this.domain = await getOrgDomain();
        this.visualforceOrigin = this.buildVisualforceOriginUrl(this.domain);
    }

    renderedCallback() {
        this.registerPostMessageListener();
    }

    @api
    isValid() {
        return true;
    }

    /*******************************************************************************
    * @description Builds the visualforce origin url that we need in order to
    * make sure we're only listening for messages from the correct source in the
    * registerPostMessageListener method.
    */
    buildVisualforceOriginUrl(domain) {
        let url = `https://${domain}--c.visualforce.com`
        if (TemplateBuilderService.namespaceWrapper) {
            const currentNamespace = TemplateBuilderService.namespaceWrapper.currentNamespace;

            if (currentNamespace) {
                url = url.replace('--c', `--${currentNamespace}`);
            }
        }

        return url;
    }

    /*******************************************************************************
    * @description Method listens for a message from the visualforce iframe.
    * Rejects any messages from an unknown origin.
    */
    registerPostMessageListener() {
        let component = this;

        window.onmessage = async function (event) {
            if (event && event.origin !== component.visualforceOrigin) {
                // Reject any messages from an unexpected origin
                return;
            } else {
                const message = JSON.parse(event.data);
                component.handleMessage(message);
            }
        }
    }

    /*******************************************************************************
    * @description Method handles messages received from iframed visualforce page.
    *
    * @param {object} message: Message received from iframe
    */
    async handleMessage(message) {
        fireEvent(null, 'tokenResponse', message); // move so we can handle error or token
        if (message.error) {
            // Error with tokenization
        } else if (message.token) {
            this.token = message.token;
        } else if (message.isLoaded) {
            this.isLoading = false;
        }
    }

    /*******************************************************************************
    * @description Method sends a message to the visualforce page iframe requesting
    * a token. Response for this request is found and handled in
    * registerPostMessageListener.
    */
    requestToken() {
        const iframe = this.template.querySelector(`[data-id='${this.CUSTOM_LABELS.commonPaymentServices}']`);
        fireEvent(null, 'tokenRequested');

        if (iframe) {
            iframe.contentWindow.postMessage(
                { action: 'createToken' },
                this.visualforceOrigin);
        }
    }

    @api
    returnValues() {
        this.requestToken();
    }

    @api
    load() {}

    @api
    reset() {}

    @api
    setNameOnCard(cardHolderName) {
        this.cardHolderName = cardHolderName;
    }
}