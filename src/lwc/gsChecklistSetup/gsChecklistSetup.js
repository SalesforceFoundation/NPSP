import { LightningElement, track, api } from 'lwc';
import gsAdminSetupTitle from '@salesforce/label/c.gsAdminSetupTitle';
import getChecklists from '@salesforce/apex/GS_ChecklistSetup.getChecklists';
import getLabelValue from 'c/gsLabelMapper';

/**
* @description This component renders all checklist sections and their steps
*/
export default class gsChecklistSetup extends LightningElement {

    /**
    * @description A list of checklists to render
    */
    @track checklists = [];
    
    /**
    * @description To select which data display in this component
    */
    @api pageType = 'Admin';

    /**
     * @description Page title custom label
     */
    @api pageTitle ='';

    connectedCallback() {
        getChecklists({'pageType': this.pageType})
        .then(data => {
            if (data) {
                this.checklists = data.map(this.getLabelValueSection);
            }
        });
    }

    /**
    * @description This method getLabelValue all text info in the checklist section and his items
    * @param ChecklistSection
    * @return ChecklistSection (getLabelValue)
    */
    getLabelValueSection = (section) => {
        const tSection = {...section}
        tSection.title = getLabelValue(section.title);
        tSection.description = getLabelValue(section.description);
        tSection.items = section.items.map(this.getLabelValueItem)
        return tSection
    }

    /**
    * @description This method getLabelValue all text info in checklist items
    * @param ChecklistItem
    * @return ChecklistItem (getLabelValue)
    */
    getLabelValueItem = (item) => {
        const tItem = {...item};
        tItem.title = getLabelValue(item.title);
        tItem.description = getLabelValue(item.description);
        tItem.extraInfo = getLabelValue(item.extraInfo);
        if (item.primaryBtn) {
            tItem.primaryBtn = {...(item.primaryBtn)};
            tItem.primaryBtn.label = getLabelValue(item.primaryBtn.label);
        }
        if (item.secondaryBtn) {
            tItem.secondaryBtn = {...(item.secondaryBtn)};
            tItem.secondaryBtn.label = getLabelValue(item.secondaryBtn.label);
        }
        if (item.link) {
            tItem.link = {...(item.link)};
            tItem.link.label = getLabelValue(item.link.label);
        }
        return tItem;
    }

    /**
    * @description Return title to display in UI
    * @return      Title text
    * @see         labels
    */
    get title() {
        if (this.pageTitle !== undefined && this.pageTitle !== null && this.pageTitle !== '') {
            return getLabelValue(this.pageTitle);
        }
        return '';
    }
}