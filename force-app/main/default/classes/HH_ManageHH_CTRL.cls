/*
    Copyright (c) 2016, Salesforce.org
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
* @author Salesforce.org
* @date 2016
* @group Households
* @group-content ../../ApexDocContent/Households.htm
* @description Visualforce page Controller for the Manage Household UI page
*/
public with sharing class HH_ManageHH_CTRL {

    /** @description The Id of the Household Object or Account */
    public ID hhId { get; set; }

    /** @description The Id of the Contact to use when invoked for a new Household Object */
    private ID contactId { get; set; }

    /** @description The Household Object or Account */
    public SObject hh { get; set; }
    
    /** @description The household cast to an Account for account override checking */
    public Account hhA {
        get {
            return (Account)hh;
        } private set;
    }

    /** @description what is the namespace (null if unmanaged, or npsp if managed) */
    public string namespacePrefix { get; set; }
    
    /*******************************************************************************************************
    * @description to easily tell our Account override page whether to defer to the normal Account edit page
    * when the user is trying to change their recordtype!
    */
    public boolean isChangingRecordType {
        get {
            if (ApexPages.currentPage() != null) {
                map<string, string> mapParams = ApexPages.currentPage().getParameters();
                if (mapParams != null) {
                    string paramRtId = mapParams.get('RecordType');
                    if (paramRtId != null && paramRtId != ContactAndOrgSettings.rtIdForAccountModel(true)) {
                        return true;
                    }
                }
            }
            return false; 
        } private set;
    }
    
    /*******************************************************************************************************
    * @description Constructor for the page.  Loads up the HH Account or HH Object, using fields from
    * the appropriate field set.
    */
    public HH_ManageHH_CTRL() {
        this(null);
    }
    
    public HH_ManageHH_CTRL(ApexPages.StandardController controller) {
        namespacePrefix = UTIL_Namespace.getNamespace();

        Map<String, String> pageParams = ApexPages.currentPage().getParameters();
        hhId = pageParams.get('Id');
        contactId = pageParams.get('cid');
        
        // handle existing Household.  new HH will be handled in actionMethod handleNewHousehold().
        if (hhId != null) {
	        // load up only the fields exposed in the field set for our visualforce page to use.
	        String strSoql = 'select Id';
	        
	        // for accounts, also include system field our page needs
	        if (isHHAccount)
	            strSoql += ', npe01__SYSTEM_AccountType__c';
	            
	        for (Schema.FieldSetMember fsm : hhFieldSet)
	            strSoql += ', ' + fsm.getFieldPath();
	        strSoql += ' from ' + (isHHAccount ? 'Account' : 'npo02__Household__c');
	        strSoql += ' where Id = :hhId';
	
	        hh = database.query(strSoql);
        }
    }
    
    /*******************************************************************************************************
    * @description ActionMethod called when the page loads, to handle new Household objects (so it can do)
    * DML to save it.
    * @return null
    */
    public PageReference handleNewHousehold() {
        try {
            if (hhId == null) {
                if (!UTIL_Permissions.canCreate('npo02__Household__c')) {
                    throw new UTIL_Permissions.InsufficientPermissionException(System.Label.commonAccessErrorMessage);
                }
                hh = new npo02__Household__c();
                hh.put('Name', Label.npo02.DefaultHouseholdName);    // name will get fixed up when we update the contact
                UTIL_DMLService.insertRecord(hh);
                hhId = hh.Id;

                if (contactId != null) {
                    if (!UTIL_Permissions.canUpdate('Contact','npo02__Household__c', false)) {
                        throw new UTIL_Permissions.InsufficientPermissionException(System.Label.commonAccessErrorMessage);
                    }
                    Contact con = new Contact(Id = contactId, npo02__Household__c = hhId);
                    UTIL_DMLService.updateRecord(con);
                }
            }
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, e.getMessage()));
        }

        return null;
    }
    
    /*******************************************************************************************************
    * @description is the Household a Household Account, vs. a Household Object.
    * @return Boolean
    */
    public boolean isHHAccount {
        get {
            if (isHHAccount == null) {
                isHHAccount = UTIL_Describe.isObjectIdThisType(hhId, 'Account');
            }
            return isHHAccount;
        }
        private set;
    }

    /*******************************************************************************************************
    * @description holds the list of FieldSetMembers from the appropriate field set.
    * @return List<Schema.FieldSetMember>
    */
    public List<Schema.FieldSetMember> hhFieldSet {
        get {
            if (hhFieldSet == null) {
                if (isHHAccount)
                    hhFieldSet = Schema.SObjectType.Account.FieldSets.Manage_Household_Custom.getFields();
                else
                    hhFieldSet = Schema.SObjectType.npo02__Household__c.FieldSets.npo02__Manage_Household_Custom.getFields();
            }
            return hhFieldSet;
        }
        private set;
    }

    /*******************************************************************************************************
    * @description ActionMethod to save the Household
    * @return null
    */
    public PageReference save() {
        try {
            if (!canUpdateHousehold()) {
                throw new UTIL_Permissions.InsufficientPermissionException(System.Label.commonAccessErrorMessage);
            }
            UTIL_DMLService.updateRecord(hh);
        } catch (Exception ex) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, ex.getMessage()));
        }        
        return null; 
    }

    private Boolean canUpdateHousehold() {
        String accountToCheck = isHHAccount ? 'Account' : 'npo02__Household__c';
        Set<String> fieldsToCheck = new Set<String>();
        for (FieldSetMember fsMember : hhFieldSet) {
            fieldsToCheck.add(fsMember.getFieldPath());
        }
        if (isHHAccount) {
            fieldsToCheck.add('npo02__Household__c');
        }
        for (String fieldToCheck : fieldsToCheck) {
            if (!UTIL_Permissions.canUpdate(accountToCheck, fieldToCheck, false)) {
                return false;
            }
        }

        return true;
    }
}