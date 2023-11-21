/*
    Copyright (c) 2010, Salesforce.org
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

    @TestVisible
    private OrgConfig orgConfig {
        get {
            if (orgConfig == null) {
                orgConfig = new OrgConfig();
            }
            return orgConfig;
        }
        set;
    }

    /*******************************************************************************************************
    * @description Sets the Lead to be converted
    */
    public Lead leadToConvert { get; set; }
    /*******************************************************************************************************
    * @description Provides a dummy Contact to write to - avoids ownership issues when setting owner
    */
    public Contact dummyCon { get; set; }
    /*******************************************************************************************************
    * @description Sends email to the owner on conversion if selected
    */
    public Boolean sendEmailToOwner { get; set; }

    /*******************************************************************************************************
    * @description Contains the Id or 'NEW' for the Account to use.
    */
    public String leadAccountId { get; set; }

    /*******************************************************************************************************
    * @description Contains the Id or 'NEW' for the Primary Affiliation to use.
    */
    public String primaryAffiliationId { get; set; }

    /*******************************************************************************************************
    * @description Determines the account that the created Opportunity will be related to.
    * 'CON_ACC' -> Contact.AccountId
    * 'AFF_ACC' -> Contact.Primary_Affiliation__c
    */
    public String strOppAccChoice { get; set; }

    /*******************************************************************************************************
    * @description Contains the value of the converted-into Contact
    */
    public String convertedContactId { get; set; }

    /*******************************************************************************************************
    * @description Constructs the value of the Opportunity name if created
    */
    public String oppName { get; set; }
    /*******************************************************************************************************
    * @description Determines if an Opportunity is not created
    */
    public Boolean doNotCreateOpp { get; set; }

    /*******************************************************************************************************
    * @description List of possible matching Contacts
    */
    public List<SelectOption> conList;

    /*******************************************************************************************************
    * @description Selected Contact
    */
    public Contact selectedCon;

    /*******************************************************************************************************
    * @description List of possible Opportunity Account
    */
    public List<SelectOption> oppAccChoices;

    /*******************************************************************************************************
    * @description Settings for the main Contacts & Organizations pacakge (npe01)
    */
    private npe01__Contacts_And_Orgs_Settings__c ContactsSettings;

    public Boolean hasAccess {
        get {
            if (hasAccess == null) {
                hasAccess = getCurrentUserHasAccess();
            }
            return hasAccess;
        }
        private set;
    }

    private UTIL_Permissions perms {
        get {
            if (perms == null) {
                perms = new UTIL_Permissions();
            }

            return perms;
        }
        set;
    }

    /*******************************************************************************************************
    * @description Select options for the possible Lead Statuses
    */
    public List<SelectOption> lcStatuses {
        get {
            if (lcStatuses == null) {
                lcStatuses = new List<SelectOption>();

                for (LeadStatus ls : [
                        SELECT Id, ApiName, MasterLabel
                        FROM LeadStatus
                        WHERE IsConverted = TRUE
                ]) {
                    lcStatuses.add(
                            new SelectOption(
                                    ls.ApiName.escapeHtml4(),
                                    ls.MasterLabel.escapeHtml4()));
                }
            }
            return lcStatuses;
        } private set;
    }

    /*******************************************************************************************************
    * @description Checks the value of the 'Company' field for values associated with 1x1 or Individual Accounts
    */
    public Boolean isLegacyHousehold {
        get {
            if (leadToConvert == null) {
                return false;
            }
            return (
                leadToConvert.Company == null ||
                leadToConvert.Company == '' ||
                leadToConvert.Company.toLowerCase() == 'self' ||
                leadToConvert.Company.toLowerCase() == 'individual' ||
                leadToConvert.Company.toLowerCase() == leadToConvert.Name.toLowerCase()
            );
        } private set;
    }

    /*******************************************************************************************************
    * @description Provides the options for select list of possible Contact matches
    */
    public List<SelectOption> getConList() {
      if (conList == null) {
        conList = new List<SelectOption>();

        conList.add( new SelectOption('', System.Label.stgLabelNone) );
        conList.add( new SelectOption('NEW_CONTACT',
                System.Label.leadConvertCreateNewContact + ' ' + leadToConvert.Name) );

        for (Contact c : conMap.values()) {
          conList.add( new SelectOption(c.Id,
                  System.Label.leadConvertMergeExistingContact + ' ' + c.Name) );
        }
      }
      return conList;
    }

    public List<SelectOption> getOppAccChoices() {
        if(oppAccChoices == null) {
            oppAccChoices = new List<SelectOption>();

            oppAccChoices.add(new SelectOption(
                    'CON_ACC', System.Label.leadConvertContactAccount));
            oppAccChoices.add(new SelectOption(
                    'AFF_ACC', System.Label.leadConvertAffiliatedAccount));
        }
        return oppAccChoices;
    }

    /*******************************************************************************************************
    * @description Display the selection list for matching Contacts
    */
    @TestVisible private Map<Id, Contact> conMap {
        get {
            if (conMap == null) {
                conMap = new Map<Id, Contact>((List<Contact>) contactFinder.find());
            }
            return conMap;
        }
        set;
    }

    /*******************************************************************************************************
    * @description Finder used to search Contact using either SOQl or SOSL
    */
    @TestVisible private UTIL_Finder contactFinder {
        get {
            if (contactFinder == null) {
                UTIL_Where whereClause = new UTIL_Where().withOr()
                    .add(UTIL_Where.AndGroup()
                        .add(new UTIL_Where.FieldExpression(Contact.LastName).equals(leadToConvert.LastName))
                        .add(new UTIL_Where.FieldExpression(Contact.FirstName).equals(leadToConvert.FirstName))
                    );
                if (String.isNotBlank(leadToConvert.Email)) {
                    whereClause.add(UTIL_Where.AndGroup()
                        .add(new UTIL_Where.FieldExpression(Contact.Email).equals(leadToConvert.Email))
                    );
                }

                contactFinder = new UTIL_Finder(Contact.SObjectType)
                        .withSelectFields(new Set<Schema.SObjectField>{
                                Contact.Id, Contact.Name, Contact.FirstName,
                                Contact.LastName, Contact.Email
                        })
                    .withSelectFields(conFieldSet)
                    .withWhere(whereClause)
                    .withLimit(50);
            }
            return contactFinder;
        }
        set;
    }

    /*******************************************************************************************************
    * @description holds the list of FieldSetMembers from the appropriate field set.
    * @return List<Schema.FieldSetMember>
    */
    public List<Schema.FieldSetMember> conFieldSet {
        get {
            if (conFieldSet == null) {
                conFieldSet = Schema.SObjectType.Contact.fieldSets.ContactMergeFoundFS.getFields();
            }
            return conFieldSet;
        }
        private set;
    }

    /*******************************************************************************************************
    * @description Display the selected Contact
    */
    public Contact getSelectedCon() {
        if (convertedContactId !='NEW_CONTACT' & convertedContactId !=null && conMap.containsKey(convertedContactId)) {
            selectedCon = conMap.get(convertedContactId);
        } else {
            selectedCon = null;
        }
        return selectedCon;
    }

    /*******************************************************************************************************
    * @description Provides the options for select list of possible Account to use for the Contact
    */
    public List<SelectOption> listSOAccounts {
        get {
            if (listSOAccounts == null) {
                listSOAccounts = new List<SelectOption>();
                String strAcc;
                if (CAO_Constants.isHHAccountModel()) {
                    strAcc = System.Label.leadConvertAutocreateHHAccount;
                }
                else if (CAO_Constants.isOneToOne()) {
                    strAcc = System.Label.leadConvertAutocreateOne2OneAccount;
                }
                else if (CAO_Constants.isBucketModel()) {
                    strAcc = System.Label.leadConvertAttachBucketAccount;
                }
                if (strAcc != null) {
                    listSOAccounts.add(new SelectOption('AUTO', strAcc));
                }

                if (!isLegacyHousehold) {
                    // find Account matches
                    for (Account acc : mapIdAccountMatches.values()) {
                        listSOAccounts.add(
                                new SelectOption(
                                        acc.Id,
                                        System.Label.leadConvertAttachExistingAccount
                                                + ' ' + acc.Name));
                    }
                    // new Account
                    listSOAccounts.add(
                            new SelectOption(
                                    'NEW',
                                    System.Label.leadConvertCreateAccount
                                            + ' ' + leadToConvert.Company));
                }
            }
        return listSOAccounts;
        }

        set;
    }

    /*******************************************************************************************************
    * @description Provides the options for select list of possible Accounts to use for the Affiliation
    */
    public List<SelectOption> listSOAfflAccounts {
        get {
            if (listSOAfflAccounts == null) {
                listSOAfflAccounts = new List<SelectOption>();
                listSOAfflAccounts.add(new SelectOption('', System.Label.stgLabelNone));
                if (!isLegacyHousehold) {
                    // find Account matches
                    for (Account acc : mapIdAccountMatches.values()) {
                        listSOAfflAccounts.add(
                                new SelectOption(
                                        acc.Id,
                                        System.Label.leadConvertAffiliateExistingAccount +
                                                ' ' + acc.Name
                                ));
                    }
                    // new Account
                    listSOAfflAccounts.add(new SelectOption('NEW', System.Label.leadConvertAffiliateNewAccount + ' ' + leadToConvert.Company));
                }
            }
        return listSOAfflAccounts;
        }

        set;
    }

    /*******************************************************************************************************
    * @description map of all Accounts that match the name of Lead.Company
    */
    public Map<Id, Account> mapIdAccountMatches {
        get {
            if (mapIdAccountMatches == null) {
                mapIdAccountMatches = new Map<Id, Account>((List<Account>) accountFinder.find());
            }
            return mapIdAccountMatches;
        }
        set;
    }

    /*******************************************************************************************************
    * @description Finder used to search Accounts using either SOQl or SOSL (the Account.Name is encryted)
    */
    @TestVisible private UTIL_Finder accountFinder {
        get {
            if (accountFinder == null) {
                accountFinder = new UTIL_Finder(Account.SObjectType)
                        .withSelectFields(new Set<Schema.SObjectField>{
                                Account.Id, Account.Name, Account.BillingCity
                        })
                        .withWhere(new UTIL_Where.FieldExpression(Account.Name).equals(leadToConvert.Company))
                        .withLimit(50);
            }
            return accountFinder;
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
        leadToConvert = [
                SELECT Id, Name, FirstName, LastName, Company, Email, Title, OwnerId, Status,
                        CompanyStreet__c, CompanyCity__c, CompanyState__c,
                        CompanyPostalCode__c, CompanyCountry__c
                FROM Lead
                WHERE Id = :controller.getId()
        ];

        // dummy contact allows owner selection - use contact as always accessible if user
        // has lead conversion rights
        dummyCon = new Contact(
                OwnerId = ((((String) (leadToConvert.OwnerId)).startsWith('005')) ?
                        leadToConvert.OwnerId : UserInfo.getUserId())
        );

        // set a default opp name
        oppName = leadToConvert.Name;
        doNotCreateOpp = !Schema.SObjectType.Opportunity.isCreateable()
                || !ContactsSettings.npe01__Default_Opp_on_Convert__c;
        sendEmailToOwner = false;

        // set reasonable defaults for contact and account.
        leadAccountId = 'AUTO';
        if (conMap.size() == 0) {
            convertedContactId = 'NEW_CONTACT';
        }
        if (!isLegacyHousehold) {
            primaryAffiliationId = listSOAfflAccounts[1].getValue();
        } // either the first existing
        // or the new account if none.

        // warn user if default record type is the same as the HH Account Record Type
        Id recTypeId =
                UTIL_CustomSettingsFacade.getContactsSettings().npe01__HH_Account_RecordTypeID__c;
        if (recTypeId != null) {
            SObjectType objType = Account.SObjectType;
            String recTypeName = UTIL_RecordTypes.getRecordTypeName(objType, recTypeId);
            if (UTIL_RecordTypes.isRecordTypeDefault(objType, recTypeName)) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING,
                        System.Label.leadConvertRecordTypeWarning));
            }
        }
    }

    /*******************************************************************************************************
    * @description action method called when the page is created, which decides whether to defer to the
    * standard Salesforce Lead Convert page (when the Account is a company) vs. using the NPSP version (when
    * the Account is self/invididual/name to imply an 1:1/household/bucket account).
    * @return PageReference to either standard or null (this custom lead convert page).
    */
    public PageReference pickLeadConvertPage() {
        PageReference pageRef = null;

        if (!isLegacyHousehold) {
            pageRef = new PageReference('/lead/leadconvert.jsp?retURL=%2F' +
                    leadToConvert.Id + '&id=' + leadToConvert.Id + '&nooverride=1');
            pageRef.setRedirect(true);
        }
        return pageRef;
    }

    /*******************************************************************************************************
    * @description Converts the actual Lead.  All conversion logic is contained in this method
    * @return PageReference
    */
    public PageReference convertLeadNow() {
        Savepoint sp = Database.setSavepoint();

        if (!isContactSelected()) {
            return displayNoContactSelectedError();
        }

        Database.LeadConvert instanceOfLeadConvert = prepareLeadConversion();
        // avoid auto-affiliation creation by disabling the Affiliations Trigger for Contacts
        disableAffiliationTrigger();

        Boolean isHouseholdAddressesDisabled = isHouseholdAddressesDisabled();
        Boolean isOrganizationAddressesDisabled = isOrganizationAddressesEnabled();

        // temporarily disable address management
        disableAddressManagement();

        try {
            // convert the lead
            Database.LeadConvertResult leadConversionResult = Database.convertLead(instanceOfLeadConvert);
            // restore address management
            restoreAddressManagement(isHouseholdAddressesDisabled, isOrganizationAddressesDisabled);
            // fix the account that lead conversion created
            if (shouldFixConvertedAccount()) {
                fixConvertedAccount(leadConversionResult);
            }

            //clean up the extra OCR Issue
            // if we create an opp, its a 1x1 (or HH),
            // before 6/2016 this fix was only applied if merging into an existing contact,
            // but we've run into multiple orgs where they can reproduce the bug when creating new contacts.
            // npsp devs have not been able to reproduce it, but feel this is a safe fix for all.
            deleteDuplicateOpportunityContactRoles(instanceOfLeadConvert, leadConversionResult);

            // if we created a new company account, affiliate to it.
            if (isConvertedAccountNew()) {
                setPrimaryAffiliationId(leadConversionResult.getAccountId());
            }

            Address__c tempAddr = new Address__c(
                    MailingStreet__c = leadToConvert.CompanyStreet__c,
                    MailingCity__c = leadToConvert.CompanyCity__c,
                    MailingState__c = leadToConvert.CompanyState__c,
                    MailingPostalCode__c = leadToConvert.CompanyPostalCode__c,
                    MailingCountry__c = leadToConvert.CompanyCountry__c
            );

            // if we created a new company acct and the Lead had a company address, set the
            // new acct's address
            if (shouldUpdateAccountAddress()) {
                updateAccountAddress(leadConversionResult, tempAddr);
            }
            // handle the optional Affiliation to a new or existing Account.
            Id affiliationId = createAffiliation(tempAddr, leadConversionResult);

            //// Opportunity Cleanup
            if(!instanceOfLeadConvert.isDoNotCreateOpportunity()) {
                updateOpportunityWithConversionResult(leadConversionResult, affiliationId);
            }
            UserRecordAccess userContactAccess = [SELECT RecordId, HasReadAccess
                                                 FROM UserRecordAccess
                                                 WHERE RecordId = :leadConversionResult.getContactId()
                                                 AND UserId = :UserInfo.getUserId()];

            if (userContactAccess.HasReadAccess) {
                return new PageReference('/' + leadConversionResult.getContactId());
            } else {
                return new PageReference(
                    '/' + UTIL_Describe.getObjectDescribe(Lead.SObjectType).getKeyPrefix());
            }

        } catch (Exception e) {
            Database.rollback(sp);
            ERR_Handler.processError(e, ERR_Handler_API.Context.LD);
            ApexPages.addMessage(
                    new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            return null;
        }
    }

    private void updateOpportunityWithConversionResult(Database.LeadConvertResult leadConversionResult, Id affiliationId) {
        Opportunity convertedOpp = new Opportunity(Id = leadConversionResult.getOpportunityId());

        // Set the (a/o 3.45) Opportunity Primary Contact to the converted contact
        convertedOpp.Primary_Contact__c = leadConversionResult.getContactId();

        // set the Opportunity Account to the Primary Affiliation based on strOppAccChoice
        if (strOppAccChoice == 'AFF_ACC') {
            convertedOpp.AccountId = affiliationId;
        }
        String oppName = convertedOpp.Name;

        DMLWithoutSharing convertedOpportunityDmlWithoutSharing = new DMLWithoutSharing(convertedOpp);
        convertedOpportunityDmlWithoutSharing.updateRecord();

        // refresh opportunity names after update. if no opportunity names are defined,
        // keeps original name
        OPP_OpportunityNaming.refreshOppNames(new List<Opportunity>{
                convertedOpp
        });
        // update Opportunity again if refreshed name is different
        if (convertedOpp.Name != oppName) {
            convertedOpportunityDmlWithoutSharing.updateRecord();
        }
    }

    private void deleteDuplicateOpportunityContactRoles(Database.LeadConvert instanceOfLeadConvert, Database.LeadConvertResult leadConversionResult) {
        if (!instanceOfLeadConvert.isDoNotCreateOpportunity() && !CAO_Constants.isBucketModel()) {
            //get the new OCRs
            List<OpportunityContactRole> newOpportunityContactRoles = [
                    SELECT Id, IsPrimary, Role
                    FROM OpportunityContactRole
                    WHERE IsPrimary = TRUE
                    AND OpportunityId = :leadConversionResult.getOpportunityId()
                    AND ContactId = :leadConversionResult.getContactId()
            ];

            //if there are more than one delete the extraneous ones
            if (newOpportunityContactRoles != null && newOpportunityContactRoles.size() > 1) {
                deleteDuplicateOpportunityContactRoles(newOpportunityContactRoles);

                //on delete of one ocr, the other 'isPrimary' is set to false
                //so we need to issue an udpate to correct it.
                //also make sure it has the correct role
                updatePrimaryOpportunityContactRole(newOpportunityContactRoles);
            }
        }
    }

    private Id createAffiliation(Address__c tempAddr, Database.LeadConvertResult leadConversionResult) {
        Id affiliationId = null;
        if (isNewPrimaryAffiliation()) {
            Account acc = new Account(
                    Name = leadToConvert.Company
            );
            //copy address from temporary address__c record, handles state and country
            // picklists if enabled
            NPSP_Address npspAddress = new NPSP_Address(tempAddr);
            NPSP_HouseholdAccount npspHousehold = new NPSP_HouseholdAccount(acc);
            npspHousehold.setBillingAddress(npspAddress);
            new DMLWithoutSharing(npspHousehold.getRecord()).insertRecord();
            affiliationId = acc.Id;
        } else if (String.isNotBlank(primaryAffiliationId)) {
            affiliationId = primaryAffiliationId;
        }
        if (affiliationId != null) {
            // Re-Enable the Affilations Trigger for the Contact
            TDTM_ProcessControl.toggleTriggerState(
                    'Contact', 'AFFL_Affiliations_TDTM', true);
            new AffiliationNonDupeWithoutSharing(leadToConvert, leadConversionResult.getContactId(),
                    affiliationId, true).createNonDupeAffiliation();
        }
        return affiliationId;
    }

    private Boolean isNewPrimaryAffiliation() {
        return primaryAffiliationId == 'NEW';
    }

    private Boolean shouldUpdateAccountAddress() {
        return leadAccountId == 'NEW' && !String.isBlank(leadToConvert.CompanyStreet__c);
    }

    private void updateAccountAddress(Database.LeadConvertResult leadConversionResult, Address__c tempAddr) {
        Account acc = new Account(
                Id = leadConversionResult.getAccountId()
        );
        //copy address from temporary address__c record, handles state and country
        // picklists if enabled
        NPSP_Address npspAddress = new NPSP_Address(tempAddr);
        NPSP_HouseholdAccount npspHousehold = new NPSP_HouseholdAccount(acc);
        npspHousehold.setBillingAddress(npspAddress);
        new DMLWithoutSharing(npspHousehold.getRecord()).updateRecord();
    }

    private void setPrimaryAffiliationId(Id accountId) {
        primaryAffiliationId = accountId;
    }

    private Boolean isConvertedAccountNew() {
        return leadAccountId == 'NEW';
    }

    private void updatePrimaryOpportunityContactRole(List<OpportunityContactRole> ocrList) {
        OpportunityContactRole ocr = ocrList[0];
        ocr.IsPrimary = true;
        ocr.Role = ContactsSettings.npe01__Opportunity_Contact_Role_Default_role__c;
        new DMLWithoutSharing(ocr).updateRecord();
    }

    private void deleteDuplicateOpportunityContactRoles(List<OpportunityContactRole> ocrList) {
        List<OpportunityContactRole> dlist = new List<OpportunityContactRole>();
        for (Integer i = 1; i < ocrList.size(); i++) {
            dlist.add(ocrList[i]);
        }
        new DMLWithoutSharing(dlist).deleteRecords();
    }

    private Boolean shouldFixConvertedAccount() {
        return convertedContactId == 'NEW_CONTACT' && (isLegacyHousehold || isNewLeadAccount());
    }

    private void fixConvertedAccount(Database.LeadConvertResult leadConversionResult) {
        Contact con = new ContactQueryWithoutSharing(leadConversionResult.getContactId()).query();
        Account myAccount = new Account(Id = leadConversionResult.getAccountId());
        npo02__Households_Settings__c hs = UTIL_CustomSettingsFacade.getHouseholdsSettings();

        // update the account since it is non-standard
        if (CAO_Constants.isOneToOne()) {
            myAccount.Name = Households.strNameOne2OneAccountForContact(con);
            myAccount.npe01__SYSTEM_AccountType__c = CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE;
        } else if (CAO_Constants.isHHAccountModel()) {
            // if custom household naming is on, we need to leave the account name untouched,
            // so on update, it will get its correct name.
            if (!hs.npo02__Advanced_Household_Naming__c) {
                myAccount.Name = Households.strNameHHAccountForContact(con);
            } else {
                myAccount.Name = System.Label.npo02.NameReplacementText;
            }
            myAccount.npe01__SYSTEM_AccountType__c = CAO_Constants.HH_ACCOUNT_TYPE;
        }

        if (!CAO_Constants.isBucketModel()) {
            // change its recordtype if specified in settings
            Id rtIdAcccount =
                    ContactAndOrgSettings.rtIdForAccountModel(CAO_Constants.isHHAccountModel());
            if (rtIdAcccount != null) {
                myAccount.put('RecordTypeID', rtIdAcccount);
            }
            myAccount.npe01__SYSTEMIsIndividual__c = true;
            myAccount.npe01__One2OneContact__c = con.Id;
            new DMLWithoutSharing(myAccount).updateRecord();
        }

        // see if we need to create a household object for this contact (1:1 & bucket only)
        if (!CAO_Constants.isHHAccountModel() && con.npo02__Household__c == null) {
            if (hs.npo02__Household_Rules__c == HH_Households.ALL_PROCESSOR ||
                    hs.npo02__Household_Rules__c == HH_Households.ALL_INDIVIDUALS_PROCESSOR) {
                LegacyHouseholdMembers legacyHouseholdContacts =
                        new LegacyHouseholdMembers(new List<Contact>{
                                con
                        });
                legacyHouseholdContacts.onAfterInsert();
                new DMLWithoutSharing(con).updateRecord();
            }
        }

        // now create the address object if appropriate
        if (CAO_Constants.isHHAccountModel() && !isHouseholdAddressesDisabled()) {
            Address__c addr = new Address__c();
            NPSP_Address npspAddress = new NPSP_Address(addr);
            npspAddress.getRecord().Household_Account__c = myAccount.Id;
            npspAddress.getRecord().Default_Address__c = true;
            npspAddress.getRecord().Latest_Start_Date__c = System.today();
            npspAddress.getRecord().Latest_End_Date__c = null;
            npspAddress.copyFromSObject(con, 'Mailing', null);
            new DMLWithoutSharing(npspAddress.getRecord()).insertRecord();
        }
    }

    private void restoreAddressManagement(Boolean isHouseholdAddressesDisabled, Boolean isOrganizationAccountsEnabled) {
        UTIL_CustomSettingsFacade.getContactsSettings()
                .Household_Account_Addresses_Disabled__c = isHouseholdAddressesDisabled;
        UTIL_CustomSettingsFacade.getContactsSettings()
                .Organizational_Account_Addresses_Enabled__c = isOrganizationAccountsEnabled;
    }

    private Boolean isOrganizationAddressesEnabled() {
        Boolean isOrganizationAddressesDisabled =
                UTIL_CustomSettingsFacade.getContactsSettings()
                        .Organizational_Account_Addresses_Enabled__c;
        return isOrganizationAddressesDisabled;
    }

    private Boolean isHouseholdAddressesDisabled() {
        Boolean isHouseholdAddressesDisabled =
                UTIL_CustomSettingsFacade.getContactsSettings()
                        .Household_Account_Addresses_Disabled__c;
        return isHouseholdAddressesDisabled;
    }

    private void disableAffiliationTrigger() {
        TDTM_ProcessControl.toggleTriggerState(
                'Contact', 'AFFL_Affiliations_TDTM', false);
    }

    private void disableAddressManagement() {
        UTIL_CustomSettingsFacade.getContactsSettings()
                .Household_Account_Addresses_Disabled__c = true;
        UTIL_CustomSettingsFacade.getContactsSettings()
                .Organizational_Account_Addresses_Enabled__c = false;
    }

    private Boolean isNewLeadAccount() {
        return leadAccountId == 'AUTO';
    }

    private Database.LeadConvert prepareLeadConversion() {
        Database.LeadConvert instanceOfLeadConvert = new Database.LeadConvert();
        instanceOfLeadConvert.setLeadId(leadToConvert.Id);
        if (!doNotCreateOpp && Schema.SObjectType.Opportunity.isCreateable()) {
            instanceOfLeadConvert.setOpportunityName(oppName);
        }
        instanceOfLeadConvert.setDoNotCreateOpportunity(
                !Schema.SObjectType.Opportunity.isCreateable()
                        || doNotCreateOpp);
        instanceOfLeadConvert.setConvertedStatus(leadToConvert.Status);
        instanceOfLeadConvert.setOwnerId(dummyCon.OwnerId);
        instanceOfLeadConvert.setSendNotificationEmail(sendEmailToOwner);


        // is this a merge to existing?
        if (convertedContactId != 'NEW_CONTACT') {
            // get this contact's account
            instanceOfLeadConvert.setContactId(convertedContactId);
            instanceOfLeadConvert.setAccountId(conMap.get(convertedContactId).AccountId);
        } else if (leadAccountId != 'NEW' && leadAccountId != 'AUTO'
                && leadAccountId != null && leadAccountId != '') {
            instanceOfLeadConvert.setAccountId(leadAccountId);
        } else if (CAO_Constants.isBucketModel() && (isLegacyHousehold || isNewLeadAccount())) {
            instanceOfLeadConvert.setAccountId(CAO_Constants.getIndividualAccountId());
        }
        return instanceOfLeadConvert;
    }

    private PageReference displayNoContactSelectedError() {
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,
                System.Label.leadConvertContactSelection));
        return null;
    }

    private Boolean isContactSelected() {
        return convertedContactId != null;
    }

    @TestVisible
    private without sharing class AffiliationNonDupeWithoutSharing {
        Lead leadToConvert;
        Id contactId;
        Id affiliationId;
        Boolean isPrimary;

        private AffiliationNonDupeWithoutSharing(Lead leadToConvert, Id contactId, Id affiliationId, Boolean
                isPrimary) {
            this.leadToConvert = leadToConvert;
            this.contactId = contactId;
            this.affiliationId = affiliationId;
            this.isPrimary = isPrimary;
        }

        private void createNonDupeAffiliation() {
            AFFL_Affiliations_TDTM.createNonDupeAffiliation(leadToConvert, contactId, affiliationId, isPrimary);
        }
    }

    @TestVisible
    private without sharing class DMLWithoutSharing {
        SObject record;
        List<SObject> records;

        @TestVisible
        private DMLWithoutSharing(SObject record) {
            this.record = record;
        }

        @TestVisible
        private DMLWithoutSharing(List<SObject> records) {
            this.records = records;
        }

        private Database.SaveResult insertRecord() {
            return UTIL_DMLService.insertRecord(record);
        }

        private Database.SaveResult updateRecord() {
            return UTIL_DMLService.updateRecord(record);
        }

        private void deleteRecords() {
            delete records;
        }
    }

    @TestVisible
    private without sharing class ContactQueryWithoutSharing {

        @TestVisible
        private OrgConfig orgConfig {
            get {
                if (orgConfig == null) {
                    orgConfig = new OrgConfig();
                }
                return orgConfig;
            }
            set;
        }

        private List<String> selectFields = new List<String> {
            String.valueOf(Contact.FirstName),
            String.valueOf(Contact.LastName),
            String.valueOf(Contact.AccountId),
            String.valueOf(Contact.npo02__Household__c),
            String.valueOf(Contact.MailingStreet),
            String.valueOf(Contact.MailingCity),
            String.valueOf(Contact.MailingState),
            String.valueOf(Contact.MailingPostalCode),
            String.valueOf(Contact.MailingCountry),
            String.valueOf(Contact.MailingLatitude),
            String.valueOf(Contact.MailingLongitude),
            String.valueOf(Contact.HomePhone),
            String.valueOf(Contact.Email)
        };
        private String queryString;

        @TestVisible
        private ContactQueryWithoutSharing(Id contactId) {
            if (Schema.SObjectType.Contact.fields.getMap().get('RecordTypeId') != null) {
                selectFields.add('RecordTypeId');
            }
            if (orgConfig.isStateCountryPicklistsEnabled()) {
                selectFields.addAll(new List<String> {
                    'MailingStateCode',
                    'MailingCountryCode'
                });
            }
            UTIL_Query query = new UTIL_Query()
                .withSelectFields(selectFields)
                .withFrom(Contact.SObjectType)
                .withWhere('Id = \'' + contactId + '\'');

            queryString = query.build();
        }

        @TestVisible
        private Contact query() {
            return Database.query(queryString);
        }
    }

    private Boolean getCurrentUserHasAccess() {
        Boolean accessResult = true;

        SObjectType ld = Lead.getSObjectType();
        Set<SObjectField> sObjectLeadFieldsRead = new Set<SObjectField>{
            Lead.fields.Name,
            Lead.fields.FirstName,
            Lead.fields.LastName,
            Lead.fields.Company,
            Lead.fields.Email,
            Lead.fields.Title,
            Lead.fields.OwnerId,
            Lead.fields.Status,
            Lead.fields.CompanyStreet__c,
            Lead.fields.CompanyCity__c,
            Lead.fields.CompanyState__c,
            Lead.fields.CompanyPostalCode__c,
            Lead.fields.CompanyCountry__c
        };

        if (!perms.canRead(ld, sObjectLeadFieldsRead)) {
            accessResult = false;
        }

        return accessResult;
    }
}