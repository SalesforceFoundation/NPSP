import { LightningElement, api, track } from 'lwc';
import { TabData } from 'c/utilTemplateBuilder';

export default class geTemplateBuilderTemplateInfo extends LightningElement {
    @track templateInfo;

    /* Needs to be revisited, WIP tied to retrieving and rendering an existing template */
    @api
    set templateInfo(templateInfo) {
        this.templateInfo = templateInfo;
    }
    
    @api
    getTabData() {
        let tabData = new TabData(
            'geTemplateBuilderTemplateInfo',
            this.template.querySelector('lightning-input[data-name="templateName"]').value,
            this.template.querySelector('lightning-textarea[data-name="description"]').value
        );

        return tabData;
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
        let tabData = this.getTabData();

        let detail = {
            tabData: tabData,
            tabValue: event.target.getAttribute('data-tab-value')
        }

        this.dispatchEvent(new CustomEvent('gototab', { detail: detail }));
    }
}