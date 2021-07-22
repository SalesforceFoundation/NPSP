import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import CumulusStaticResources from '@salesforce/resourceUrl/CumulusStaticResources';
import updateCheckItem from '@salesforce/apex/GS_ChecklistSetup.updateCheckItem'
import getNamespace from '@salesforce/apex/GS_ChecklistSetup.getNamespace';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
const gsAssetsImage = CumulusStaticResources + '/gsAssets/step';

/**
* @description This component render the Sub Section Item info
*/
export default class GsChecklistItem extends NavigationMixin(LightningElement) {

    /**
    * @description data of the item this component render
    * @type  GS_ChecklistSetup.ChecklistItem
    */
    @api item = {}

    /**
    * @description package namespace to used in navigation
    * @type string
    */
    namespace = '';

    connectedCallback() {
        getNamespace()
            .then(data => {
                if (data) {
                    this.namespace = data;
                }
            });
    }

    /**
    * @description return if the item has Secondary button
    * @return boolean
    */
    get hasSecondaryBtn() {
        return !!this.item.secondaryBtn;
    }
    /**
    * @description return if the item has Primary button
    * @return boolean
    */
    get hasPrimaryBtn() {
        return !!this.item.primaryBtn;
    }
    /**
    * @description return if the item has Link
    * @return boolean
    */
    get hasLink() {
        return !!this.item.link;
    }
    /**
    * @description return if the item has buttons
    * @return boolean
    */
    get hasButtons() {
        return !!this.item.primaryBtn || !!this.item.secondaryBtn;
    }
    /**
    * @description return if the item has Image
    * @return boolean
    */
    get hasImage() {
        return !!this.item.image;
    }
    /**
    * @description return if the item Image URI
    * @return String
    * @see uri
    */
    get imgSrc() {
        return `${gsAssetsImage}/${this.item.image}`;
    }
    /**
    * @description return class to use in footer
    * @returns String
    */
    get footerClass() {
        const styleClass = ['content-footer'];
        if(!this.item.link) {
            styleClass.push('without-link');
        }
        return styleClass.join(' ');
    }
    /**
    * @description handler the event to click Primary button
    */
    onClickPrimaryBtn() {
        this.buttonAction(this.item.primaryBtn);
    }
    /**
    * @description handler the event to click Secondary button
    */
    onClickSecondaryBtn() {
        this.buttonAction(this.item.secondaryBtn);
    }
    /**
    * @description exec button action
    * @param string button type
    */
    buttonAction(button) {
        switch(button.type) {
            case 'sfdc:new-tab': {
                this.sfdcLinkAction(button.value);
                break;
            }
            case 'link': {
                window.open(button.value, '_blank');
                break
            }
        }
    }
    /**
    * @description use NavigationMixin.GenerateUrl Api to navigate in SFDC org
    * @param string button value
    */
    sfdcLinkAction(value) {
        const values = value.split(':');     
        this[NavigationMixin.GenerateUrl]({
            type: `standard__${values[0]}`,
            attributes: this.getSfdcLinkAttr(values)
        }).then((url) => {
            window.open(url, '_blank');
        })
    }

    /**
    * @description get attribute to navigate in sfdc pages
    * @param string[] value arguments
    * @returns object
    */
    getSfdcLinkAttr(values) {
        switch(values[0]) {
            case 'navItemPage':
                return {
                    apiName: this.subNamespace(values[1])
                };
            case 'objectPage':
                return {
                    objectApiName: this.subNamespace(values[1]),
                    actionName: values[2]
                };
            default:
                return {};
        }
    }

    /**
    * @description Substitute 'c__' to package namespace
    * @param string api name
    * @returns String
    */
    subNamespace(apiName) {
        return apiName.replace(/^c__/, this.namespace ? `${this.namespace}__` : '');
    }

    /**
     * Event when the user check or uncheck the checkbox in the item.
     * It calls the backend to update the status and call events to notify the front end to update the progress ring.
     * @param event the event object.
     */
    onChange(event) {
        let checked = event.detail.checked;
        let target = event.target;
        target.disabled = true;

        updateCheckItem({'itemId': this.item.id, 'isChecked': checked})
        .then ( _ => {
            let eventName = checked ? 'checked' : 'unchecked';
            this.dispatchEvent(new CustomEvent(eventName));
        })
        .catch(error => {
            if (error && error.body) {
                const evt = new ShowToastEvent({
                    title: '',
                    message: error.body.message,
                    variant: 'error'
                });
                this.dispatchEvent(evt);
                
            }
        }) 
        .then( _ => {
            target.disabled = false;
        })
        .then( _ => {
            target.focus();
        });
        
    }
}