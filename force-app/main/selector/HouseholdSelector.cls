public inherited sharing class HouseholdSelector {

    private List<Account> getAccounts(Set<Id> accountIds) {
        List<Account> accounts = [
                SELECT Id, Type, npe01__SYSTEM_AccountType__c, npe01__One2OneContact__c,
                (SELECT Id, AccountId, Account.npe01__One2OneContact__c FROM Contacts),
                (SELECT Id FROM Opportunities LIMIT 1)
                FROM Account
                WHERE Id IN :accountIds
        ];
        return accounts;
    }

    public Households findByIds(Set<Id> ids){
        return new Households(getAccounts(ids));
    }

}