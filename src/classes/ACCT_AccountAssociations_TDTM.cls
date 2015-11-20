/*
    Copyright (c) 2015, Salesforce.com Foundation
    All rights reserved.
    
    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:
    
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Salesforce.com Foundation nor the names of
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
* @author Salesforce.com Foundation
* @description Implements account association behavior 
*/
public class ACCT_AccountAssociations_TDTM extends TDTM_Runnable {

    public override DmlWrapper run(List<SObject> newlist, List<SObject> oldlist, 
    TDTM_Runnable.Action triggerAction, Schema.DescribeSObjectResult objResult) {
        
        List<Account_Association__c> newListCasted = (newList == null ? new List<Account_Association__c>() : (List<Account_Association__c>)newList);
        List<Account_Association__c> oldListCasted = (oldList == null ? new List<Account_Association__c>() : (List<Account_Association__c>)oldList);
        
        if(triggerAction != TDTM_Runnable.Action.afterDelete) {
            return runForAssociations(newListCasted, oldListCasted, triggerAction);
        } else {
            return runForAssociations(oldListCasted, null, triggerAction);
        }
    }
    
    /*******************************************************************************************************
    * @description Trigger Handler on Account Associations that handles creating, updating, and deleting
    * a reciprocal Account Association.
    * @param listNew the list of Account Associations from trigger new. 
    * @param listOld the list of Account Associations from trigger old. 
    * @param triggerAction which trigger event (BeforeInsert, AfterInsert, etc.). 
    * @return dmlWrapper descriptor of DML operations to perform
    ********************************************************************************************************/
    private DmlWrapper runForAssociations(List<Account_Association__c> newlist, List<Account_Association__c> oldlist, 
    TDTM_Runnable.Action triggerAction) {
            
        DmlWrapper mainWrapper = new DmlWrapper();
        
        // Relationship list for termination updates
        List<Account_Association__c> origAssociations = new List<Account_Association__c>();
        List<Account_Association__c> associationsToCreate = new List<Account_Association__c>();
        List<Account_Association__c> associationsToUpdate = new List<Account_Association__c>();
        List<Account_Association__c> associationsToDelete = new List<Account_Association__c>();
        List<Account_Association__c> reciprocalsToUpdate = new List<Account_Association__c>();
        
        Integer i = 0;          // processing counter            
        for(Account_Association__c r : newlist) {
            // AFTER INSERT
            if (triggerAction == TDTM_Runnable.Action.afterInsert) {
                if (r.Reciprocal_Association__c == null) {
                    associationsToCreate.add(r);
                }
                if (r.Reciprocal_Association__c != null) {
                    reciprocalsToUpdate.add(r);
                }
            }
            
            // AFTER UPDATE
            if (triggerAction == TDTM_Runnable.Action.afterUpdate) {   
                if (r.Reciprocal_Association__c == oldlist[i].Reciprocal_Association__c 
                && r.Associated_Account__c != null) {
                    associationsToUpdate.add(r);
                    origAssociations.add(oldlist[i]);
                }
                if (r.Associated_Account__c == null) {
                    associationsToDelete.add(r);
                }
            }

            // AFTER DELETE
            if (triggerAction == TDTM_Runnable.Action.afterDelete) {
                if (r.Reciprocal_Association__c != null) {
                    associationsToDelete.add(r);
                }
            }

            i++;
        }

        if (associationsToCreate.size() > 0 ) {
            DmlWrapper wrapper = createAssociation(associationsToCreate);
            mainWrapper.objectsToInsert.addAll(wrapper.objectsToInsert);
            mainWrapper.objectsToUpdate.addAll(wrapper.objectsToUpdate);
        }
        if (associationsToUpdate.size() > 0 ) {
            DmlWrapper wrapper = updateAssociations(associationsToUpdate, origAssociations);
            mainWrapper.objectsToUpdate.addAll(wrapper.objectsToUpdate);
        }
        if (reciprocalsToUpdate.size() > 0 ) {
            DmlWrapper wrapper = reciprocate(reciprocalsToUpdate);
            mainWrapper.objectsToUpdate.addAll(wrapper.objectsToUpdate);            
        }
        if (associationsToDelete.size() > 0 ) {
            DmlWrapper wrapper = deleteAssociations(associationsToDelete);
            mainWrapper.objectsToDelete.addAll(wrapper.objectsToDelete);
        }

        return mainWrapper;
    }


    /*******************************************************************************************************
    * @description Delete reciprocal associations when an Account Association is deleted.
    * @param associations the list of Account Associations to delete
    * @return dmlWrapper descriptor of DML operations to perform
    ********************************************************************************************************/
    public static DmlWrapper deleteAssociations(Account_Association__c[] associations) {
        UTIL_Debug.debug('****Deleting account associations: ' + associations);
        DmlWrapper dmlWrapper = new DmlWrapper();
        List<SObject> associationsToDelete = new List<SObject>();
        for(Account_Association__c a : associations) {
            Account_Association__c associationToDelete;
            if(a.Reciprocal_Association__c != null) {
                associationToDelete = new Account_Association__c(Id = a.Reciprocal_Association__c);
            } else if(a.Associated_Account__c == null) {
                associationToDelete = new Account_Association__c(Id = a.Id);
            }
            associationsToDelete.add(associationToDelete);
        }
        if (associationsToDelete.size() > 0) {
            dmlWrapper.objectsToDelete.addAll(associationsToDelete);
        }
        return dmlWrapper;
    }
    
