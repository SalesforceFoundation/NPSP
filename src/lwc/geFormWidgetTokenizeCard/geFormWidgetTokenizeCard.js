import { LightningElement, track, api } from 'lwc';
import GeLabelService from 'c/geLabelService';
import TemplateBuilderService from 'c/geTemplateBuilderService';
import getOrgDomain from '@salesforce/apex/GE_GiftEntryController.getOrgDomain';
// TODO: temporary makePurchaseCall import below. Remove later.
import makePurchaseCall from '@salesforce/apex/GE_GiftEntryController.makePurchaseCall';
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
        if (message.error) {
            // Error with tokenization
            let error = JSON.stringify(message.error);
            handleError(error);
        } else if (message.token) {
            // TODO: Start - Remove later
            // Make purchase call... for dev only
            try {
                let purchaseCallResponse = await makePurchaseCall({ token: message.token });
                this.purchaseResult = JSON.parse(purchaseCallResponse);
            } catch (error) {
                handleError(error);
            }
            // TODO: End - Remove later

            // TODO: Save token locally in widget until form requests it
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

        if (iframe) {
            iframe.contentWindow.postMessage(
                { action: 'createToken' },
                this.visualforceOrigin);
        }
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