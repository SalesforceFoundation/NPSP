/*
    Copyright (c) 2014, Salesforce.org
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
* @author Sten Ebenau
* @date 28 February 2017
* @group ContactMerge
* @description Batch class to merge multiple contacts.
*/

public class CON_ContactMerge_BATCH implements Database.Batchable<SObject>{
	
	/*******************************************************************************************************
    * @description masterContact holds the master contact where all losers are merged into. 
    */
    private Contact masterContact {get; set;}
    
    /*******************************************************************************************************
    * @description loserIds hold all loser contacts. These are merged into the masterContact
    */
    private List<Id> loserIds {get; set;}
    
	/*******************************************************************************************************
    * @description Constructs the class, sets the properties
    * @param master masterContact 
    * @param losers List<Id> containing all loserids.
    */
	public CON_ContactMerge_BATCH(Contact master, List<Id> losers) {
		this.masterContact = master;
		this.loserIds = losers;
	}
	
	/*******************************************************************************************************
    * @description Start of batch process. Fetches all the loser contacts. 
    * @param bc BatchableContext passed by the system call
    */
	public database.Querylocator start(Database.BatchableContext bc) {
        if (Test.isRunningTest()) {
        	return Database.getQueryLocator([Select Id, Name FROM Contact WHERE Id IN :this.loserIds LIMIT 1]);
        } 
        return Database.getQueryLocator([Select Id, Name FROM Contact WHERE Id IN :this.loserIds]);
    }
    
    /*******************************************************************************************************
    * @description End of Batch Contact Merge, nothing happens here. 
    * @param bc BatchableContext passed by the system call
    * @param scope List of Contacts passed by the system call. 
    */
    public void execute(Database.BatchableContext bc, List<Contact> scope) {
    	for (Contact loser : scope) {
    		Savepoint sp = Database.setSavepoint();
    		try {
    			CON_ContactMerge.mergeContacts(this.masterContact, new List<Contact>{loser});
    		} catch (DMLException e) {
    			Database.rollback(sp);
    		}
    	}
    }
    
    /*******************************************************************************************************
    * @description End of Batch Contact Merge, nothing happens here. 
    * @param bc BatchableContext passed by the system call
    */
    public void finish(Database.BatchableContext bc) {
    	
    }
	
	
	


    
}