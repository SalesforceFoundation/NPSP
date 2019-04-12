/**
 * @author Roger Mitchell
 * @date 4/12/2019
 * @group TDTM
 * @group-content ../../ApexDocContent/TDTM.htm
 * @description Sample implementation of TDTM_RunnableMutable to allow for testing
 * expected behavior and assisting with test coverage of TDTM_RunnableMutable. For
 * each time this class runs, the expectation is that the Account's NumberOfEmployees
 * field will increment by 1.
 */
@isTest
public class TDTM_RunnableMutableExample_TEST extends TDTM_RunnableMutable {
    
    public override void run(List<SObject> newList, List<SObject> oldList, 
        TDTM_Runnable.Action triggerAction, Schema.DescribeSObjectResult objResult,
        TDTM_Runnable.DmlWrapper dmlWrapper) {

        // collect each Contact's AccountId
        Set<Id> accountIds = new Set<Id>();

        for (SObject record : newList) {
            Contact contact = (Contact) record;
            accountIds.add(contact.AccountId);
        }

        // create a map version of dmlWrapper.objectsToUpdate to easily
        // check whether a record is already part of this collection
        Map<Id, SObject> objectsToUpdate = new Map<Id, SObject>(dmlWrapper.objectsToUpdate);

        // retrieve a collection of these Accounts, update a field
        for (Account account : [
            SELECT Id,
                NumberOfEmployees
            FROM Account
            WHERE Id IN :accountIds
        ]) {

            // if objectsToUpdate does not contain this Account, add to collection 
            if (!objectsToUpdate.containsKey(account.Id)) {
                objectsToUpdate.put(account.Id, account);
            }

            // pull the account from objectsToUpdate
            Account accountToUpdate = (Account) objectsToUpdate.get(account.Id);

            // set this field to 0 if it is null
            if (accountToUpdate.NumberOfEmployees == null) {
                accountToUpdate.NumberOfEmployees = 0;
            }

            // increment the field by 1
            accountToUpdate.NumberOfEmployees += 1;

            // put this record back into the collection for update
            objectsToUpdate.put(accountToUpdate.Id, accountToUpdate);
        }

        // set dmlWrapper's objectToUpdate collection
        dmlWrapper.objectsToUpdate = objectsToUpdate.values();
    }
}