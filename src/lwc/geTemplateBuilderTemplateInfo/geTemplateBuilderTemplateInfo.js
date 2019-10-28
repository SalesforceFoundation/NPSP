import { LightningElement, api, track } from 'lwc';
import { mutable } from 'c/utilTemplateBuilder';

export default class geTemplateBuilderTemplateInfo extends LightningElement {
    @track templateInfo;

    /* Public setter for the tracked property templateInfo */
    // TODO: Needs to be revisited, WIP tied to retrieving and rendering an existing template
    @api
    set templateInfo(templateInfo) {
        this.templateInfo = templateInfo;
    }

    /*******************************************************************************
    * @description Public method that returns the templateInfo object. Called when
    * saving a form template.
    *
    * @return {object} templateInfo: Object containing the template name and description
    */
    @api
    getTabData() {
        let templateInfo = mutable(this.templateInfo);
        templateInfo.name = this.template.querySelector('lightning-input[data-name="templateName"]').value;
        templateInfo.description = this.template.querySelector('lightning-textarea[data-name="description"]').value;

        return templateInfo;
    }

    /*******************************************************************************
    * @description Sends an event up to geTemplateBuilder for tab navigation
    * Currently also collecting data from the page to send up with event.
    * Likely to change this behavior later when more comprehensively look at
    * the way to collect/pass tab data around.
    *
    * @param {object} event: Onclick event object from lightning-button
    */
    handleGoToTab(event) {
        let detail = {
            tabValue: event.target.getAttribute('data-tab-value')
        }
        this.dispatchEvent(new CustomEvent('gototab', { detail: detail }));
    }
}