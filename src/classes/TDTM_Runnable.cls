/*
    Copyright (c) 2013, Salesforce.com Foundation
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
 * Class that classes to be run from a trigger according to the TDTM design
 * need to extend.
 */
global abstract class TDTM_Runnable {

    //It will be the duty of the run method implementation to set a flag to prevent re-entrancy. We cannot do 
    //that for them in TDTM_TriggerHandler, even if it's after calling the future, because then it might get set 
    //before the future runs (and since the future method calls the non-future method, which checks the flag, 
    //the future method would have no effect.) Also, some classes might not want to prevent it.
    
    //We need this method because Apex won't let us call a non-static method from a separate object instance
    public void runFutureNonStatic(Set<Id> newIds, Set<Id> oldIds, String action, String objectName, String classToRunName) {
        runFuture(newIds, oldIds, action, objectName, classToRunName);
    }
    
    @future
    public static void runFuture(Set<Id> newIds, Set<Id> oldIds, String action, String objectName, String classToRunName) {
        
        Schema.DescribeSObjectResult objResult = TDTM_TriggerActionHelper.getDescribeObjectByName(objectName);
        TDTM_Runnable.Action triggerAction = TDTM_TriggerActionHelper.getTriggerActionFromName(action);
        
        //Get all fields for the object
        List<Schema.SObjectField> allFields = objResult.fields.getMap().values();
        
        //Getting the records the IDs refer to
        String qn = 'select ';
        for(Integer i = 0; i < allFields.size() - 1; i++) //add all fields, except last, to query
            qn += ' ' + allFields[i] + ', ';
        qn += ' ' + allFields[allFields.size() - 1]; //add last field to query
        qn += ' from ' + objectName + ' where id IN ';

        List<SObject> newlist = Database.query(qn + ':newIds');
        List<SObject> oldlist = Database.query(qn + ':oldIds');

        //Call the non-future method
        Type classType = Type.forName(classToRunName);
        Object classInstance; 
        if(classType != null)
            classInstance = classType.newInstance();
        if(classInstance instanceof TDTM_Runnable) {
        	TDTM_Runnable runnable = (TDTM_Runnable) classInstance;
        	//WARNING: we have queried all the fields that would be available in the records themselves, but NOT the fields
        	//from related (parent or child) records. Those would need to be queried independently in the class itself (see 
        	//ERR_ParentAccountUpdater2_TEST class for an example on how to do that).
	        DmlWrapper dmlWrapper = runnable.run(newlist, oldlist, triggerAction, objResult);
	        
	        //Process the result. In this case we cannot pass the original Trigger.new and Trigger.old, since we are
	        //in a future
	        TDTM_TriggerHandler.processDML(dmlWrapper);
        }
    }
    
    global abstract DmlWrapper run(List<SObject> newlist, List<SObject> oldlist, Action triggerAction, 
        Schema.DescribeSObjectResult objResult);
        
    global class DmlWrapper {
        global List<SObject> objectsToInsert = new List<SObject>(); 
        global List<SObject> objectsToUpdate = new List<SObject>();
        global List<SObject> objectsToDelete = new List<SObject>();
        global List<SObject> objectsToUndelete = new List<SObject>();
        
        public void groupByType() {
        	objectsToInsert = groupSObjects(objectsToInsert);
        	objectsToUpdate = groupSObjects(objectsToUpdate);
        	objectsToDelete = groupSObjects(objectsToDelete);
        	objectsToUndelete = groupSObjects(objectsToUndelete);
        }
        
        //To avoid the "Cannot have more than 10 chunks in a single operation. Please rearrange 
        //the data to reduce chunking" error.
        private List<SObject> groupSObjects(List<SObject> sobjects) {
        	//First remove duplicates to avoid the "Duplicate id in list" error
        	sobjects = new List<SObject>(new Set<SObject>(sobjects));
        	        	
        	List<SObject> sorted = new List<SObject>();
        	
        	List<SObject> accounts = new List<SObject>();
            List<SObject> contacts = new List<SObject>();
            List<SObject> opps = new List<SObject>();
            List<SObject> addresses = new List<SObject>();
            List<SObject> affiliations = new List<SObject>();
            List<SObject> errors = new List<SObject>();
            List<SObject> households = new List<SObject>();
            List<SObject> payments = new List<SObject>();
            List<SObject> recDonations = new List<SObject>();
            List<SObject> relationships = new List<SObject>();
            list<SObject> allocations = new list<SObject>();
            List<SObject> unknown = new List<SObject>();
            
            for(SObject o : sobjects) {
                if(o instanceof Account) {
                	accounts.add(o);
                } else if(o instanceof Contact) {
                	contacts.add(o);
                } else if(o instanceof Opportunity) {
                	opps.add(o);
                } else if(o instanceof Address__c) {
                    addresses.add(o);
                } else if(o instanceof npe5__Affiliation__c) {
                    affiliations.add(o);
                } else if(o instanceof Error__c) {
                    errors.add(o);
                } else if(o instanceof npo02__Household__c) {
                    households.add(o);
                } else if(o instanceof npe01__OppPayment__c) {
                    payments.add(o);
                } else if(o instanceof npe03__Recurring_Donation__c) {
                    recDonations.add(o);
                } else if(o instanceof npe4__Relationship__c) {
                    relationships.add(o);
                } else if(o instanceof Allocation__c) {
                    allocations.add(o);
                } else {
                	UTIL_Debug.debug(LoggingLevel.WARN, '****Not one of our basic object types');
                	unknown.add(o);
                }
            }
            sorted.addAll(accounts);
            sorted.addAll(contacts);
            sorted.addAll(opps);
            sorted.addAll(addresses);
            sorted.addAll(affiliations);
            sorted.addAll(errors);
            sorted.addAll(households);
            sorted.addAll(payments);
            sorted.addAll(recDonations);
            sorted.addAll(relationships);
            sorted.addAll(allocations);
            sorted.addAll(unknown);
            
            return sorted;
        }
    }
    
    global enum Action {   
        BeforeInsert, 
        BeforeUpdate, 
        BeforeDelete, 
        AfterInsert, 
        AfterUpdate, 
        AfterDelete,
        AfterUndelete
    }
}