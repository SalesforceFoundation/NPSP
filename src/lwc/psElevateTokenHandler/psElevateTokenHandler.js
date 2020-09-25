
import { fireEvent } from 'c/pubsubNoPageRef';
import { getNamespace, isFunction, isNull } from 'c/utilCommon';

import PAYMENT_AUTHORIZATION_TOKEN_FIELD from '@salesforce/schema/DataImport__c.Payment_Authorization_Token__c';
import tokenRequestTimedOut from '@salesforce/label/c.gePaymentRequestTimedOut';


/***
* @description Visualforce page used to handle the payment services credit card tokenization request
*/
const TOKENIZE_CARD_PAGE_NAME = 'GE_TokenizeCard';

/***
* @description Event action sent to the Visualforce page to request the token
*/
const TOKENIZE_EVENT_ACTION = 'createToken';

/***
* @description Max number of ms to wait for the response containing a token or an error
*/
const TOKENIZE_TIMEOUT_MS = 10000;


/***
* @description Payment services Elevate credit card tokenization service
*/
class psElevateTokenHandler {
    /***
    * @description Custom labels
    */
    labels = Object.freeze({
        tokenRequestTimedOut
    });


    /***
    * @description Returns credit card tokenization Visualforce page URL
    */
    getTokenizeCardPageURL() {
        const namespace = this.getCurrentNamespace();

        return namespace
            ? `/apex/${namespace}__${TOKENIZE_CARD_PAGE_NAME}`
            : `/apex/${TOKENIZE_CARD_PAGE_NAME}`;
    }

    /***
    * @description Builds the Visualforce origin url that we need in order to
    * make sure we're only listening for messages from the correct source.
    */
    getVisualforceOriginURLs(domainInfo) {
        if (isNull(domainInfo)) {
            return;
        }

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
    * @description Returns the NPSP namespace (if any)
    */
    getCurrentNamespace() {
        return getNamespace(PAYMENT_AUTHORIZATION_TOKEN_FIELD.fieldApiName);
    }

    /***
    * @description Dispatches the application event when the Elevate credit card iframe
    * is displayed or hidden
    */
    dispatchApplicationEvent(eventName, payload) {
        fireEvent(null, eventName, payload);
    }

    /***
    * @description Listens for a message from the Visualforce iframe.
    * Rejects any messages from an unknown origin.
    */
    registerPostMessageListener(component) {
        window.onmessage = async function (event) {
            if (component.visualforceOriginUrls) {
                component.visualforceOrigin = component.visualforceOriginUrls.find(
                    origin => event.origin === origin.value
                ).value;
            }

            if (component.visualforceOrigin) {
                const message = JSON.parse(event.data);
                component.handleMessage(message);
            }
        }
    }

    /***
    * @description Handles messages received from Visualforce page.
    * @param message Message received from the iframe
    */
    handleMessage(message) {
        if (message.error || message.token) {
            if (isFunction(this.tokenCallback)) {
                this.tokenCallback(message);
            }
        }
    }

    /***
    * @description Method sends a message to the visualforce page iframe requesting a token.
    * This request response is found and handled in the registerPostMessageListener().
    * @param visualforceOrigin Visualforce origin
    * @param iframe The payment services iframe displayed within the credit card widget LWC
    * @param nameOnCard The cardholder name value
    * @param handleError An error handler function
    * @return Promise A token promise
    */
    requestToken(visualforceOrigin, iframe, nameOnCard, handleError) {
        if (isNull(iframe)) {
            return;
        }

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
            {
                action: TOKENIZE_EVENT_ACTION,
                nameOnCard: nameOnCard
            },
            visualforceOrigin
        );

        return tokenPromise;
    }

    /**
     * Handles a timeout error display when the tokenization
     * request does not result in a response
     */
    handleTimeout(handleError) {
        const message = {
            error: this.labels.tokenRequestTimedOut,
            isObject: false
        };

        handleError(message);
    }
}

/**
 * A new instance of the Elevate tokenization handler
 */
export default new psElevateTokenHandler();
