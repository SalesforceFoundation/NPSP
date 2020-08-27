import {api, LightningElement, track} from 'lwc';
import GeLabelService from 'c/geLabelService';
import getOrgDomainInfo from '@salesforce/apex/GE_GiftEntryController.getOrgDomainInfo';
import getPaymentTransactionStatusValues
    from '@salesforce/apex/GE_PaymentServices.getPaymentTransactionStatusValues';
import {format, getNamespace, isFunction} from 'c/utilCommon';
import {
    fireEvent,
    registerListener,
    unregisterListener,
} from 'c/pubsubNoPageRef';
import DATA_IMPORT_OBJECT from '@salesforce/schema/DataImport__c';
import DATA_IMPORT_PAYMENT_AUTHORIZATION_TOKEN_FIELD
    from '@salesforce/schema/DataImport__c.Payment_Authorization_Token__c';
import DATA_IMPORT_PAYMENT_STATUS_FIELD
    from '@salesforce/schema/DataImport__c.Payment_Status__c';
import {
    DISABLE_TOKENIZE_WIDGET_EVENT_NAME,
    LABEL_NEW_LINE,
    WIDGET_TYPE_DI_FIELD_VALUE,
} from 'c/geConstants';

const TOKENIZE_TIMEOUT = 10000; // 10 seconds
const TOKENIZE_CARD_PAGE_NAME = 'GE_TokenizeCard';

export default class geFormWidgetTokenizeCard extends LightningElement {
    @api cardHolderName;

    @track domain;
    @track visualforceOrigin;
    @track isLoading = true;
    @track alert = {};
    @track disabledMessage;
    @track isDisabled = false;
    @track hasUserDisabledWidget = false;
    @track hasEventDisabledWidget = false;
    _visualforceOriginUrls;

    CUSTOM_LABELS = GeLabelService.CUSTOM_LABELS;
    PAYMENT_TRANSACTION_STATUS_ENUM;

    get displayDoNotChargeCardButton() {
        return !(this.hasEventDisabledWidget || this.hasUserDisabledWidget);
    }

    get tokenizeCardPageUrl() {
        const namespace = getNamespace(DATA_IMPORT_OBJECT.objectApiName);
        if (namespace) return `/apex/${namespace}__${TOKENIZE_CARD_PAGE_NAME}`;

        return `/apex/${TOKENIZE_CARD_PAGE_NAME}`;
    }

    async connectedCallback() {
        this.PAYMENT_TRANSACTION_STATUS_ENUM = Object.freeze(JSON.parse(await getPaymentTransactionStatusValues()));
        this.domainInfo = await getOrgDomainInfo();
        this._visualforceOriginUrls = this.buildVisualforceOriginUrls();
    }

    renderedCallback() {
        this.registerPostMessageListener();
        registerListener(DISABLE_TOKENIZE_WIDGET_EVENT_NAME, this.handleEventDisabledWidget, this);
    }

    disconnectedCallback() {
        unregisterListener(DISABLE_TOKENIZE_WIDGET_EVENT_NAME);
    }

    /*******************************************************************************
    * @description Handles a user's onclick event for disabling the widget.
    */
    handleUserDisabledWidget() {
        this.toggleWidget(true);
        this.hasUserDisabledWidget = true;
        this.dispatchApplicationEvent('doNotChargeState', {
            isWidgetDisabled : this.hasUserDisabledWidget
        });
    }

    /*******************************************************************************
    * @description Handles a user's onclick event for re-enabling the widget.
    */
    handleUserEnabledWidget() {
        this.isLoading = true;
        this.toggleWidget(false);
        this.hasUserDisabledWidget = false;
        this.dispatchApplicationEvent('doNotChargeState', {
            isWidgetDisabled : this.hasUserDisabledWidget
        });
    }

    /*******************************************************************************
    * @description Handles receipt of an event to disable this widget. Currently
    * used when we've charged a card, but BDI processing failed.
    */
    handleEventDisabledWidget(event) {
        this.toggleWidget(true, event.detail.message);
        this.hasEventDisabledWidget = true;
    }

