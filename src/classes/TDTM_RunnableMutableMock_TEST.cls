/*
    Copyright (c) 2019, Salesforce.org
    All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Salesforce.org nor the names of
      its contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
    FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
    COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
    INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
    BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
    CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
    LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
    ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
    POSSIBILITY OF SUCH DAMAGE.
*/
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
public class TDTM_RunnableMutableMock_TEST extends TDTM_RunnableMutable {

    /*******************************************************************************************************
     * @description Mock class used for testing the TDTM_RunnableMutable class. If the dmlWrapper collection
     * contains Contact objects, the parent Account.NumberOfEmployees field value is incremented from zero
     * to show that the dmlWrapper collection returned (by reference) is mutated by this class.
     */
    public override void run(List<SObject> newList, List<SObject> oldList, 
            TDTM_Runnable.Action triggerAction, Schema.DescribeSObjectResult objResult,
            TDTM_Runnable.DmlWrapper dmlWrapper
    ) {

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
            SELECT Id, NumberOfEmployees
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