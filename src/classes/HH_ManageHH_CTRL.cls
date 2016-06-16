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

    /** @description The Household Object or Account */
    public SObject hh { get; set; }

    /** @description what is the namespace (null if unmanaged, or npsp__ if managed) */
    public string namespacePrefix { get; set; }
    
    /*******************************************************************************************************
    * @description Constructor for the page.  Loads up the HH Account or HH Object, using fields from
    * the appropriate field set.
    */
    public HH_ManageHH_CTRL() {
        namespacePrefix = UTIL_Namespace.getNamespace();
        if (namespacePrefix != null && namespacePrefix != '')
            namespacePrefix += '__';

        Map<String, String> pageParams = ApexPages.currentPage().getParameters();
        hhId = pageParams.get('Id');
        
        // load up only the fields exposed in the field set for our visualforce page to use.
        String strSoql = 'select Id';
        for (Schema.FieldSetMember fsm : hhFieldSet)
            strSoql += ', ' + fsm.getFieldPath();
        strSoql += ' from ' + (isHHAccount ? 'Account' : 'npo02__Household__c');
        strSoql += ' where Id = :hhId';

        hh = database.query(strSoql);
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
    * @description ActionMethod to save the Household and close the page.
    * @return PageReference the original calling page's URL.
    */
    public PageReference save() {
        update hh;
        return new PageReference('/' + hhId);
    }
}