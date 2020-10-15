import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import CumulusStaticResources from '@salesforce/resourceUrl/CumulusStaticResources';
const gsAssetsImage = CumulusStaticResources + '/gsAssets/step';

export default class GsChecklistItem extends NavigationMixin(LightningElement) {
    @api item = {}

    get hasSecondaryBtn() {
        return !!this.item.secondaryBtn;
    }

    get hasPrincipalBtn() {
        return !!this.item.principalBtn;
    }

    get hasLink() {
        return !!this.item.link;
    }

    get hasImage() {
        return !!this.item.image;
    }

    get imgSrc() {
        return `${gsAssetsImage}/${this.item.image}`;
    }

    onClickPrincipalBtn() {
        this.buttonAction(this.item.principalBtn);
    }

    onClickSecondaryBtn() {
        this.buttonAction(this.item.secondaryBtn);
    }

    buttonAction(button) {
        switch(button.type) {
            case 'sfdc:link': {
                this.sfdcLinkAction(button.value);
                break;
            }
            case 'link': {
                window.open(button.value, '_blank');
                break
            }
        }
    }

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