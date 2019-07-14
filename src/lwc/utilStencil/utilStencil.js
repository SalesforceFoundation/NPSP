import { LightningElement, api, track } from 'lwc';

export default class utilStencil extends LightningElement {
    @api rowCount = 3;
    @api columnCount = 3;
    @track rows = [];
    @track columns = [];

    connectedCallback() {
        if (this.rowCount) {
            for (let i = 0; i < this.rowCount; i++) {
                this.rows.push({id: i});
            }
        }
        if (this.columnCount) {
            for (let i = 0; i < this.columnCount; i++) {
                this.columns.push({id: i});
            }
        }
    }
}