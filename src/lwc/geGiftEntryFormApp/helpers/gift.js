import getDummySoftCredits from '@salesforce/apex/GE_GiftEntryController.getDummySoftCredits';

class Gift {
    softCredits = [];    

    async init() {
        const softCreditOppContactRoles = await getDummySoftCredits();
        
        softCreditOppContactRoles.forEach( oppContactRole => {
            let softCredit = { ...oppContactRole };
            /***
            softCredit.Role = oppContactRole.Role;
            softCredit.ContactId = oppContactRole.ContactId;
            softCredit.OpportunityId = oppContactRole.OpportunityId;
            softCredit.Id = oppContactRole.Id;
            **/
            softCredit.isReadOnly = true;
            this.softCredits.push( softCredit );
        });        
    }
}

export default Gift;