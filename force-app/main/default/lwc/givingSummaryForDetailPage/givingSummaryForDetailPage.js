import { api, LightningElement } from "lwc";
import getContactIdByUserId from "@salesforce/apex/DonationHistoryController.getContactIdByUserId";

export default class GivingSummaryForDetailPage extends LightningElement {
    @api recordId;

    connectedCallback() {
        if (!this.recordId) {
            getContactIdByUserId().then((recordId) => {
                this.recordId = recordId;
            });
        }
    }
}
