import { LightningElement, api } from 'lwc';
import { dispatch } from 'c/utilTemplateBuilder';

export default class geTemplateBuilderTemplateInfo extends LightningElement {
    @api isLoading;
    @api templateName;
    @api templateDescription;

    /*******************************************************************************
    * @description Handles onblur event from lightning-input and dispatches an
    * event to notify parent component geTemplateBuilder that the form template
    * description has changed.
    *
    * @param {object} event: Event object from lightning-input onblur event handler
    * @return {object} templateInfo: Object containing the template name and description
    */
    handleChangeTemplateInfoName(event) {
        dispatch(this, 'changetemplateinfoname', event.target.value);
    }

    /*******************************************************************************
    * @description Handles onblur event from lightning-textarea and dispatches an
    * event to notify parent component geTemplateBuilder that the form template
    * description has changed.
    *
    * @param {object} event: Event object from lightning-textarea onblur event handler
    * @return {object} templateInfo: Object containing the template name and description
    */
    handleChangeTemplateInfoDescription(event) {
        dispatch(this, 'changetemplateinfodescription', event.target.value);
    }
}