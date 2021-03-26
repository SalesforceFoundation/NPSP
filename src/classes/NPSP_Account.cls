public inherited sharing class NPSP_Account {

    private Account account;

    public NPSP_Account(Account a) {
        this.account = a;
    }

    public Boolean isHouseholdAccount() {
        return account.npe01__SYSTEM_AccountType__c == CAO_Constants.HH_ACCOUNT_TYPE;
    }
}