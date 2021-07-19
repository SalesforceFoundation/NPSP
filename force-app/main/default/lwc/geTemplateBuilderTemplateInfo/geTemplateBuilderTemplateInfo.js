import { LightningElement, api } from 'lwc';
import { dispatch } from 'c/utilTemplateBuilder';
import { isEmpty, isFunction, handleError } from 'c/utilCommon';
import checkNameUniqueness from '@salesforce/apex/GE_GiftEntryController.checkNameUniqueness';
import GeLabelService from 'c/geLabelService';

export default class geTemplateBuilderTemplateInfo extends LightningElement {

    CUSTOM_LABELS = GeLabelService.CUSTOM_LABELS;

    @api isLoading;
    @api templateId;
    @api templateName;
    @api templateDescription;

    /*******************************************************************************
    * Start getters for data-qa-locator attributes
    */

    get qaLocatorTemplateName() {
        return `input Field Label ${this.CUSTOM_LABELS.geLabelTemplateInfoNameField}`;
    }

    get qaLocatorTemplateDescription() {
        return `input Field Label ${this.CUSTOM_LABELS.geLabelTemplateInfoDescriptionField}`;
    }

    /*******************************************************************************
    * End getters for data-qa-locator attributes
    */

    @api
    validate() {
        return new Promise(async (resolve, reject) => {
            const nameInput = this.template.querySelector('lightning-input');
            let isValid = false;

            if (isFunction(nameInput.reportValidity) && !isEmpty(nameInput)) {
                checkNameUniqueness({ name: nameInput.value, id: this.templateId })
                    .then(isNameValid => {
                        if (isNameValid) {
                            nameInput.setCustomValidity('');
                        } else {
                            nameInput.setCustomValidity(this.CUSTOM_LABELS.geErrorExistingTemplateName);
                        }

                        nameInput.reportValidity();
                        isValid = nameInput.checkValidity();

                        dispatch(this, 'updatevalidity', { property: 'hasTemplateInfoTabError', hasError: !isValid });
                        resolve(isValid);
                    })
                    .catch(error => {
                        handleError(error);
                        reject(error);
                    });
            }
        });
    }

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
        this.validate();
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