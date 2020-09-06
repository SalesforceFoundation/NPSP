import { api, track, LightningElement } from 'lwc';

import psElevateCommon from 'c/psElevateCommon';
import getOrgDomainInfo from '@salesforce/apex/PS_ElevateController.getOrgDomainInfo';

import commonPaymentServices from '@salesforce/label/c.commonPaymentServices';
import assistiveSpinner from '@salesforce/label/c.geAssistiveSpinner';

import rd2ElevateDisableLabel from '@salesforce/label/c.RD2_ElevateDisableLabel';
import rd2ElevateDisabledMessage from '@salesforce/label/c.RD2_ElevateDisabledMessage';
import rd2ElevateEnableLabel from '@salesforce/label/c.RD2_ElevateEnableLabel';

const WIDGET_DISABLED_EVENT_NAME = 'rd2TokenizeCardWidgetDisabled';

export default class psElevateCreditCardForm extends LightningElement {

    labels = {
        commonPaymentServices,
        assistiveSpinner,
        rd2ElevateDisableLabel,
        rd2ElevateDisabledMessage,
        rd2ElevateEnableLabel
    };

    @api cardHolderName;

    @track visualforceOrigin;
    @track visualforceOriginUrls;

    @track isLoading = true;
    @track isDisabled = false;
    @track alert = {};

    /***
    * @description
    */
    async connectedCallback() {
        const domainInfo = await getOrgDomainInfo();

        this.visualforceOriginUrls = psElevateCommon.getVisualforceOriginURLs(domainInfo);
    }

    /***
    * @description
    */
    renderedCallback() {
        let component = this;
        psElevateCommon.registerPostMessageListener(component);
    }

    /***
    * @description
    */
    disconnectedCallback() {
    }


    /***
    * @description 
    */
    get tokenizeCardPageUrl() {
        return psElevateCommon.getTokenizeCardPageURL();
    }

    /***
    * @description Handles a user's onclick event for disabling the widget.
    */
    handleUserDisabledWidget() {
        this.hideWidget();
        psElevateCommon.dispatchApplicationEvent(WIDGET_DISABLED_EVENT_NAME, {
            isWidgetDisabled: true
        });
    }

    /***
    * @description Handles a user's onclick event for re-enabling the widget.
    */
    handleUserEnabledWidget() {
        this.isLoading = true;
        this.displayWidget();
        psElevateCommon.dispatchApplicationEvent(WIDGET_DISABLED_EVENT_NAME, {
            isWidgetDisabled: false
        });
    }

    /***
    * @description Function enables or disables the widget based on provided args.
    */
    displayWidget() {
        this.isDisabled = false;
        this.clearError();
    }

    /***
    * @description Function enables or disables the widget based on provided args.
    */
    hideWidget() {
        this.isDisabled = true;
        this.clearError();
    }

    /***
    * @description Method handles messages received from iframed visualforce page.
    *
    * @param {object} message: Message received from iframe
    */
    async handleMessage(message) {
        psElevateCommon.handleMessage(message);
        
        if (message.isLoaded) {
            this.isLoading = false;
        }
    }

    /***
    * @description Method sends a message to the visualforce page iframe requesting
    * a token. Response for this request is found and handled in
    * registerPostMessageListener.
    */
    requestToken() {
        const iframe = this.template.querySelector(`[data-id='${this.labels.commonPaymentServices}']`);

        return psElevateCommon.requestToken(this.visualforceOrigin, iframe, this.handleError);
    }

    /**
     *
     */
    handleError = (message) => {
        let errorValue;
        let isObject = false;

        if (typeof message.error === 'object') {
            errorValue = JSON.stringify(Object.values(message.error));
            isObject = true;

        } else if (typeof message.error === 'string') {
            errorValue = message.error;
        }

        this.alert = {
            theme: 'error',
            show: true,
            message: errorValue,
            variant: 'inverse',
            icon: 'utility:error'
        };

        return {
            error: {
                message: errorValue,
                isObject: isObject
            }
        };
    }

    /**
     * 
     */
    clearError() {
        this.alert = {};
    }

    /**
     * Requests a payment token when the form is saved
     * @return {paymentToken: Promise<*>} Promise that will resolve to the token
     */
    @api
    returnValues() {
        return {
            payload: this.requestToken()
        };
    }

    @api
    setNameOnCard(cardHolderName) {
        this.cardHolderName = cardHolderName;
    }

}
