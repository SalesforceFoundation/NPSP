import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import CumulusStaticResources from '@salesforce/resourceUrl/CumulusStaticResources';
const gsAssetsImage = CumulusStaticResources + '/gsAssets/step';

/**
* @description This component render the Sub Section Item info
*/
export default class GsChecklistItem extends NavigationMixin(LightningElement) {
    /**
    * @description data of the item this component render
    * @type  GS_AdminSetup.ChecklistItem
    */
    @api item = {}
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
            attributes: {
                objectApiName: values[1],
                actionName: values[2]
            }
        }).then((url) => {
            window.open(url, '_blank');
        })
    }
}