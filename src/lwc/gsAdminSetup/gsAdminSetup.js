import { LightningElement, track, wire } from 'lwc';
import gsAdminSetupTitle from '@salesforce/label/c.gsAdminSetupTitle';
import getChecklist from '@salesforce/apex/GS_AdminSetup.getChecklist';
import translate from 'c/gsTranslate';

/**
* @description This component render all checklist section and his steps
*/
export default class gsAdminSetup extends LightningElement {

    /**
    * @description This var contain a list of checklist to render
    */
    @track checklists;

    /**
    * @description This function load and translate all checklist sections and his items
    */
    @wire(getChecklist)
    wiredGetChecklist({ data, error }) {
        // Hold on to the provisioned value so we can refresh it later.
        if (data) {
            this.checklists = data.map(this.translateSection);
        }
    }

    /**
    * @description This method translate all text info in the checklist section and his items
    * @param ChecklistSection
    * @return ChecklistSection (translate)
    */
    translateSection = (section) => {
        const tSection = {...section}
        tSection.title = translate(section.title);
        tSection.description = translate(section.description);
        tSection.items = section.items.map(this.translateSectionItem)
        return tSection
    }

    /**
    * @description This method translate all text info in checklist items
    * @param ChecklistItem
    * @return ChecklistItem (translate)
    */
    translateSectionItem = (item) => {
        const tItem = {...item};
        tItem.title = translate(item.title);
        tItem.description = translate(item.description);
        tItem.extraInfo = translate(item.extraInfo);
        if (item.principalBtn) {
            tItem.principalBtn = {...(item.principalBtn)};
            tItem.principalBtn.label = translate(item.principalBtn.label);
        }
        if (item.secondaryBtn) {
            tItem.secondaryBtn = {...(item.secondaryBtn)};
            tItem.secondaryBtn.label = translate(item.secondaryBtn.label);
        }
        if (item.link) {
            tItem.link = {...(item.link)};
            tItem.link.label = translate(item.link.label);
        }
        return tItem;
    }

    /**
    * @description Return title to display in UI
    * @return      Title text
    * @see         labels
    */
    get title() {
        return gsAdminSetupTitle;
    }
}