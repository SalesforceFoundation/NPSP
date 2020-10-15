import { LightningElement, track, wire } from 'lwc';
import gsAdminSetupTitle from '@salesforce/label/c.gsAdminSetupTitle';
import getChecklist from '@salesforce/apex/GS_AdminSetup.getChecklist';
import translate from './labelTranslate';

export default class gsAdminSetup extends LightningElement {

    @track checklists;

    @wire(getChecklist)
    wiredGetChecklist({ data, error }) {
        // Hold on to the provisioned value so we can refresh it later.
        if(data) {
            this.checklists = data.map(this.translateSection);
        }
    }

    translateSection = (section) => {
        const tSection = {...section}
        tSection.title = translate(section.title);
        tSection.description = translate(section.description);
        tSection.items = section.items.map(this.translateSectionItem)
        return tSection
    }

    translateSectionItem = (item) => {
        const tItem = {...item};
        tItem.title = translate(item.title);
        tItem.description = translate(item.description);
        if(item.principalBtn) {
            tItem.principalBtn = {...(item.principalBtn)};
            tItem.principalBtn.label = translate(item.principalBtn.label);
        }
        if(item.secondaryBtn) {
            tItem.secondaryBtn = {...(item.secondaryBtn)};
            tItem.secondaryBtn.label = translate(item.secondaryBtn.label);
        }
        if(item.link) {
            tItem.link = {...(item.link)};
            tItem.link.label = translate(item.link.label);
        }
        return tItem;
    }

    /**
    * Return title to display in UI
    * @return      Title text
    * @see         Label
    */
    get title() {
        return gsAdminSetupTitle;
    }
}