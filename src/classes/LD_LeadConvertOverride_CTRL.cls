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
* @group Lead Conversion
* @group-content ../../ApexDocContent/LeadConversion.htm
* @description Controller for lead conversion of all contacts
*/
public with sharing class LD_LeadConvertOverride_CTRL {
// Controller for lead conversion of all contacts

// Written by jason venable and evan callahan
// at the NPSP Sprint 2010

    /*******************************************************************************************************
    * @description Sets the Lead to be converted
    */
    public lead l { get; set; }
    /*******************************************************************************************************
    * @description Provides a dummy Contact to write to - avoids ownership issues when setting owner
    */
    public Contact dummyCon { get; set; }
    /*******************************************************************************************************
    * @description Sends email to the owner on conversion if selected
    */
    public boolean sendEmailToOwner { get; set; }
    
    /*******************************************************************************************************
    * @description Contains the Id or 'NEW' for the Account to use.
    */
    public string strAccountId { get; set; }
    
    /*******************************************************************************************************
    * @description Contains the Id or 'NEW' for the Primary Affiliation to use.
    */
    public string strAfflAccountId { get; set; }
    
    /*******************************************************************************************************
    * @description Contains the value of the converted-into Contact
    */
    public string strConId { get; set; }

    /*******************************************************************************************************
    * @description Constructs the value of the Opportunity name if created
    */
    public string oppName { get; set; }
    /*******************************************************************************************************
    * @description Determines if an Opportunity is not created
    */
    public boolean doNotCreateOpp { get; set; }

    /*******************************************************************************************************
    * @description Shows the value of the lead status
    */
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

    /*******************************************************************************************************
    * @description List of possible matching Contacts
    */
    public list<selectOption> conList;

    /*******************************************************************************************************
    * @description Settings for the main Contacts & Organizations pacakge (npe01)
    */
    private npe01__Contacts_And_Orgs_Settings__c ContactsSettings;

    /*******************************************************************************************************
    * @description Select options for the possible Lead Statuses
    */
    public list<selectOption> lcStatuses {
      get {
        if (lcStatuses == null) {
          lcStatuses = new list<selectOption>();
          for (LeadStatus ls : [Select Id, Masterlabel from LeadStatus where IsConverted=true] ) {
            lcStatuses.add( new SelectOption(ls.masterlabel, ls.masterlabel));
          }
        }
        return lcStatuses;
      }
      private set;
    }

    /*******************************************************************************************************
    * @description Checks the value of the 'Company' field for values associated with 1x1 or Individual Accounts
    */
    public boolean isSpecialAccount {
        get {
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
    }

    /*******************************************************************************************************
    * @description Provides the options for select list of possible Contact matches
    */
    public list<selectOption> getConList() {
      if (conList == null) {
        conList = new list<selectOption>();

        conList.add( new SelectOption('', label.stgLabelNone) );
        conList.add( new SelectOption('NEW_CONTACT', label.leadConvertCreateNewContact + ' ' + l.name) );

        for (contact c : conMap.values()) {
          conList.add( new SelectOption(c.id, label.leadConvertMergeExistingContact + ' ' + c.name) );
        }
      }
      return conList;
    }

    /*******************************************************************************************************
    * @description Display the selection list for matching Contacts
    */
    private map<id, contact> conMap {
        get {
            if (conMap == null) {
                // find contact matches
                conMap = new map<id, contact>([select id, name, accountid, firstname, lastname from contact where
                (lastname = : l.lastname and firstname = : l.firstname) or
                (email = : l.email and email != null) limit 50]);            
            }
            return conMap;
        }
        set;
    }

    /*******************************************************************************************************
    * @description Provides the options for select list of possible Account to use for the Contact
    */
    public list<selectOption> listSOAccounts {
        get {
            if (listSOAccounts == null) {
                listSOAccounts = new list<selectOption>();
                string strAcc;
                if (CAO_CONSTANTS.isHHAccountModel())
                    strAcc = label.leadConvertAutocreateHHAccount;
                else if (CAO_CONSTANTS.isOneToOne())
                    strAcc = label.leadConvertAutocreateOne2OneAccount;
                else if (CAO_CONSTANTS.isBucketModel())
                    strAcc = label.leadConvertAttachBucketAccount;
                if (strAcc != null)
                    listSOAccounts.add(new SelectOption('AUTO', strAcc));
                    
                if (!isSpecialAccount) {
                    // find Account matches
                    for (Account acc : mapIdAccountMatches.values())
                        listSOAccounts.add(new SelectOption(acc.Id, Label.leadConvertAttachExistingAccount + ' ' + acc.Name));
                    // new Account
                    listSOAccounts.add(new SelectOption('NEW', Label.leadConvertCreateAccount + ' ' + l.Company));
                }
            }
        return listSOAccounts;
        }
      
        set;
    }
    
    /*******************************************************************************************************
    * @description Provides the options for select list of possible Accounts to use for the Affiliation
    */
    public list<selectOption> listSOAfflAccounts {
        get {
            if (listSOAfflAccounts == null) {
                listSOAfflAccounts = new list<selectOption>();
                listSOAfflAccounts.add(new SelectOption('', label.stgLabelNone));
                if (!isSpecialAccount) {
                    // find Account matches
                    for (Account acc : mapIdAccountMatches.values())
                        listSOAfflAccounts.add(new SelectOption(acc.Id, Label.leadConvertAffiliateExistingAccount + ' ' + acc.Name));
                    // new Account
                    listSOAfflAccounts.add(new SelectOption('NEW', Label.leadConvertAffiliateNewAccount + ' ' + l.Company));
                }
            }
        return listSOAfflAccounts;
        }
      
        set;
    }

    /*******************************************************************************************************
    * @description map of all Accounts that match the name of Lead.Company
    */
    public map<Id, Account> mapIdAccountMatches {
        get {
            if (mapIdAccountMatches == null) {
                mapIdAccountMatches = new map<Id, Account>([select Id, Name, BillingCity from Account where name = :l.company limit 50]);
            }
            return mapIdAccountMatches;
        }
        set;
    }

    /*******************************************************************************************************
    * @description Constructs the page and default values for the Lead, dummy Contact and Opportunity
    * @param controller Standard page controller for the page
    * @param result Results to be processed from the query
    */
    public LD_LeadConvertOverride_CTRL(ApexPages.StandardController controller) {
        ContactsSettings = UTIL_CustomSettingsFacade.getContactsSettings();

        // get the lead
        l = [select id, name, firstname, lastname, company, email, title, ownerId from lead
            where id = : controller.getId()];

        // dummy contact allows owner selection - use contact as always accessible if user has lead conversion rights
        dummyCon = new Contact(
            OwnerId = ((((string)(l.ownerid)).startsWith('005')) ? l.ownerid : userInfo.getUserId())
        );

        // set a default opp name
        oppName = l.name;
        doNotCreateOpp = !Schema.SObjectType.Opportunity.isCreateable() || !ContactsSettings.npe01__Default_Opp_on_Convert__c;
        sendEmailToOwner = false;
        
        // set reasonable defaults for contact and account.
        strAccountId = 'AUTO';
        if (conMap.size() == 0)
            strConId = 'NEW_CONTACT';
        if (!isSpecialAccount)
            strAfflAccountId = listSOAfflAccounts[1].getValue(); // either the first existing or the new account if none.
    }
    
    /*******************************************************************************************************
    * @description action method called when the page is created, which decides whether to defer to the
    * standard Salesforce Lead Convert page (when the Account is a company) vs. using the NPSP version (when
    * the Account is self/invididual/name to imply an 1:1/household/bucket account).
    * @return PageReference to either standard or null (this custom lead convert page).
    */
    public pageReference pickLeadConvertPage() {
        PageReference pageRef = null;
        
        if (!isSpecialAccount) {
            pageRef = new PageReference('/lead/leadconvert.jsp?retURL=%2F' + l.Id + '&id=' + l.Id + '&nooverride=1');
            pageRef.setRedirect(true);
        }
        return pageRef;
    }               

    /*******************************************************************************************************
    * @description Converts the actual Lead.  All conversion logic is contained in this method
    * @return PageReference
    */
    public pageReference convertLeadNow() {
    	Savepoint sp = Database.setSavepoint();
    	try {
	        if (strConId == null) {
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
	        
	        boolean isIndividualAccount = isSpecialAccount || strAccountId == 'AUTO';

	        // is this a merge to existing?
	        if (strConId != 'NEW_CONTACT') {
	            // get this contact's account
	            lc.setContactId(strConId);
	            lc.setAccountId(conMap.get(strConId).accountId);
	        } else if (strAccountId != 'NEW' && strAccountId != 'AUTO' && strAccountId != null && strAccountId != '') {
	           lc.setAccountId(strAccountId);
	        } else if (CAO_Constants.isBucketModel() && isIndividualAccount) {
                lc.setAccountID(CAO_Constants.getIndividualAccountID());
	        }

	        // avoid auto-affiliation creation
            AFFL_Affiliations_TDTM.hasRunForContacts = true;
            AFFL_Affiliations_TDTM.hasRunForAccounts = true;

	        // convert the lead
	        Database.LeadConvertResult lcr = Database.convertLead(lc);

            // fix the account that lead conversion created
            if (strConId == 'NEW_CONTACT' && isIndividualAccount) {
            	string strSoql = 'select id, firstname, lastname,';
            	if (Schema.sObjectType.Contact.fields.getMap().get('RecordTypeId') != null)
            	   strSoql += ' recordtypeId,';
            	strSoql += ' npo02__Household__c, MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry, HomePhone, Email';
                strSoql += ' from contact where id= \'' + lcr.getContactId() + '\'';
            	Contact con = database.query(strSoql);
                Account myAccount = new Account(Id=lcr.getAccountId());
                npo02__Households_Settings__c hs = UTIL_CustomSettingsFacade.getHouseholdsSettings();

                // update the account since it is non-standard
                if (CAO_Constants.isOneToOne()) {
                    myAccount.Name = ACCT_IndividualAccounts_TDTM.strNameOne2OneAccountForContact(con);
                    myAccount.npe01__SYSTEM_AccountType__c = CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE;
                } else if (CAO_Constants.isHHAccountModel()) {
                    // if custom household naming is on, we need to leave the account name untouched,
                    // so on update, it will get its correct name.
                    if (!hs.npo02__Advanced_Household_Naming__c)
                        myAccount.Name = ACCT_IndividualAccounts_TDTM.strNameHHAccountForContact(con);
                        myAccount.npe01__SYSTEM_AccountType__c = CAO_Constants.HH_ACCOUNT_TYPE;
                    }
                
                if (!CAO_Constants.isBucketModel()) {
                    // change its recordtype if specified in settings
                    ID rtIdAcccount = ACCT_IndividualAccounts_TDTM.rtIdForNewAccount();
                    if (rtIdAcccount != null) 
                        myAccount.put('RecordTypeID', rtIdAcccount);
                    myAccount.npe01__SYSTEMISINDIVIDUAL__c = true;
                    myAccount.npe01__One2OneContact__c = con.Id;
                    update myAccount;
                    }

	            // see if we need to create a household object for this contact (1:1 & bucket only)
	            if (!CAO_Constants.isHHAccountModel() && con.npo02__Household__c == null) {
	                if (hs.npo02__Household_Rules__c == HH_Households.ALL_PROCESSOR || 
	                   hs.npo02__Household_Rules__c == HH_Households.ALL_INDIVIDUALS_PROCESSOR) {
	                    HH_Households_TDTM.insertHousehold(new list<Contact>{con}, true, null);
	                    update con;
	                }
	            }
            }

            //clean up the extra OCR Issue #214
            // if we create an opp, its a 1x1 (or HH), and its merged into an existing contact
            if (!lc.isDoNotCreateOpportunity() && !CAO_Constants.isBucketModel() && strConId != 'NEW_CONTACT'){

                //get the new OCRs
                list<OpportunityContactRole> ocrList = [select id, isPrimary, Role from OpportunityContactRole where 
                    OpportunityID = :lcr.getOpportunityId() and ContactID = :lcr.getContactId()];

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
	        
            // if we created a new company account, affiliate to it.
            if (strAccountId == 'NEW')
                strAfflAccountId = lcr.getAccountId();
                
            // handle the optional Affiliation to a new or existing Account.
            ID afflAccId = null;
            if (strAfflAccountId == 'NEW') {
                Account acc = new Account(name=l.Company);
                insert acc;
                afflAccId = acc.Id;
            } else if (strAfflAccountId != null && strAfflAccountId != '') {
            	afflAccId = strAfflAccountId;
            }
            if (afflAccId != null) {
                AFFL_Affiliations_TDTM.hasRunForContacts = false;
                AFFL_Affiliations_TDTM.hasRunForAccounts = false;
                AFFL_Affiliations_TDTM.createNonDupeAffiliation(l, lcr.getContactId(), afflAccId, true); 
            }
	        // redirect
            return new PageReference('/' + lcr.getContactId());
    	} catch (exception e) {
            Database.rollback(sp);
            ERR_Handler.processError(e, ERR_Handler_API.Context.LD);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            return null;
        }
    }
}