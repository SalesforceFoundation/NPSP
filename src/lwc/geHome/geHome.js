import { LightningElement, api } from 'lwc';
import { getQueryParameters, deepClone } from 'c/utilCommon';
import { dispatch, handleError } from 'c/utilTemplateBuilder';

const EVENT_TOGGLE_MODAL = 'togglemodal';
const SAVE = 'save';

export default class geHome extends LightningElement {

    connectedCallback() {
        console.log('*************--- connectedCallback');
    }

    /*******************************************************************************
    * @description Public method for receiving modal related events from geListView.
    *
    * @param {object} modalData: Event object containing the action and modal payload.
    * component chain: utilDualListbox -> geListView -> here.
    */
    @api
    notify(event) {
        console.log('*******--- notify: ', deepClone(event));
        if (event.componentName) {
            if (event.action === SAVE) {
                const component = this.template.querySelector(`c-${event.componentName}`);
                if (component) {
                    component.notify(event);
                }
            }
        }
    }

    /*******************************************************************************
    * @description Pass through method that receives an event from geListView to
    * notify parent aura component to construct a modal.
    *
    * @param {object} event: Event object containing a payload for the modal.
    */
    toggleModal(event) {
        console.log('toggleModal');
        dispatch(this, EVENT_TOGGLE_MODAL, event.detail);
    }
}