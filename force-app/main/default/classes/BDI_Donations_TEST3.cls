/*
    Copyright (c) 2022 Salesforce.org
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
    'AS IS' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
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
* @date 2022
* @group Batch Data Import
* @group-content ../../ApexDocContent/BatchDataImport.htm
* @description tests specific to the Batch Data Importer Donations batch processing and record creation
*/

@isTest
public with sharing class BDI_Donations_TEST3 {

    /*********************************************************************************************************
    * @description operation: 
    *    import donations using different matching rules: Amount, Date.  avoid same amount, different day.
    * verify: 
    *    correct donations matched
    **********************************************************************************************************/            
    static testMethod void donationMatchRules1() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) return;

        insert new DataImport__c(Contact1_Firstname__c='c0', Contact1_Lastname__c='c0', Contact1_Personal_Email__c='c0@c0.com',
            Donation_Amount__c=100,
            Donation_Date__c=System.Today(),
            Payment_Method__c = 'Check',
            Donation_Donor__c='contact1');
            
        donationMatchRules(
            UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c') + ';' +
            UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c'),
            0, BDI_DataImport_API.ExactMatchOrCreate, label.bdiMatched, label.bdiMatched, false, 0);
    }

    /*********************************************************************************************************
    * @description operation:
    *    import donations using different matching rules: Amount, Date.  avoid same amount, different day.
    *    use date range for the match.
    * verify:
    *    correct donations matched
    **********************************************************************************************************/
    static testMethod void donationMatchRules1b() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) return;

        insert new DataImport__c(Contact1_Firstname__c='c0', Contact1_Lastname__c='c0', Contact1_Personal_Email__c='c0@c0.com',
            Donation_Amount__c=100,
            Donation_Date__c=System.Today()+1,
            Payment_Method__c = 'Check',
            Donation_Donor__c='contact1');

        donationMatchRules(
            UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c') + ';' +
                UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c'),
            0, BDI_DataImport_API.ExactMatchOrCreate, label.bdiMatched, label.bdiMatched, false, 1);
    }

    /*********************************************************************************************************
    * @description operation:
    *    import donations using different matching rules: Amount, Date.  avoid same amount, different day.
    *    use date range for the match.
    * verify:
    *    error, due to multiple matches
    **********************************************************************************************************/
    static testMethod void donationMatchRules1c() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) return;

        insert new DataImport__c(Contact1_Firstname__c='c0', Contact1_Lastname__c='c0', Contact1_Personal_Email__c='c0@c0.com',
            Donation_Amount__c=100,
            Donation_Date__c=System.Today(),
            Payment_Method__c = 'Check',
            Donation_Donor__c='contact1');

        donationMatchRules(
            UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c') + ';' +
                UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c'),
            -1, BDI_DataImport_API.RequireExactMatch, label.bdiErrorPaymentMultiMatch, label.bdiErrorPaymentMultiMatch, true, 1);
    }

    /*********************************************************************************************************
    * @description operation:
    *    import donations using different matching rules: Amount, Date.  avoid same amount, different day.
    *    use date range for the match.
    * verify:
    *    correct donations matched
    **********************************************************************************************************/
    static testMethod void donationMatchRules1d() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) return;

        insert new DataImport__c(Contact1_Firstname__c='c0', Contact1_Lastname__c='c0', Contact1_Personal_Email__c='c0@c0.com',
            Donation_Amount__c=100,
            Donation_Date__c=System.Today(),
            Payment_Method__c = 'Check',
            Donation_Donor__c='contact1');

        donationMatchRules(
            UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c') + ';' +
                UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c'),
            0, BDI_DataImport_API.RequireBestMatch, label.bdiMatchedBest, label.bdiMatchedBest, true, 1);
    }

    /*********************************************************************************************************
    * @description operation: 
    *    import donations using different matching rules: Amount, Date.  avoid different amount, same day.  
    * verify: 
    *    correct donations matched
    **********************************************************************************************************/            
    static testMethod void donationMatchRules2() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) return;

        insert new DataImport__c(Contact1_Firstname__c='c0', Contact1_Lastname__c='c0', Contact1_Personal_Email__c='c0@c0.com',
            Donation_Amount__c=300,
            Donation_Date__c=System.Today(),
            Payment_Method__c = 'Check',
            Donation_Donor__c='contact1');
            
        donationMatchRules(
            UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c') + ';' +
            UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c'),
            4, BDI_DataImport_API.ExactMatchOrCreate, label.bdiMatched, label.bdiMatched, false, 0);
    }

    /*********************************************************************************************************
    * @description operation: 
    *    import donations using different matching rules: Amount, Date, RecordType 
    * verify: 
    *    correct donations matched
    **********************************************************************************************************/            
    static testMethod void donationMatchRules3() {
        
        string strRTName = UTIL_RecordTypes.getRecordTypeNameForMembershipTests(Opportunity.sObjectType);

        // if membership is the default recordtype, we can't assume we'll match the intended opp, so we can't test.
        if (UTIL_RecordTypes.isRecordTypeDefault(Opportunity.sObjectType, strRTName))
            return;
        
        insert new DataImport__c(Contact1_Firstname__c='c0', Contact1_Lastname__c='c0', Contact1_Personal_Email__c='c0@c0.com',
            Donation_Amount__c=200,
            Donation_Date__c=System.Today(),
            Donation_Record_Type_Name__c=strRTName,
            Payment_Method__c = 'Check',
            Donation_Donor__c='contact1');
            
        donationMatchRules(
            UTIL_Namespace.StrTokenNSPrefix('Donation_Record_Type_Name__c') + ';' +
            UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c') + ';' +
            UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c'),
            3, BDI_DataImport_API.ExactMatchOrCreate, label.bdiMatched, label.bdiMatched, false, 0);
    }

    /*********************************************************************************************************
    * @description operation: 
    *    import donations using different matching rules: Amount, Date.  Ambiguous match detected.
    * verify: 
    *    no donations matched
    *    ambiguous match error logged
    **********************************************************************************************************/            
    static testMethod void donationMatchRules4() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) return;

        insert new DataImport__c(Contact1_Firstname__c='c0', Contact1_Lastname__c='c0', Contact1_Personal_Email__c='c0@c0.com',
            Donation_Amount__c=200,
            Donation_Date__c=System.Today(),
            Payment_Method__c = 'Check',
            Donation_Donor__c='contact1');
            
        donationMatchRules(
            UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c') + ';' +
            UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c'),
            -1, BDI_DataImport_API.ExactMatchOrCreate, label.bdiErrorDonationMultiMatch, label.bdiErrorDonationMultiMatch, true, 0);
    }

    /*********************************************************************************************************
    * @description operation: 
    *    import donations using different matching rules: Amount, Date.  ExactMatchOrCreate, no match found
    * verify: 
    *    no donations matched
    *    new donation created
    **********************************************************************************************************/            
    static testMethod void donationMatchRules4b() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) return;

        insert new DataImport__c(Contact1_Firstname__c='c0', Contact1_Lastname__c='c0', Contact1_Personal_Email__c='c0@c0.com',
            Donation_Amount__c=99,
            Donation_Date__c=System.Today(),
            Payment_Method__c = 'Check',
            Donation_Donor__c='contact1');
            
        donationMatchRules(
            UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c') + ';' +
            UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c'),
            -1, BDI_DataImport_API.ExactMatchOrCreate, label.bdiCreated, label.bdiCreated, false, 0);
    }

    /*********************************************************************************************************
    * @description operation: 
    *    import donations using different matching rules: Amount, Date.  BestMatchOrCreate. matches exist
    * verify: 
    *    best donation matched
    **********************************************************************************************************/            
    static testMethod void donationMatchRules5() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) return;

        insert new DataImport__c(Contact1_Firstname__c='c0', Contact1_Lastname__c='c0', Contact1_Personal_Email__c='c0@c0.com',
            Donation_Amount__c=200,
            Donation_Date__c=System.Today(),
            Payment_Method__c = 'Check',
            Donation_Donor__c='contact1');
            
        donationMatchRules(
            UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c') + ';' +
            UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c'),
            -2, BDI_DataImport_API.BestMatchOrCreate, label.bdiMatchedBest, label.bdiMatchedBest, true, 0);
    }

    /*********************************************************************************************************
    * @description operation: 
    *    import donations using different matching rules: Amount, Date.  BestMatchOrCreate, no match
    * verify: 
    *    no donation matched
    *    new donation created
    **********************************************************************************************************/            
    static testMethod void donationMatchRules5b() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) return;

        insert new DataImport__c(Contact1_Firstname__c='c0', Contact1_Lastname__c='c0', Contact1_Personal_Email__c='c0@c0.com',
            Donation_Amount__c=99,
            Donation_Date__c=System.Today(),
            Payment_Method__c = 'Check',
            Donation_Donor__c='contact1');
            
        donationMatchRules(
            UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c') + ';' +
            UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c'),
            -1, BDI_DataImport_API.BestMatchOrCreate, label.bdiCreated, label.bdiCreated, false, 0);
    }

    /*********************************************************************************************************
    * @description operation: 
    *    import donations using different matching rules: Amount, Date.  Specify No Match
    * verify: 
    *    new donation created (even though matches existing Opp)
    **********************************************************************************************************/            
    static testMethod void donationMatchRules6() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) return;

        insert new DataImport__c(Contact1_Firstname__c='c0', Contact1_Lastname__c='c0', Contact1_Personal_Email__c='c0@c0.com',
            Donation_Amount__c=100,
            Donation_Date__c=System.Today(),
            Payment_Method__c = 'Check',
            Donation_Donor__c='contact1');
            
        donationMatchRules(
            UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c') + ';' +
            UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c'),
            -1, BDI_DataImport_API.DoNotMatch, label.bdiCreated, label.bdiCreated, false, 0);
    }

    /*********************************************************************************************************
    * @description operation: 
    *    import donations using different matching rules: Amount, Date.  Specify RequireNoMatch, but match exists
    * verify: 
    *    no donation created
    *    error reported on bdi
    **********************************************************************************************************/            
    static testMethod void donationMatchRules7() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) return;

        insert new DataImport__c(Contact1_Firstname__c='c0', Contact1_Lastname__c='c0', Contact1_Personal_Email__c='c0@c0.com',
            Donation_Amount__c=200,
            Donation_Date__c=System.Today(),
            Payment_Method__c = 'Check',
            Donation_Donor__c='contact1');
            
        donationMatchRules(
            UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c') + ';' +
            UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c'),
            -1, BDI_DataImport_API.RequireNoMatch, label.bdiErrorDonationRequireNoMatch, label.bdiErrorDonationRequireNoMatch, true, 0);
    }

    /*********************************************************************************************************
    * @description operation: 
    *    import donations using different matching rules: Amount, Date.  Specify RequireNoMatch, no match exists
    * verify: 
    *    new donation created
    **********************************************************************************************************/            
    static testMethod void donationMatchRules7b() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) return;

        insert new DataImport__c(Contact1_Firstname__c='c0', Contact1_Lastname__c='c0', Contact1_Personal_Email__c='c0@c0.com',
            Donation_Amount__c=99,
            Donation_Date__c=System.Today(),
            Payment_Method__c = 'Check',
            Donation_Donor__c='contact1');
            
        donationMatchRules(
            UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c') + ';' +
            UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c'),
            -1, BDI_DataImport_API.RequireNoMatch, label.bdiCreated, label.bdiCreated, false, 0);
    }

    /*********************************************************************************************************
    * @description operation: 
    *    import donations using different matching rules: Amount, Date.  Specify RequireExactMatch, but none exists
    * verify: 
    *    no new donation created
    *    error reported on bdi
    **********************************************************************************************************/            
    static testMethod void donationMatchRules8() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) return;

        insert new DataImport__c(Contact1_Firstname__c='c0', Contact1_Lastname__c='c0', Contact1_Personal_Email__c='c0@c0.com',
            Donation_Amount__c=99,
            Donation_Date__c=System.Today(),
            Payment_Method__c = 'Check',
            Donation_Donor__c='contact1');
            
        donationMatchRules(
            UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c') + ';' +
            UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c'),
            -1, BDI_DataImport_API.RequireExactMatch, label.bdiErrorDonationNoMatch, label.bdiErrorDonationNoMatch, false, 0);
    }

    /*********************************************************************************************************
    * @description operation: 
    *    import donations using different matching rules: Amount, Date.  Specify RequireExactMatch, but multi exists
    * verify: 
    *    no new donation created
    *    error reported on bdi
    **********************************************************************************************************/            
    static testMethod void donationMatchRules9() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) return;

        insert new DataImport__c(Contact1_Firstname__c='c0', Contact1_Lastname__c='c0', Contact1_Personal_Email__c='c0@c0.com',
            Donation_Amount__c=200,
            Donation_Date__c=System.Today(),
            Payment_Method__c = 'Check',
            Donation_Donor__c='contact1');
            
        donationMatchRules(
            UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c') + ';' +
            UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c'),
            -1, BDI_DataImport_API.RequireExactMatch, label.bdiErrorPaymentMultiMatch, label.bdiErrorPaymentMultiMatch, true, 0);
    }

    /*********************************************************************************************************
    * @description operation: 
    *    import donations using different matching rules: Amount, Date.  Specify RequireExactMatch, exact exists
    * verify: 
    *    no new donation created
    *    record matched
    **********************************************************************************************************/            
    static testMethod void donationMatchRules9b() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) return;

        insert new DataImport__c(Contact1_Firstname__c='c0', Contact1_Lastname__c='c0', Contact1_Personal_Email__c='c0@c0.com',
            Donation_Amount__c=100,
            Donation_Date__c=System.Today(),
            Payment_Method__c = 'Check',
            Donation_Donor__c='contact1');
            
        donationMatchRules(
            UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c') + ';' +
            UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c'),
            -1, BDI_DataImport_API.RequireExactMatch, label.bdiMatched, label.bdiMatched, false, 0);
    }

    /*********************************************************************************************************
    * @description operation: 
    *    import donations using different matching rules: Amount, Date.  Specify RequireBestMatch, multi exists
    * verify: 
    *    no new donation created
    *    best opp matched
    **********************************************************************************************************/            
    static testMethod void donationMatchRules10() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) return;

        insert new DataImport__c(Contact1_Firstname__c='c0', Contact1_Lastname__c='c0', Contact1_Personal_Email__c='c0@c0.com',
            Donation_Amount__c=200,
            Donation_Date__c=System.Today(),
            Payment_Method__c = 'Check',
            Donation_Donor__c='contact1');
            
        donationMatchRules(
            UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c') + ';' +
            UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c'),
            2, BDI_DataImport_API.RequireBestMatch, label.bdiMatchedBest, label.bdiMatchedBest, true, 0);
    }

    /*********************************************************************************************************
    * @description operation: 
    *    import donations using different matching rules: Amount, Date.  Specify RequireBestMatch, no match exists
    * verify: 
    *    no new donation created
    *    error reported on bdi
    **********************************************************************************************************/            
    static testMethod void donationMatchRules10b() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) return;

        insert new DataImport__c(Contact1_Firstname__c='c0', Contact1_Lastname__c='c0', Contact1_Personal_Email__c='c0@c0.com',
            Donation_Amount__c=99,
            Donation_Date__c=System.Today(),
            Payment_Method__c = 'Check',
            Donation_Donor__c='contact1');
            
        donationMatchRules(
            UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c') + ';' +
            UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c'),
            -1, BDI_DataImport_API.RequireBestMatch, label.bdiErrorDonationNoMatch, label.bdiErrorDonationNoMatch, false, 0);
    }

    /*********************************************************************************************************
    * @description operation: 
    *    import donations using different matching rules: Opportunity Unique Id (string), opp exists
    * verify: 
    *    no new donation created
    *    existing opp matched
    **********************************************************************************************************/            
    static testMethod void donationMatchRules11() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) return;

        insert new DataImport__c(Contact1_Firstname__c='c0', Contact1_Lastname__c='c0', Contact1_Personal_Email__c='c0@c0.com',
            Donation_Amount__c=99,
            Donation_Date__c=System.Today(),
            Donation_Donor__c='contact1',
            Payment_Method__c = 'Check',
            Donation_Type__c='MyUniqueID');
            
        donationMatchRules(
            UTIL_Namespace.StrTokenNSPrefix('Donation_Type__c'),
            2, BDI_DataImport_API.RequireExactMatch, label.bdiMatched, label.bdiMatched, false, 0);
    }

    /*********************************************************************************************************
    * @description operation: 
    *    import donations using different matching rules: Opportunity Unique Id (number), opp exists
    * verify: 
    *    no new donation created
    *    existing opp matched
    **********************************************************************************************************/            
    static testMethod void donationMatchRules11b() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) return;

        insert new DataImport__c(Contact1_Firstname__c='c0', Contact1_Lastname__c='c0', Contact1_Personal_Email__c='c0@c0.com',
            Donation_Amount__c=300,
            Donation_Date__c=System.Today().addDays(-100),
            Payment_Method__c = 'Check',
            Donation_Donor__c='contact1');
            
        donationMatchRules(
            UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c'),
            4, BDI_DataImport_API.RequireExactMatch, label.bdiMatched, label.bdiMatched, false, 0);
    }

    /*********************************************************************************************************
    * @description operation: 
    *    import donations using different matching rules: Amount, Date, where Opp has NO Payments.
    * verify: 
    *    no new donation created
    *    existing opp matched
    **********************************************************************************************************/            
    static testMethod void donationMatchRules12() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) return;

        insert new DataImport__c(Contact1_Firstname__c='c0', Contact1_Lastname__c='c0', Contact1_Personal_Email__c='c0@c0.com',
            Donation_Amount__c=700,
            Donation_Date__c=System.Today(),
            Payment_Method__c = 'Check',
            Donation_Donor__c='contact1');
            
        donationMatchRules(
            UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c') + ';' +
            UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c'),
            7, BDI_DataImport_API.RequireExactMatch, label.bdiMatched, label.bdiMatched, false, 0);
    }

    /*********************************************************************************************************
    * @description operation: 
    *    import donations using different matching rules: Amount, Date, where Opp has Multiple Payments.
    * verify: 
    *    no new donation created
    *    existing opp matched
    **********************************************************************************************************/            
    static testMethod void donationMatchRules13() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) return;

        insert new DataImport__c(Contact1_Firstname__c='c0', Contact1_Lastname__c='c0', Contact1_Personal_Email__c='c0@c0.com',
            Donation_Amount__c=550,
            Donation_Date__c=System.Today(),
            Payment_Method__c = 'Check',
            Donation_Donor__c='contact1');
            
        donationMatchRules(
            UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c') + ';' +
            UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c'),
            9, BDI_DataImport_API.RequireExactMatch, label.bdiMatched, label.bdiMatched, false, 0);
    }

    /*********************************************************************************************************
    * @description operation: 
    *    import donations using different matching rules: check#, where Opp has Multiple Payments.
    * verify: 
    *    no new donation created
    *    existing opp matched
    **********************************************************************************************************/            
    static testMethod void donationMatchRules14() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) return;

        insert new DataImport__c(Contact1_Firstname__c='c0', Contact1_Lastname__c='c0', Contact1_Personal_Email__c='c0@c0.com',
            Donation_Amount__c=25,
            Donation_Date__c=System.Today(),
            Donation_Donor__c='contact1',
            Payment_Method__c = 'Check',
            Payment_Check_Reference_Number__c='pick me'
            );
            
        donationMatchRules(
            UTIL_Namespace.StrTokenNSPrefix('Payment_Check_Reference_Number__c') + ';' +
            UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c'),
            9, BDI_DataImport_API.RequireExactMatch, label.bdiMatched, label.bdiMatched, false, 0);
    }

    /*********************************************************************************************************
    * @description operation: 
    *    import donations using different matching rules: check#, amount, date, 
    *    where no payment match found, but opp found.
    * verify: 
    *    no new donation created
    *    no opp matched
    **********************************************************************************************************/            
    static testMethod void donationMatchRules14b() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) return;

        insert new DataImport__c(Contact1_Firstname__c='c0', Contact1_Lastname__c='c0', Contact1_Personal_Email__c='c0@c0.com',
            Donation_Amount__c=300,
            Donation_Date__c=System.Today(),
            Donation_Donor__c='contact1',
            Payment_Method__c = 'Check',
            Payment_Check_Reference_Number__c='pick me'
            );
            
        donationMatchRules(
            UTIL_Namespace.StrTokenNSPrefix('Payment_Check_Reference_Number__c') + ';' +
            UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c') + ';' + 
            UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c'),
            -1, BDI_DataImport_API.RequireExactMatch, label.bdiErrorDonationNoMatch, label.bdiErrorDonationNoMatch, false, 0);
    }

    /*********************************************************************************************************
    * @description operation: 
    *    import donations using different matching rules: Amount, Date, where Opp has Multiple Payments,
    *    and matches one of the payments under the opp
    * verify: 
    *    no new donation created
    *    existing opp matched, but left open
    *    payment matched
    *    opp remaining balance updated
    **********************************************************************************************************/            
    static testMethod void donationMatchRules14c() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) return;

        insert new DataImport__c(Contact1_Firstname__c='c0', Contact1_Lastname__c='c0', Contact1_Personal_Email__c='c0@c0.com',
            Donation_Amount__c=350,
            Donation_Date__c=System.Today(),
            Payment_Method__c = 'Check',
            Donation_Donor__c='contact1');
            
        donationMatchRules(
            UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c') + ';' +
            UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c'),
            8, BDI_DataImport_API.RequireExactMatch, label.bdiMatched, label.bdiMatched, false, 0);
            
        DataImport__c di = [select Status__c, DonationImported__c, DonationImportStatus__c, 
            Donation_Possible_Matches__c, PaymentImported__c, PaymentImportStatus__c from DataImport__c];
        system.assertEquals(label.bdiMatched, di.DonationImportStatus__c);       
        system.assertEquals(label.bdiMatched, di.PaymentImportStatus__c);
        
        Opportunity opp = getOpportunityWithPayments(di.DonationImported__c);
        npe01__OppPayment__c pmt = [select Id, npe01__Payment_Amount__c, npe01__Paid__c from npe01__OppPayment__c where id = :di.PaymentImported__c];
        
        system.assertEquals(false, opp.IsWon);
        system.assertEquals(false, opp.IsClosed);
        system.assertEquals(600, opp.Amount);
        system.assertEquals(250, PMT_PaymentCreator.getAmountOutstanding(opp));
        system.assertEquals(350, pmt.npe01__Payment_Amount__c);
        system.assertEquals(true, pmt.npe01__Paid__c);
    }

    /*********************************************************************************************************
    * @description operation: 
    *    import donations using different matching rules: check#, donation date, where Opp has Multiple Payments, 
    *    multi opps match, RequireExactMatch
    * verify: 
    *    no new donation created
    *    error reported on bdi
    **********************************************************************************************************/            
    static testMethod void donationMatchRules15() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) return;

        insert new DataImport__c(Contact1_Firstname__c='c0', Contact1_Lastname__c='c0', Contact1_Personal_Email__c='c0@c0.com',
            Donation_Amount__c=25,
            Donation_Date__c=System.Today(),
            Donation_Donor__c='contact1',
            Payment_Method__c = 'Check',
            Payment_Check_Reference_Number__c='dupe'
            );
            
        donationMatchRules(
            UTIL_Namespace.StrTokenNSPrefix('Payment_Check_Reference_Number__c') + ';' +
            UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c'),
            -1, BDI_DataImport_API.RequireExactMatch, label.bdiErrorPaymentMultiMatch, label.bdiErrorPaymentMultiMatch, true, 0);
    }

    /*********************************************************************************************************
    * @description operation: 
    *    import donations using different matching rules: Date, Amount, remaining payment matches 
    * verify: 
    *    no new donation created
    *    error reported on bdi
    **********************************************************************************************************/            
    static testMethod void donationMatchRules16() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) return;

        insert new DataImport__c(Contact1_Firstname__c='c0', Contact1_Lastname__c='c0', Contact1_Personal_Email__c='c0@c0.com',
            Donation_Amount__c=125,
            Donation_Date__c=System.Today(),
            Donation_Donor__c='contact1',
            Payment_Method__c = 'Check'
            );
            
        donationMatchRules(
            UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c') + ';' +
            UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c'),
            10, BDI_DataImport_API.RequireExactMatch, label.bdiMatched, label.bdiMatched, false, 0);
    }

    /*********************************************************************************************************
    * @description operation: 
    *    import donations using different matching rules: Date, Amount, matching opps payment was written off
    *    but opp left open. 
    * verify: 
    *    The import should fail as the payment is written off and the matching donations code will try to 
    *    mark it as paid.
    *    no new donation created
    *    error reported on bdi
    **********************************************************************************************************/
    static testMethod void donationMatchRules17() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) return;

        insert new DataImport__c(
                Contact1_Firstname__c = 'c0',
                Contact1_Lastname__c = 'c0',
                Contact1_Personal_Email__c = 'c0@c0.com',
                Donation_Amount__c = 1100,
                Donation_Date__c = System.Today(),
                Donation_Donor__c = 'contact1',
                Payment_Method__c = 'Check',
                Donation_Description__c = 'Opp was updated.'
        );
            
        donationMatchRules(
            UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c') + ';' +
            UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c'),
            11, BDI_DataImport_API.RequireExactMatch, label.bdiMatched, label.bdiMatched, false, 0);
    }

    /*********************************************************************************************************
    * @description operation:
    *    import donations using different matching rules: Amount, Date, where Opp has Multiple Payments,
    *    and matches one of the payments under the opp
    * verify:
    *    no new donation created
    *    existing opp matched, but left open
    *    payment matched
    *    opp remaining balance updated
    **********************************************************************************************************/
    static testMethod void donationMatchRules18a() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) return;

        insert new DataImport__c(Contact1_Firstname__c='c0', Contact1_Lastname__c='c0', Contact1_Personal_Email__c='c0@c0.com',
            Donation_Amount__c=12,
            Donation_Date__c=System.Today(),
            Payment_Method__c = 'Check',
            Donation_Donor__c='contact1');

        donationMatchRules(
            UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c') + ';' +
                UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c'),
            12, BDI_DataImport_API.RequireExactMatch, label.bdiMatched, label.bdiMatched, false, 0);

        DataImport__c di = [select Status__c, DonationImported__c, DonationImportStatus__c,
            Donation_Possible_Matches__c, PaymentImported__c, PaymentImportStatus__c from DataImport__c];
        system.assertEquals(label.bdiMatched, di.DonationImportStatus__c);
        system.assertEquals(label.bdiMatched, di.PaymentImportStatus__c);

        Opportunity opp = getOpportunityWithPayments(di.DonationImported__c);
        npe01__OppPayment__c pmt = [select Id, npe01__Payment_Amount__c, npe01__Paid__c from npe01__OppPayment__c where id = :di.PaymentImported__c];

        system.assertEquals(false, opp.IsWon);
        system.assertEquals(false, opp.IsClosed);
        system.assertEquals(48, opp.Amount);
        system.assertEquals(36, PMT_PaymentCreator.getAmountOutstanding(opp));
        system.assertEquals(12, pmt.npe01__Payment_Amount__c);
        system.assertEquals(true, pmt.npe01__Paid__c);
    }

    /*********************************************************************************************************
    * @description operation:
    *    import donations using different matching rules: Amount, Date, where Opp has Multiple Payments,
    *    and matches multiple of the payments under the opp, using a date range
    * verify:
    *    no new donation created
    *    existing opp matched, but left open
    *    payment matched
    *    opp remaining balance updated
    **********************************************************************************************************/
    static testMethod void donationMatchRules18b() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) return;

        insert new DataImport__c(Contact1_Firstname__c='c0', Contact1_Lastname__c='c0', Contact1_Personal_Email__c='c0@c0.com',
            Donation_Amount__c=12,
            Donation_Date__c=System.Today(),
            Payment_Method__c = 'Check',
            Donation_Donor__c='contact1');

        donationMatchRules(
            UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c') + ';' +
                UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c'),
            12, BDI_DataImport_API.RequireBestMatch, label.bdiMatched, label.bdiMatchedBest, true, 1);

        DataImport__c di = [select Status__c, DonationImported__c, DonationImportStatus__c,
            Donation_Possible_Matches__c, PaymentImported__c, PaymentImportStatus__c from DataImport__c];
        system.assertEquals(label.bdiMatched, di.DonationImportStatus__c);
        system.assertEquals(label.bdiMatchedBest, di.PaymentImportStatus__c);

        Opportunity opp = getOpportunityWithPayments(di.DonationImported__c);
        npe01__OppPayment__c pmt = [select Id, npe01__Payment_Amount__c, npe01__Paid__c, npe01__Scheduled_Date__c from npe01__OppPayment__c where id = :di.PaymentImported__c];

        system.assertEquals(false, opp.IsWon);
        system.assertEquals(false, opp.IsClosed);
        system.assertEquals(48, opp.Amount);
        system.assertEquals(36, PMT_PaymentCreator.getAmountOutstanding(opp));
        system.assertEquals(12, pmt.npe01__Payment_Amount__c);
        system.assertEquals(true, pmt.npe01__Paid__c);
        system.assertEquals(system.Today(), pmt.npe01__Scheduled_Date__c);
    }

    /*********************************************************************************************************
    * @description operation:
    *    import donations using different matching rules: Amount, Date, where Opp has Multiple Payments,
    *    and matches multiple of the payments under the opp, using a date range
    * verify:
    *    no new donation created
    *    existing opp matched, but left open
    *    payment matched
    *    opp remaining balance updated
    **********************************************************************************************************/
    static testMethod void donationMatchRules18c() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) return;

        insert new DataImport__c(Contact1_Firstname__c='c0', Contact1_Lastname__c='c0', Contact1_Personal_Email__c='c0@c0.com',
            Donation_Amount__c=12,
            Donation_Date__c=System.Today()+1,
            Payment_Method__c = 'Check',
            Donation_Donor__c='contact1');

        donationMatchRules(
            UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c') + ';' +
                UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c'),
            12, BDI_DataImport_API.RequireBestMatch, label.bdiMatched, label.bdiMatchedBest, true, 2);

        DataImport__c di = [select Status__c, DonationImported__c, DonationImportStatus__c,
            Donation_Possible_Matches__c, PaymentImported__c, PaymentImportStatus__c from DataImport__c];
        system.assertEquals(label.bdiMatched, di.DonationImportStatus__c);
        system.assertEquals(label.bdiMatchedBest, di.PaymentImportStatus__c);

        Opportunity opp = getOpportunityWithPayments(di.DonationImported__c);
        npe01__OppPayment__c pmt = [select Id, npe01__Payment_Amount__c, npe01__Paid__c, npe01__Scheduled_Date__c from npe01__OppPayment__c where id = :di.PaymentImported__c];

        system.assertEquals(false, opp.IsWon);
        system.assertEquals(false, opp.IsClosed);
        system.assertEquals(48, opp.Amount);
        system.assertEquals(36, PMT_PaymentCreator.getAmountOutstanding(opp));
        system.assertEquals(12, pmt.npe01__Payment_Amount__c);
        system.assertEquals(true, pmt.npe01__Paid__c);
        system.assertEquals(system.Today()+1, pmt.npe01__Scheduled_Date__c);
    }

    /*********************************************************************************************************
    * @description operation:
    *    import donations using different matching rules: Amount, Date, where Opp has Multiple Payments,
    *    and matches multiple of the payments under the opp, using a date range
    * verify:
    *    error, due to detection of multiple payments
    **********************************************************************************************************/
    static testMethod void donationMatchRules18d() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) return;

        insert new DataImport__c(Contact1_Firstname__c='c0', Contact1_Lastname__c='c0', Contact1_Personal_Email__c='c0@c0.com',
            Donation_Amount__c=12,
            Donation_Date__c=System.Today()+1,
            Payment_Method__c = 'Check',
            Donation_Donor__c='contact1');

        donationMatchRules(
            UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c') + ';' +
                UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c'),
            -1, BDI_DataImport_API.RequireExactMatch, label.bdiErrorPaymentMultiMatch, label.bdiErrorPaymentMultiMatch, true, 2);
    }

    /*********************************************************************************************************
    * @description operation:
    *    import donations using different matching rules: Amount, Date, where Opp has a payment that has
    *    a different date and amount
    * verify:
    *    no new donation created
    *    existing opp matched, and closed
    *    payment matched and marked paid and updated to match opp
    **********************************************************************************************************/
    static testMethod void donationMatchRules19() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) return;

        insert new DataImport__c(Contact1_Firstname__c='c0', Contact1_Lastname__c='c0', Contact1_Personal_Email__c='c0@c0.com',
            Donation_Amount__c=15,
            Donation_Date__c=System.Today(),
            Payment_Method__c = 'Check',
            Donation_Donor__c='contact1');

        donationMatchRules(
            UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c') + ';' +
                UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c'),
            15, BDI_DataImport_API.RequireBestMatch, label.bdiMatched, label.bdiMatched, false, 0);

        DataImport__c di = [select Status__c, DonationImported__c, DonationImportStatus__c,
            Donation_Possible_Matches__c, PaymentImported__c, PaymentImportStatus__c from DataImport__c];
        system.assertEquals(label.bdiMatched, di.DonationImportStatus__c);
        system.assertEquals(label.bdiMatched, di.PaymentImportStatus__c);

        Opportunity opp = getOpportunityWithPayments(di.DonationImported__c);
        npe01__OppPayment__c pmt = [select Id, npe01__Payment_Amount__c, npe01__Paid__c, npe01__Scheduled_Date__c, npe01__Payment_Date__c from npe01__OppPayment__c where id = :di.PaymentImported__c];

        system.assertEquals(true, opp.IsWon);
        system.assertEquals(true, opp.IsClosed);
        system.assertEquals(15, opp.Amount);
        system.assertEquals(0, PMT_PaymentCreator.getAmountOutstanding(opp));
        system.assertEquals(15, pmt.npe01__Payment_Amount__c);
        system.assertEquals(true, pmt.npe01__Paid__c);
        system.assertEquals(system.Today(), pmt.npe01__Payment_Date__c);
    }

    /*********************************************************************************************************
    * @description operation: 
    *    the shared routine to actually test the different donations different matching rules. 
    * verify: 
    *    correct donations matched
    *
    * @param strRule The matching rules to use in the test
    * @param imatch The existing Opp we expect to match against.  use -1 if no match expected.  use -2 if best match expected (which can be random)
    * @param expectedStatus The status value we expect to be set in DonationImportStatus__c
    * @param expectedStatusPmt The status value we expect to be set in PaymentImportStatus__c
    * @param hasMultiMatches Whether we expect anything in Donation_Possible_Matches__c
    **********************************************************************************************************/            
    static void donationMatchRules(string strRule, integer imatch, string matchBehavior, 
        string expectedStatus, string expectedStatusPmt, boolean hasMultiMatches, integer dateRange) {
        
        // create opps to match against
        Contact con = new Contact(firstname='c0', lastname='c0', email='c0@c0.com');
        insert con;
        UTIL_UnitTestData_TEST.setFixedSearchResults(new List<Contact>{ con });
        list<Opportunity> listOpp = new list<Opportunity>();
        
        // Opps 0-5 will get their default single Payment record
        listOpp.add(new Opportunity(name='Opp0', Primary_Contact__c=con.Id, Amount=100, CloseDate=System.Today(), 
            StageName=UTIL_unitTestData_TEST.getOpenStage()));
        listOpp.add(new Opportunity(name='Opp1', Primary_Contact__c=con.Id, Amount=100, CloseDate=System.Today().addDays(-1), 
            StageName=UTIL_unitTestData_TEST.getOpenStage()));
        listOpp.add(new Opportunity(name='Opp2', Primary_Contact__c=con.Id, Amount=200, CloseDate=System.Today(), 
            StageName=UTIL_unitTestData_TEST.getOpenStage(), Type='MyUniqueID'));
        listOpp.add(new Opportunity(name='Opp3', Primary_Contact__c=con.Id, Amount=200, CloseDate=System.Today(), 
            StageName=UTIL_unitTestData_TEST.getOpenStage(), 
            RecordTypeId=UTIL_RecordTypes.getRecordTypeIdForMembershipTests(Opportunity.sObjectType)));
        listOpp.add(new Opportunity(name='Opp4', Primary_Contact__c=con.Id, Amount=300, CloseDate=System.Today(), 
            StageName=UTIL_unitTestData_TEST.getOpenStage()));
        listOpp.add(new Opportunity(name='Opp5', Primary_Contact__c=con.Id, Amount=500, CloseDate=System.Today(), 
            StageName=UTIL_unitTestData_TEST.getOpenStage(), npe01__Do_Not_Automatically_Create_Payment__c=true));
        
        // Opps 6-7 will have no Payment records
        listOpp.add(new Opportunity(name='Opp6', Primary_Contact__c=con.Id, Amount=600, CloseDate=System.Today(), 
            StageName=UTIL_unitTestData_TEST.getOpenStage(), npe01__Do_Not_Automatically_Create_Payment__c=true));
        listOpp.add(new Opportunity(name='Opp7', Primary_Contact__c=con.Id, Amount=700, CloseDate=System.Today(), 
            StageName=UTIL_unitTestData_TEST.getOpenStage(), npe01__Do_Not_Automatically_Create_Payment__c=true));

        // Opps 8-9 will have multiple Payment records
        listOpp.add(new Opportunity(name='Opp8', Primary_Contact__c=con.Id, Amount=600, CloseDate=System.Today(), 
            StageName=UTIL_unitTestData_TEST.getOpenStage(), npe01__Do_Not_Automatically_Create_Payment__c=true));
        listOpp.add(new Opportunity(name='Opp9', Primary_Contact__c=con.Id, Amount=700, CloseDate=System.Today(), 
            StageName=UTIL_unitTestData_TEST.getOpenStage(), npe01__Do_Not_Automatically_Create_Payment__c=true));
            
        // Opp 10 will have multiple Payment records, but only one open
        listOpp.add(new Opportunity(name='Opp10', Primary_Contact__c=con.Id, Amount=600, CloseDate=System.Today(), 
            StageName=UTIL_unitTestData_TEST.getOpenStage(), npe01__Do_Not_Automatically_Create_Payment__c=true));

        // Opp 11 will have one Payment records, but it will be written off, but opp left open.
        listOpp.add(new Opportunity(name='Opp11', Primary_Contact__c=con.Id, Amount=1100, CloseDate=System.Today(), 
            StageName=UTIL_unitTestData_TEST.getOpenStage(), npe01__Do_Not_Automatically_Create_Payment__c=true));

        // Opp 12 will have multiple Payment records, different days, same amounts.
        listOpp.add(new Opportunity(name='Opp12', Primary_Contact__c=con.Id, Amount=48, CloseDate=System.Today(),
            StageName=UTIL_unitTestData_TEST.getOpenStage(), npe01__Do_Not_Automatically_Create_Payment__c=true));

        // Opp 13 will have a payment with no scheduled date!
        listOpp.add(new Opportunity(name='Opp13', Primary_Contact__c=con.Id, Amount=1330, CloseDate=System.Today(),
            StageName=UTIL_unitTestData_TEST.getOpenStage(), npe01__Do_Not_Automatically_Create_Payment__c=true));

        // Opp 14 will have no Amount, nor payment!
        listOpp.add(new Opportunity(name='Opp14', Primary_Contact__c=con.Id, Amount=null, CloseDate=System.Today(),
            StageName=UTIL_unitTestData_TEST.getOpenStage(), npe01__Do_Not_Automatically_Create_Payment__c=true));

        // Opp 15 will have a payment that doesn't agree on date
        listOpp.add(new Opportunity(name='Opp15', Primary_Contact__c=con.Id, Amount=15, CloseDate=System.Today(),
            StageName=UTIL_unitTestData_TEST.getOpenStage(), npe01__Do_Not_Automatically_Create_Payment__c=true));

        insert listOpp;
        
        // create Opps 8-11's Payment records
        list<npe01__OppPayment__c> listPmt = new list<npe01__OppPayment__c>();
        listPmt.add(new npe01__OppPayment__c(npe01__Opportunity__c=listOpp[8].Id, npe01__Payment_Amount__c=350, 
            npe01__Scheduled_Date__c=System.Today(), npe01__Check_Reference_Number__c='dupe'));
        listPmt.add(new npe01__OppPayment__c(npe01__Opportunity__c=listOpp[8].Id, npe01__Payment_Amount__c=250, 
            npe01__Scheduled_Date__c=System.Today()));

        listPmt.add(new npe01__OppPayment__c(npe01__Opportunity__c=listOpp[9].Id, npe01__Payment_Amount__c=550, 
            npe01__Scheduled_Date__c=System.Today(), npe01__Check_Reference_Number__c='dupe'));
        listPmt.add(new npe01__OppPayment__c(npe01__Opportunity__c=listOpp[9].Id, npe01__Payment_Amount__c=150, 
            npe01__Scheduled_Date__c=System.Today(), npe01__Check_Reference_Number__c='pick me'));

        listPmt.add(new npe01__OppPayment__c(npe01__Opportunity__c=listOpp[10].Id, npe01__Payment_Amount__c=575, 
            npe01__Scheduled_Date__c=System.Today(), npe01__Check_Reference_Number__c='dupe', npe01__Paid__c=true));
        listPmt.add(new npe01__OppPayment__c(npe01__Opportunity__c=listOpp[10].Id, npe01__Payment_Amount__c=125, 
            npe01__Scheduled_Date__c=System.Today(), npe01__Check_Reference_Number__c='dupe'));

        listPmt.add(new npe01__OppPayment__c(npe01__Opportunity__c=listOpp[11].Id, npe01__Payment_Amount__c=1100, 
            npe01__Scheduled_Date__c=System.Today(), npe01__Written_Off__c=true));

        listPmt.add(new npe01__OppPayment__c(npe01__Opportunity__c=listOpp[12].Id, npe01__Payment_Amount__c=12,
            npe01__Scheduled_Date__c=System.Today()));
        listPmt.add(new npe01__OppPayment__c(npe01__Opportunity__c=listOpp[12].Id, npe01__Payment_Amount__c=12,
            npe01__Scheduled_Date__c=System.Today()+1));
        listPmt.add(new npe01__OppPayment__c(npe01__Opportunity__c=listOpp[12].Id, npe01__Payment_Amount__c=12,
            npe01__Scheduled_Date__c=System.Today()+2));
        listPmt.add(new npe01__OppPayment__c(npe01__Opportunity__c=listOpp[12].Id, npe01__Payment_Amount__c=12,
            npe01__Scheduled_Date__c=System.Today()+3));

        listPmt.add(new npe01__OppPayment__c(npe01__Opportunity__c=listOpp[13].Id, npe01__Payment_Amount__c=12));

        listPmt.add(new npe01__OppPayment__c(npe01__Opportunity__c=listOpp[15].Id, npe01__Payment_Amount__c=55,
            npe01__Scheduled_Date__c=System.Today()+15));

        insert listPmt;
        
        // set the specified settings
        Data_Import_Settings__c diSettings = UTIL_CustomSettingsFacade.getDataImportSettings();
        diSettings.Donation_Matching_Rule__c = strRule;
        diSettings.Donation_Matching_Behavior__c = matchBehavior;
        diSettings.Donation_Date_Range__c = dateRange;
 
        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();

        // Since we have a hard time constraining the length of translated labels, truncate here
        if(expectedStatus.length() > 255) {
            expectedStatus = expectedStatus.substring(0,255);
        }        

        list<DataImport__c> listDI = [select Status__c, DonationImported__c, DonationImportStatus__c, 
            Donation_Possible_Matches__c, PaymentImported__c, PaymentImportStatus__c, Payment_Possible_Matches__c from DataImport__c];
        system.assertEquals(1, listDI.size());
        system.assertEquals(expectedStatus, listDI[0].DonationImportStatus__c);
        system.assertEquals(hasMultiMatches, listDI[0].Donation_Possible_Matches__c != null || listDI[0].Payment_Possible_Matches__c != null);
        
        if (imatch >= 0) {

            Boolean shouldImportFail = false;
            Boolean shouldAssertImportedPayment = true;

            // There's special logic for specific donation match tests
            switch on imatch {
                when 6, 7 {
                    shouldAssertImportedPayment = false;
                }
                when 11 {
                    shouldImportFail = false;
                    shouldAssertImportedPayment = false;
                }
            }

            if (shouldImportFail) {
                // the payment was marked as written off - but matched a payment and an attempt was made to marked as paid)
                System.assertEquals(BDI_DataImport_API.bdiFailed, listDI[0].Status__c);
            } else {
                System.assertEquals(BDI_DataImport_API.bdiImported, listDI[0].Status__c);
            }

            System.assertEquals(listOpp[imatch].Id, listDI[0].DonationImported__c);

            if (shouldAssertImportedPayment) {
                system.assertNotEquals(null, listDI[0].PaymentImported__c);
                system.assertEquals(expectedStatusPmt, listDI[0].PaymentImportStatus__c);
                npe01__OppPayment__c pmt = [select Id, npe01__Payment_Method__c from npe01__OppPayment__c
                    where Id = :listDI[0].PaymentImported__c];
                system.assertEquals('Check', pmt.npe01__Payment_Method__c);
            }
	        // verify we matched an existing opp (no new opp created)
	        list<Opportunity> listOppX = [select Id, Name, Amount, Primary_Contact__c from Opportunity];
	        system.assertEquals(listOpp.size(), listOppX.size());

            if (imatch == 11) {
                Opportunity oppWithWrittenOffPmt = [
                        SELECT Amount,
                                CloseDate,
                                IsClosed,
                                IsWon,
                                Description, (
                                SELECT Id,
                                        npe01__Payment_Amount__c,
                                        npe01__Scheduled_Date__c,
                                        npe01__Written_Off__c,
                                        npe01__Paid__c
                                FROM npe01__OppPayment__r
                                WHERE Id = :listPmt[6].Id
                        )
                        FROM Opportunity
                        WHERE Name = 'Opp11'
                        LIMIT 1
                ];

                System.assertEquals('Opp was updated.', oppWithWrittenOffPmt.Description,
                        'The Opportunity.Description field should have been updated.');
                System.assert(oppWithWrittenOffPmt.IsClosed,
                        'The Opportunity should now be Closed/Won.');
                System.assert(oppWithWrittenOffPmt.IsWon,
                        'The Opportunity should now be Closed/Won.');

                System.assertEquals(listOpp[11].Amount, oppWithWrittenOffPmt.Amount,
                        'The Opportunity.Amount field should not have been updated.');
                System.assertEquals(listOpp[11].CloseDate, oppWithWrittenOffPmt.CloseDate,
                        'The Opportunity.CloseDate field should not have been updated.');

                System.assertEquals(listPmt[6].npe01__Payment_Amount__c,
                        oppWithWrittenOffPmt.npe01__OppPayment__r[0].npe01__Payment_Amount__c,
                        'The written-off Payment should be unchanged.');
                System.assertEquals(listPmt[6].npe01__Scheduled_Date__c,
                        oppWithWrittenOffPmt.npe01__OppPayment__r[0].npe01__Scheduled_Date__c,
                        'The written-off Payment should be unchanged.');
                System.assertEquals(listPmt[6].npe01__Written_Off__c,
                        oppWithWrittenOffPmt.npe01__OppPayment__r[0].npe01__Written_Off__c,
                        'The written-off Payment should be unchanged.');
                System.assertEquals(listPmt[6].npe01__Paid__c,
                        oppWithWrittenOffPmt.npe01__OppPayment__r[0].npe01__Paid__c,
                        'The written-off Payment should be unchanged.');
            }
        }
    }

    private static Opportunity getOpportunityWithPayments(Id oppId) {
        // requery the Opportunity for all fields that we need.
        return [SELECT Id, IsWon, IsClosed, Amount, npe01__Amount_Outstanding__c,
            (SELECT Id, npe01__Payment_Amount__c, npe01__Written_Off__c, npe01__Paid__c FROM  npe01__OppPayment__r)
            FROM Opportunity WHERE Id = :oppId LIMIT 1];
    }

}