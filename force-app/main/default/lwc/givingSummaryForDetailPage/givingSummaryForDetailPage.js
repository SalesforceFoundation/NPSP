import { api, LightningElement } from 'lwc';
import getContactIdByUserId from "@salesforce/apex/DonationHistoryController.getContactIdByUserId";

export default class GivingSummaryDetailPage extends LightningElement {
    
    @api recordId;

    // eslint-disable-next-line @lwc/lwc/no-async-await
    async connectedCallback() {
        if(!this.recordId){
            getContactIdByUserId()
            .then((recordId) => {
                this.recordId = recordId;
            });
        } 
    }

}