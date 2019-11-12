import { LightningElement, api } from 'lwc';
import { registerListener, unregisterAllListeners } from 'c/pubsubNoPageRef';
import { dispatch } from 'c/utilTemplateBuilder';

const RECEIVE_EVENT = 'receiveevent';

export default class utilDedicatedListener extends LightningElement {
    @api eventName;

    connectedCallback() {
        registerListener(this.eventName, this.handleEvent, this);
    }

    disconnectedCallback() {
        unregisterAllListeners();
    }

    handleEvent(event) {
        dispatch(this, RECEIVE_EVENT, event);
    }
}