import { LightningElement, track } from 'lwc';

import gsAdminSetupTitle from '@salesforce/label/c.gsAdminSetupTitle'

import exploreNPSP from './exploreNPSP';
import makeItYours from './makeItYours';
import onboardUsers from './onboardUsers';

export default class gsAdminSetup extends LightningElement {

    @track checklists = [
        { id: 1, ...exploreNPSP },
        { id: 2, ...makeItYours },
        { id: 3, ...onboardUsers },
    ];

    /**
    * Return title to display in UI
    * @return      Title text
    * @see         Label
    */
    get title() {
        return gsAdminSetupTitle;
    }
}