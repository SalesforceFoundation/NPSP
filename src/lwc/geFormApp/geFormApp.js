import {LightningElement, api} from 'lwc';

export default class GeFormApp extends LightningElement {
    @api isBatchMode = false;

    handleSubmit(event) {
        const submissions = event.target.submissions;
        console.log('submissions (in GeFormAPP: ', submissions);
    }
}