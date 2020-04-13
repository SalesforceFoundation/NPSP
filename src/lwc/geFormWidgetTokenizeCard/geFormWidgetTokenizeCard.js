import { LightningElement, track, api } from 'lwc';
import GeLabelService from 'c/geLabelService';
import TemplateBuilderService from 'c/geTemplateBuilderService';
import getOrgDomain from '@salesforce/apex/GE_GiftEntryController.getOrgDomain';
import { isFunction } from 'c/utilCommon';
import DATA_IMPORT_PAYMENT_AUTHORIZATION_TOKEN_FIELD from '@salesforce/schema/DataImport__c.Payment_Authorization_Token__c';
import { WIDGET_TYPE_DI_FIELD_VALUE } from 'c/geConstants';

const TOKENIZE_TIMEOUT = 10000; // 10 seconds

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
    handleMessage(message) {
        if (message.error || message.token) {
            if(isFunction(this.tokenCallback)) {
                this.tokenCallback(message);
            }
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

        const tokenPromise = new Promise((resolve, reject) => {

            const timer = setTimeout(() => {
                reject('Request timed out');
            }, TOKENIZE_TIMEOUT);

            this.tokenCallback = message => {
                clearTimeout(timer);
                if(message.error) {
                    reject(message);
                } else if(message.token) {
                    resolve({ [DATA_IMPORT_PAYMENT_AUTHORIZATION_TOKEN_FIELD.fieldApiName]: message.token });
                }
            };

        });

        if (iframe) {
            iframe.contentWindow.postMessage(
                { action: 'createToken' },
                this.visualforceOrigin);
        }

        return tokenPromise;
    }

    /**
     * Requests a payment token when the form is saved
     * @return {paymentToken: Promise<*>} Promise that will resolve to the token
     */
    @api
    returnValues() {
        return {
            type: WIDGET_TYPE_DI_FIELD_VALUE,
            payload: this.requestToken()
        };
    }

    @api
    load() {}

    @api
    reset() {}

    @api
    get allFieldsByAPIName() {
        return [DATA_IMPORT_PAYMENT_AUTHORIZATION_TOKEN_FIELD.fieldApiName];
    }

    @api
    setNameOnCard(cardHolderName) {
        this.cardHolderName = cardHolderName;
    }
}