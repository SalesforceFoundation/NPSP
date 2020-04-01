/**
 * Created by d.fuller on 4/1/20.
 */

import {LightningElement, api} from 'lwc';
import {isEmpty} from "c/utilCommon";

export default class NotificationCard extends LightningElement {
    /**
     * Valid values are error, warning, or info
     */
    @api theme;
    /**
     * Determines if the card will display in the UI
     * @type boolean
     */
    @api show;


    get headerClass() {
        const headerDefault = 'slds-card__header slds-p-around_small card-border-radius ' +
            'slds-grid';

        if(isEmpty(this.theme)) {
            const headerBackgroundDefault = 'none';
            return headerDefault.concat(headerDefault, ('bg-' + headerBackgroundDefault));
        }

        return headerDefault.concat(' slds-text-color_inverse ', ('bg-' + this.theme));
    }

    get bodyClass() {
        const bodyDefault = 'slds-text-color_';
        const bodyTextDefault = 'default';

        if (isEmpty(this.theme)) {
            return bodyDefault.concat(bodyTextDefault);
        }

        return bodyDefault.concat(this.theme);
    }
}