    /*******************************************************************************
    * @description Function enables or disables the widget based on provided args.
    *
    * @param {boolean} isDisabled: Determines whether or not the widget is disabled.
    * @param {string} message: Text to be disabled in the widgets body when disabled.
    */
    toggleWidget(isDisabled, message) {
        this.isDisabled = isDisabled;
        this.disabledMessage = message || null;
    }

    /*******************************************************************************
    * @description Builds the visualforce origin url that we need in order to
    * make sure we're only listening for messages from the correct source in the
    * registerPostMessageListener method.
    */
    buildVisualforceOriginUrls() {
        let url = `https://${this.domainInfo.orgDomain}--c.visualforce.com`;
        let alternateUrl = `https://${this.domainInfo.orgDomain}--c.${this.domainInfo.podName}.visual.force.com`;
        const currentNamespace = getNamespace(
            DATA_IMPORT_PAYMENT_AUTHORIZATION_TOKEN_FIELD.fieldApiName);
        if (currentNamespace) {
            url = url.replace('--c', `--${currentNamespace}`);
            alternateUrl = alternateUrl.replace('--c', `--${currentNamespace}`);
        }
        return [{value: url}, {value: alternateUrl}];
    }

    /*******************************************************************************
    * @description Method listens for a message from the visualforce iframe.
    * Rejects any messages from an unknown origin.
    */
    registerPostMessageListener() {
        let component = this;
        window.onmessage = async function (event) {
            component.visualforceOrigin = component._visualforceOriginUrls.find(
                origin => event.origin === origin.value).value;
            if (component.visualforceOrigin) {
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
        if (message.error || message.token) {
            if (isFunction(this.tokenCallback)) {
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

        if (iframe) {
            const tokenPromise = new Promise((resolve, reject) => {

                const timer = setTimeout(() => reject(this.handleTokenizationTimeout()), TOKENIZE_TIMEOUT);

                this.tokenCallback = message => {
                    clearTimeout(timer);
                    this.alert = {};
                    if (message.error) {
                        reject(this.handleTokenizationError(message));
                    } else if (message.token) {
                        resolve({
                            [DATA_IMPORT_PAYMENT_AUTHORIZATION_TOKEN_FIELD.fieldApiName]: message.token,
                            [DATA_IMPORT_PAYMENT_STATUS_FIELD.fieldApiName]: this.PAYMENT_TRANSACTION_STATUS_ENUM.PENDING
                        });
                    }
                };

            });

            iframe.contentWindow.postMessage(
                { action: 'createToken' },
                this.visualforceOrigin);

            return tokenPromise;
        }
    }

    handleTokenizationTimeout() {
        return {
            error: this.CUSTOM_LABELS.gePaymentRequestTimedOut,
            isObject: false
        };
    }

    handleTokenizationError(message) {
        this.alert = {
            theme: 'error',
            show: true,
            message: this.CUSTOM_LABELS.gePaymentProcessingErrorBanner,
            variant: 'inverse',
            icon: 'utility:error'
        };
        let errorValue;
        let isObject = false;
        if (typeof message.error === 'object') {
            errorValue = JSON.stringify(Object.values(message.error));
            isObject = true;
        } else if (typeof message.error === 'string') {
            errorValue = message.error;
        }
        let labelReplacements = [this.CUSTOM_LABELS.commonPaymentServices, errorValue];

        /** This event can be used to extend handling payment errors at the form level by adding additional detail
         * objects.
         * We use the hex value for line feed (new line) 0x0A
         */
        let formattedErrorResponse = format(this.CUSTOM_LABELS.gePaymentProcessError, labelReplacements);
        let splitErrorResponse = formattedErrorResponse.split(LABEL_NEW_LINE);
        return {
            error: {
                message: splitErrorResponse,
                isObject: isObject
            }
        };
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
    load() { }

    @api
    reset() { }

    @api
    get allFieldsByAPIName() {
        return [DATA_IMPORT_PAYMENT_AUTHORIZATION_TOKEN_FIELD.fieldApiName];
    }

    @api
    setNameOnCard(cardHolderName) {
        this.cardHolderName = cardHolderName;
    }

    dispatchApplicationEvent (eventName, payload) {
        fireEvent(null, eventName, payload);
    }
}
