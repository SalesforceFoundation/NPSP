public inherited sharing class HouseholdAccountSelector implements IHouseholdSelector {

    private List<Account> getAccounts(List<Id> accountIds) {
        List<Account> accounts = [
                SELECT Id, Type, npe01__SYSTEM_AccountType__c,
                (SELECT Id FROM Contacts LIMIT 1),
                (SELECT Id FROM Opportunities LIMIT 1)
                FROM Account
                WHERE Id IN :accountIds
        ];
        return accounts;
    }


    public IHouseholds findByIdWithOneContactAndGift(Set<Id> ids){
        return new HouseholdAccounts(getAccounts(new List<Id>(ids)));
    }
}