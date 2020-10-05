import { LightningElement, track } from 'lwc';

import gsAdminSetupTitle from '@salesforce/label/c.gsAdminSetupTitle'

import exploreNonProfit from './exploreNonprofit';
import makeYou from './makeYou';
import userOnBoard from './userOnBoard';

export default class gsAdminSetup extends LightningElement {

    @track checklists = [
        { id: 1, ...exploreNonProfit },
        { id: 2, ...makeYou },
        { id: 3, ...userOnBoard },
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