
import { fireEvent } from 'c/pubsubNoPageRef';
import { getNamespace, isFunction } from 'c/utilCommon';

import PAYMENT_AUTHORIZATION_TOKEN_FIELD from '@salesforce/schema/DataImport__c.Payment_Authorization_Token__c';
import tokenRequestTimedOut from '@salesforce/label/c.gePaymentRequestTimedOut';


/***
* @description Visualforce page for the credit card tokenization
*/
const TOKENIZE_CARD_PAGE_NAME = 'GE_TokenizeCard';

/***
* @description Event action sent to the Visualforce page to request the token
*/
const TOKENIZE_EVENT_ACTION = 'createToken';

/***
* @description Max number of ms to wait for the response
*/
const TOKENIZE_TIMEOUT_MS = 10000;


class PSElevateCommon {
    /***
    * @description Max number of ms to wait for the response
    */
    labels = Object.freeze({
        tokenRequestTimedOut
    });


    /***
    * @description Returns tokenize card Visualforce page URL
    */
    getTokenizeCardPageURL() {
        const namespace = this.getCurrentNamespace();

        return namespace
            ? `/apex/${namespace}__${TOKENIZE_CARD_PAGE_NAME}`
            : `/apex/${TOKENIZE_CARD_PAGE_NAME}`;
    }

    /***
    * @description Builds the visualforce origin url that we need in order to
    * make sure we're only listening for messages from the correct source in the
    * registerPostMessageListener method.
    */
    getVisualforceOriginURLs(domainInfo) {
        const namespace = this.getCurrentNamespace();

        let url = `https://${domainInfo.orgDomain}--c.visualforce.com`;
        let alternateUrl = `https://${domainInfo.orgDomain}--c.${domainInfo.podName}.visual.force.com`;

        if (namespace) {
            url = url.replace('--c', `--${namespace}`);
            alternateUrl = alternateUrl.replace('--c', `--${namespace}`);
        }

        return [{ value: url }, { value: alternateUrl }];
    }

    /***
    * @description
    */
    getCurrentNamespace() {
        return getNamespace(PAYMENT_AUTHORIZATION_TOKEN_FIELD.fieldApiName);
    }

    /***
    * @description
    */
    dispatchApplicationEvent(eventName, payload) {
        fireEvent(null, eventName, payload);
    }

    /***
    * @description Method listens for a message from the visualforce iframe.
    * Rejects any messages from an unknown origin.
    */
    registerPostMessageListener(component) {
        window.onmessage = async function (event) {
            component.visualforceOrigin = component.visualforceOriginUrls.find(
                origin => event.origin === origin.value
            ).value;

            if (component.visualforceOrigin) {
                const message = JSON.parse(event.data);
                component.handleMessage(message);
            }
        }
    }

    /***
    * @description Method handles messages received from iframed visualforce page.
    *
    * @param {object} message: Message received from iframe
    */
    handleMessage(message) {
        if (message.error || message.token) {
            if (isFunction(this.tokenCallback)) {
                this.tokenCallback(message);
            }
        } 
    }

    /***
    * @description Method sends a message to the visualforce page iframe requesting
    * a token. Response for this request is found and handled in
    * registerPostMessageListener.
    */
    requestToken(visualforceOrigin, iframe, handleError) {
        if (iframe) {
            const tokenPromise = new Promise((resolve, reject) => {

                const timer = setTimeout(() => 
                    reject(this.handleTimeout(handleError)), 
                    TOKENIZE_TIMEOUT_MS
                );

                this.tokenCallback = message => {
                    clearTimeout(timer);

                    if (message.error) {
                        reject(handleError(message));

                    } else if (message.token) {
                        resolve(message.token);
                    }
                };

            });

            iframe.contentWindow.postMessage(
                { action: TOKENIZE_EVENT_ACTION },
                visualforceOrigin
            );

            return tokenPromise;
        }
    }

    /**
     *
     */
    handleTimeout(handleError) {
        const message = {
            error: this.labels.tokenRequestTimedOut,
            isObject: false
        };

        handleError(message);
    }
}


export default new PSElevateCommon();
