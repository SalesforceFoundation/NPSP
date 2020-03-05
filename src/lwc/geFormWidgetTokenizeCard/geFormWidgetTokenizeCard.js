import { LightningElement, track } from 'lwc';
import GeLabelService from 'c/geLabelService';
import getDomainUrl from '@salesforce/apex/GE_FormRendererService.getDomainUrl';
import makePurchaseCall from '@salesforce/apex/GE_FormRendererService.makePurchaseCall';
// TODO: maybe import data import token field reference?

export default class geFormWidgetTokenizeCard extends LightningElement {

    CUSTOM_LABELS = GeLabelService.CUSTOM_LABELS;
    
    @track domain;
    @track visualforceOrigin;
    //@track lightningOrigin;
    @track tokenizeCardPageUrl;
    @track isLoading;

    async connectedCallback() {
        let domainUrl = await getDomainUrl();
        this.domain = domainUrl.split('.')[0];
        this.visualforceOrigin = `https://${this.domain}--npsp.visualforce.com`;
        this.tokenizeCardPageUrl = `${this.visualforceOrigin}/apex/GE_TokenizeCard`;
        //this.lightningOrigin = `https://${this.domain}.lightning.force.com`;
    }

    renderedCallback() {
        this.registerPostMessageListener();
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
                component.handlePostMessage(message);
            }
        }
    }

    /*******************************************************************************
    * @description Method handles making a purchase call using a token from the
    * received message.
    *
    * @param {object} message: Message received from a tokenization call
    */
    async handlePostMessage(message) {
        if (message.error) {
            let error = JSON.stringify(message.error);
            console.log(error);
            alert(error);
        } else if (message.token) {
            // TODO: Start - Remove later
            // Make purchase call... for dev only
            let purchaseCallResponse = await makePurchaseCall({ token: message.token });
            this.purchaseResult = JSON.parse(purchaseCallResponse);
            console.log(this.purchaseResult);
            alert(this.purchaseResult)
            // TODO: End - Remove later

            // TODO: Save token locally in widget until form requests it
        }
    }

    /*******************************************************************************
    * @description Method sends a message to the visualforce page iframe requesting
    * a token. Response for this request is found and handled in
    * registerPostMessageListener.
    */
    requestToken() {
        const iframe = this.template.querySelector('iframe');

        if (iframe) {
            iframe.contentWindow.postMessage(
                { action: 'createToken' },
                this.visualforceOrigin);
        }
    }
}