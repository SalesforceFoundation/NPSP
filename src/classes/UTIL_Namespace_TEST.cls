/*
    Copyright (c) 2014 Salesforce.com Foundation
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
* @date 2014 
* @description test Class which holds test methods for common utilities, 
* such as detecting whether we are in a managed package, and some string helpers.
*/
@isTest
public with sharing class UTIL_Namespace_TEST {

    static testmethod void TestNamespacePrefixFixups() {
        if (UTIL_Namespace.InManagedPackage) {
            system.assertEquals('npsp__foo', UTIL_Namespace.StrTokenNSPrefix('foo'));
            system.assertEquals('npsp__foo__c', UTIL_Namespace.StrTokenNSPrefix('foo__c'));     
            system.assertEquals('foo', UTIL_Namespace.StrAllNSPrefix('foo'));
            system.assertEquals('npsp__foo__c', UTIL_Namespace.StrAllNSPrefix('foo__c'));
            system.assertEquals('npsp__foo_bar_baz__c', UTIL_Namespace.StrAllNSPrefix('foo_bar_baz__c'));
            system.assertEquals('select npsp__foo__c, bar, npsp__baz1__c, npsp__biz_buz__c from Contact', UTIL_Namespace.StrAllNSPrefix('select foo__c, bar, baz1__c, biz_buz__c from Contact'));
        } else {
            system.assertEquals('foo', UTIL_Namespace.StrTokenNSPrefix('foo'));
            system.assertEquals('foo__c', UTIL_Namespace.StrTokenNSPrefix('foo__c'));     
            system.assertEquals('foo', UTIL_Namespace.StrAllNSPrefix('foo'));
            system.assertEquals('foo__c', UTIL_Namespace.StrAllNSPrefix('foo__c'));
            system.assertEquals('foo_bar_baz__c', UTIL_Namespace.StrAllNSPrefix('foo_bar_baz__c'));
            system.assertEquals('select foo__c, bar, baz1__c, biz_buz__c from Contact', UTIL_Namespace.StrAllNSPrefix('select foo__c, bar, baz1__c, biz_buz__c from Contact'));           
        }       
    }               

    static testmethod void testSandboxEmailToRealEmail() {
        String fixedEmail = UTIL_Namespace.sandboxEmailToRealEmail('awheeler=universalcontainers.com@example.com');	
        System.assertEquals('awheeler@universalcontainers.com', fixedEmail);
    }
    
    //we have some packaged labels that we no longer reference.
    //unfortunately, this causes our local DE Orgs to not include them in our local package.
    //but these labels were already released in the managed package and cannot be deleted.
    //so we now refer to them here, just so our DE Orgs will keep the in our local package.
    static testmethod void keepUnusedPackagedLabelsInPackage() {
        string str;
        str = Label.Addr_Settings_API_Body;
        str = Label.Addr_Settings_Intro_Body;
        str = Label.Addr_Settings_Intro_Title;
        str = Label.Addr_Settings_Notice;
        str = Label.Addr_Settings_Test_Body;
        str = Label.Addr_Settings_Test_Response_Title;
        str = Label.Addr_Settings_Test_Title;
        str = Label.Addr_Verification_Batch_Status;
        str = Label.stgHHNameRefreshTitle;
        str = Label.stgLabelAfflSettings;
        str = Label.stgLabelBDESettings;
        str = Label.stgLabelBatchStatus;
        str = Label.stgLabelCurrentUDR;
        str = Label.stgLabelErrorNotify;
        str = Label.stgLabelMembershipSettings;
        str = Label.stgLabelPaymentSettings;
        str = Label.stgLabelRDFieldMap;
        str = Label.stgLabelRDPeriod;
        str = Label.stgLabelRDSettings;
        str = Label.stgLabelRelSettings;
        str = Label.stgLabelTriggerHandlers;
        str = Label.stgNavContacts;
        str = Label.stgLabelHHNamingProgress;
        str = Label.Address_StateCountry_Invalid_Error;
    }
}