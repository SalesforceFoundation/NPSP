/*
    Copyright (c) 2010, Salesforce.com Foundation
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
* @author Jason Venable & Evan Callahan
* @date 2010 (2.x)
* @description Controller for lead conversion of all contacts
*/
public with sharing class LD_LeadConvertOverride_CTRL {
// Controller for lead conversion of all contacts
 
// Written by jason venable and evan callahan
// at the NPSP Sprint 2010    

    // properties for page
    public lead l { get; set; }
    public Contact dummyCon { get; set; }
    public boolean sendEmailToOwner { get; set; }
    //public string acct { get; set; }  
    public string con { get; set; }
    public string oppName { get; set; }
    public boolean doNotCreateOpp { get; set; }
    
    public string leadConvStatus { 
    	get {
    		if (leadConvStatus == null || leadConvStatus == '') {
                if (lcStatuses != null && lcStatuses.size() > 0)
                    leadConvStatus = lcStatuses[0].getValue();
    		}
    		return leadConvStatus;
    	}
    	set;
    }

    //public task leadTask { get; set; }

    //public list<selectOption> acctList = new list<selectOption>(); 
    public list<selectOption> conList; 
    map<id, contact> conMap = new map<id, contact>(); 
    
    private npe01__Contacts_And_Orgs_Settings__c ContactsSettings; 
    
    public LD_LeadConvertOverride_CTRL(ApexPages.StandardController controller) {
        ContactsSettings = UTIL_CustomSettingsFacade.getContactsSettings();
                            
        // get the lead
        l = [select id, name, firstname, lastname, company, email, ownerId from lead
            where id = : controller.getId()];
        
        // dummy contact allows owner selection - use contact as always accessible if user has lead conversion rights
        dummyCon = new Contact(
            OwnerId = ((((string)(l.ownerid)).startsWith('005')) ? l.ownerid : userInfo.getUserId())
        );
        
        // set a default opp name
        oppName = l.name;
        doNotCreateOpp = !Schema.SObjectType.Opportunity.isCreateable() || !ContactsSettings.npe01__Default_Opp_on_Convert__c;
        sendEmailToOwner = false;        
    }    
    
    public list<selectOption> getConList() {
        if (conList == null) { 
            conList = new list<selectOption>();
            
            conList.add( new SelectOption('', '--None--') );
            conList.add( new SelectOption('NEW_CONTACT', 'Create New: ' + l.name) );            
        
            // find contact matches
            conMap = new map<id, contact>([select id, name, accountid, firstname, lastname from contact where 
                (lastname = : l.lastname and firstname = : l.firstname) or
                (email = : l.email and email != null) limit 50]);
                
            for (contact c : conMap.values()) {
                conList.add( new SelectOption(c.id, 'Merge with Existing: ' + c.name) );                            
            }
        }
        return conList; 
    } 
    
    public list<selectOption> lcStatuses {
    	get {
	        if (lcStatuses == null) {
	            lcStatuses = new list<selectOption>();
	            // query
	            for (LeadStatus ls : [Select Id, Masterlabel from LeadStatus where IsConverted=true] ) {
	                lcStatuses.add( new SelectOption(ls.masterlabel, ls.masterlabel));
	            }
	            //leadConvStatus = lcStatuses[0].getValue();
	        }
	        return lcStatuses;
    	}
    	private set;
    } 
    
    // utility to handle all the lead.company scenarios that specify
    // that our special account handling should be used.
    private boolean isSpecialAccount() {
    	if (l == null)
    	   return false;
    	return (
    	   l.company == null ||
    	   l.company == '' ||
    	   l.company.toLowerCase() == 'self' ||
    	   l.company.toLowerCase() == 'individual' ||
    	   l.company.toLowerCase() == l.name.toLowerCase()
        ); 
    }
    
    public pageReference convertLeadNow() {
    	Savepoint sp = Database.setSavepoint();
    	try {
	        if (con == null) {
	            apexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error,
	                'You must select an option in the Contact box.'));
	            return null;
	        }
	        
	        // set up the conversion
	        Database.LeadConvert lc = new database.LeadConvert();
	        lc.setLeadId(l.Id);
	        if (!doNotCreateOpp && Schema.SObjectType.Opportunity.isCreateable()) lc.setOpportunityName(oppName);
	        lc.setDoNotCreateOpportunity(!Schema.SObjectType.Opportunity.isCreateable() || doNotCreateOpp);
	        lc.setConvertedStatus(leadConvStatus);
	        lc.setOwnerId(dummyCon.OwnerId);
	        lc.setSendNotificationEmail(sendEmailToOwner);
	        
	        // is this a merge to existing?
	        if (con != 'NEW_CONTACT') { 
	            // get this contact's account
	            lc.setContactId(con);
	            lc.setAccountId(conMap.get(con).accountId);          
	        } else if (CAO_Constants.isBucketModel() && isSpecialAccount()) {
	               lc.setAccountID(CAO_Constants.getIndividualAccountID());
	        }    
	
	        // convert the lead
	        Database.LeadConvertResult lcr = Database.convertLead(lc);
            
            // fix the account that lead conversion created
            if (con == 'NEW_CONTACT') {  
            	string strSoql = 'select id, firstname, lastname,';
            	if (Schema.sObjectType.Contact.fields.getMap().get('RecordTypeId') != null)
            	   strSoql += ' recordtypeId,';
            	strSoql += ' npo02__Household__c, MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry, HomePhone, Email';
                strSoql += ' from contact where id= \'' + lcr.getContactId() + '\'';             	
            	Contact con = database.query(strSoql);   
                Account myAccount = new Account(Id=lcr.getAccountId());
                
                // update the account if it is non-standard 
                if (isSpecialAccount()) {
	                if (CAO_Constants.isOneToOne()) {
		                myAccount.Name = ACCT_IndividualAccounts_TDTM.strNameOne2OneAccountForContact(con);
		                myAccount.npe01__SYSTEM_AccountType__c = CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE;
	                } else if (CAO_Constants.isHHAccountModel()) { 
	                	myAccount.Name = ACCT_IndividualAccounts_TDTM.strNameHHAccountForContact(con);
	                	myAccount.npe01__SYSTEM_AccountType__c = CAO_Constants.HH_ACCOUNT_TYPE;
	                }
	                
	                if (!CAO_Constants.isBucketModel()) {
	                	// change its recordtype if specified in settings 
	                    ID rtIdAcccount = ACCT_IndividualAccounts_TDTM.rtIdForNewAccount();
		                if (rtIdAcccount != null) {                
		                    myAccount.put('RecordTypeID', rtIdAcccount);
		                }                                    
		                myAccount.npe01__SYSTEMISINDIVIDUAL__c = true;
	                    myAccount.npe01__One2OneContact__c = con.Id;
		                update myAccount;                    
   	                }
                }
                                             
	            // see if we need to create a household object for this contact (1:1 & bucket only)
	            if (!CAO_Constants.isHHAccountModel() && con.npo02__Household__c == null) {
	                npo02__Households_Settings__c hs = UTIL_CustomSettingsFacade.getHouseholdsSettings();                
	                if (hs.npo02__Household_Rules__c == HH_Households.ALL_PROCESSOR || hs.npo02__Household_Rules__c == HH_Households.ALL_INDIVIDUALS_PROCESSOR) {
	                    HH_Households_TDTM.insertHousehold(new list<Contact>{con}, true, null);
	                    update con;                         
	                }
	            }
            }     
                        
            //clean up the extra OCR Issue #214
            // if we create an opp, its a 1x1 (or HH?), and its merged into an existing contact
            if (!lc.isDoNotCreateOpportunity() && !CAO_Constants.isBucketModel() && con != 'NEW_CONTACT'){
                
                //get the new OCRs
                list<OpportunityContactRole> ocrList = [select id, isPrimary, Role from OpportunityContactRole where OpportunityID = :lcr.getOpportunityId() and ContactID = :lcr.getContactId()];
                
                //if there are more than one, find the primary with the right role, and delete 
                //the extraneous ones
                if (ocrList != null && ocrList.size() > 1){
                    list<OpportunityContactRole> dlist = new list<OpportunityContactRole>();
                    for (OpportunityContactRole ocr : ocrList){
                        if (!ocr.IsPrimary && dlist.size()+1 != ocrList.size()){
                            dlist.add(ocr);     
                        }
                        else if (ocr.Role != ContactsSettings.npe01__Opportunity_Contact_Role_Default_role__c && dlist.size()+1 != ocrList.size()){
                            dlist.add(ocr);
                        }
                    }
                    delete dlist;
                    
                    //on delete of one ocr, the other 'isPrimary' is set to false
                    //so we need to issue an udpate to correct it. 
                    OpportunityContactRole ocr = ocrList[0];
                    ocr.IsPrimary = true;
                    update ocr;
                } 
                        
	        }
	        // redirect
            return new PageReference('/' + lcr.getContactId());                  
    	} catch (exception e) {
            Database.rollback(sp);
            ERR_Handler.processError(e, ERR_Handler.Context.LD);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            return null;
        }
    }
}