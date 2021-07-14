import getDummySoftCredits from '@salesforce/apex/GE_GiftEntryController.getDummySoftCredits';

class Gift {
    softCredits = [];    

    async init() {
        const softCreditOppContactRoles = await getDummySoftCredits();
        
        softCreditOppContactRoles.forEach( (oppContactRole, index) => {
            let softCredit = { ...oppContactRole };
            softCredit.Id = index;
            this.softCredits.push( softCredit );
        });       
    }
}

export default Gift;