import { LightningElement, track } from 'lwc';

import gsAdminSetupTitle from '@salesforce/label/c.gsAdminSetupTitle';

import data from './data';


export default class gsAdminSetup extends LightningElement {

    @track checklists = data;

    /**
    * Return title to display in UI
    * @return      Title text
    * @see         Label
    */
    get title() {
        return gsAdminSetupTitle;
    }
}