    /*******************************************************************************************************
    * @description Store a reference to the initially created association once its mirror is inserted
    * @param associations the list of mirror Account Associations that were inserted
    * @return dmlWrapper descriptor of DML operations to perform
    ********************************************************************************************************/
    public static DmlWrapper reciprocate(Account_Association__c[] associations) {
        DmlWrapper dmlWrapper = new DmlWrapper();
        List<SObject> associationsToUpdate = new List<SObject>();
        for(Account_Association__c a : associations) {
            UTIL_Debug.debug('****Creating reciprocal relatioship');
            Account_Association__c copy = new Account_Association__c(
                Id = a.Reciprocal_Association__c, 
                Reciprocal_Association__c = a.Id
            );
            associationsToUpdate.add(copy);
        }
        dmlWrapper.objectsToUpdate.addAll(associationsToUpdate);
        return dmlWrapper;
    }

    /*******************************************************************************************************
    * @description Get a map of reciprocal type strings from custom settings.
    ********************************************************************************************************/
    static private map<String, String> reciprocalTypes {
        get {
            if (reciprocalTypes == null) {
                reciprocalTypes = new map<String, String>();
                for (Reciprocal_Account_Association_Types__c reciprocal : Reciprocal_Account_Association_Types__c.getAll().values()) {
                    reciprocalTypes.put(reciprocal.Name, reciprocal.Reciprocal_Type__c);
                }
            }
            return reciprocalTypes;
        }
        set;
    }

    /*******************************************************************************************************
    * @description Create reciprocal associations when an Account Association is inserted.
    * @param associations the list of Account Associations to create
    * @return dmlWrapper descriptor of DML operations to perform
    ********************************************************************************************************/
    public static DmlWrapper createAssociation(Account_Association__c[] associations) {
        
        DmlWrapper dmlWrapper = new DmlWrapper();
        
        List<SObject> associationsToCreate = new List<SObject>();

        for(Account_Association__c a : associations) {
            UTIL_Debug.debug('****Creating account association');
            Account_Association__c copy = new Account_Association__c();
            copy.Reciprocal_Association__c = a.Id;
            copy.Account__c = a.Associated_Account__c;
            copy.Associated_Account__c = a.Account__c;
            copy.Status__c = a.Status__c;
            copy.Description__c = a.Description__c;
            copy.Start_Date__c = a.Start_Date__c;
            copy.End_Date__c = a.End_Date__c;

            String reciprocalType = reciprocalTypes.get(a.Type__c);
            if (reciprocalType != null) {
                copy.Type__c = reciprocalType;
            } else {
                copy.Type__c = a.Type__c;
            }

            associationsToCreate.add(copy);

        }
        
        dmlWrapper.objectsToInsert.addAll(associationsToCreate);
        return dmlWrapper;
    }

    /*******************************************************************************************************
    * @description Update reciprocal associations when an Account Association is updated.
    * @param associations the list of Account Associations to update
    * @return dmlWrapper descriptor of DML operations to perform
    ********************************************************************************************************/
    public static DmlWrapper updateAssociations(Account_Association__c[] associations, Account_Association__c[] oldAssociations){
        
        DmlWrapper dmlWrapper = new DmlWrapper();
        
        List<SObject> reciprocalsToUpdate = new List<SObject>();
        Integer counter = 0;                                            // processing counter       

        for(Account_Association__c a : associations) {
            Account_Association__c old = oldAssociations[counter];
            if ((a.Status__c != old.Status__c 
                 || a.Type__c != old.Type__c 
                 || a.Description__c != old.Description__c
                 || a.Account__c != old.Account__c
                 || a.Associated_Account__c != old.Associated_Account__c)
               && a.Reciprocal_Association__c != null) {
                UTIL_Debug.debug('****Updating account association');
                Account_Association__c copy = new Account_Association__c(Id=a.Reciprocal_Association__c);
                if (old.Account__c != a.Account__c) {
                    copy.Associated_Account__c = a.Account__c;
                }
                if (old.Associated_Account__c != a.Associated_Account__c) {
                    copy.Account__c = a.Associated_Account__c;
                }
                String reciprocalType = reciprocalTypes.get(a.Type__c);
                if (reciprocalType != null) {
                    copy.Type__c = reciprocalType;
                } else {
                    copy.Type__c = a.Type__c;
                }
                copy.Status__c = a.Status__c;
                copy.Description__c = a.Description__c;
                copy.Start_Date__c = a.Start_Date__c;
                copy.End_Date__c = a.End_Date__c;
                reciprocalsToUpdate.add(copy);
            }
            counter++;
        }
        if (!reciprocalsToUpdate.isEmpty()){
            dmlWrapper.objectsToUpdate.addAll(reciprocalsToUpdate);
        }
        return dmlWrapper;
    }
    
    /*******************************************************************************************************
    * @description After an account is deleted, delete any newly orphaned Account Associations
    * (called from ACCT_Accounts_TDTM)
    * @param associations the list of Accounts that were deleted
    * @return dmlWrapper descriptor of DML operations to perform
    ********************************************************************************************************/
    public static DmlWrapper deleteOrphanedAccountAssociations(list<Id> mergedAccountIds) {
        DmlWrapper dmlWrapper = new DmlWrapper();

        // delete orphaned associations
        UTIL_Debug.debug('****Cleaning orphaned account associations');
        list<SObject> associationsToDelete = [select Id from Account_Association__c
            where Associated_Account__c = null limit 200];
        dmlWrapper.objectsToDelete.addAll(associationsToDelete);

        // delete self-referencing associations after merge
        if (mergedAccountIds != null) {
            UTIL_Debug.debug('****Cleaning self-referencing account associations');
            list<Account_Association__c> foo = [select Id, Account__c, Associated_Account__c from Account_Association__c];
            dmlWrapper.objectsToDelete.addAll((list<sobject>) [
                select Id from Account_Association__c
                where Account__c in :mergedAccountIds and Associated_Account__c in :mergedAccountIds
            ]);
        }

        return dmlWrapper;
    }

}