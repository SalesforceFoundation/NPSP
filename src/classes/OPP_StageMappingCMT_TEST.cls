/*
    Copyright (c) 2019, Salesforce.org
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
* @date 2019
* @group Opportunity
* @group-content ../../ApexDocContent/Opportunity.htm
* @description Test Coverage for OPP_StageMappingCMT class
*/
@isTest(isParallel=true)
private with sharing class OPP_StageMappingCMT_TEST {

    /*********************************************************************************************************
    * @description Tests the createFinalizedOppStageToStateRecord Method and creates the finalized record. 
    * @return void
    **********************************************************************************************************/
    @isTest
    private static void testFinalizedOppStageToStateRecordCreation() {
        npe01__Contacts_And_Orgs_Settings__c contactAndOrgSetting = UTIL_CustomSettingsFacade.getContactsSettingsForTests(
                                                                        new npe01__Contacts_And_Orgs_Settings__c(
                                                                            Payments_Auto_Close_Stage_Name__c = UTIL_UnitTestData_TEST.getClosedWonStage()
                                                                        )
                                                                    );

        UTIL_CustomSettingsFacade.getContactsSettings().Payments_Auto_Close_Stage_Name__c = UTIL_UnitTestData_TEST.getClosedWonStage();
        
        Test.startTest();
        // We cannot test the result of this call since the response to this call is async. 
        // The best we can do right now is just execute the code. 
        List<Metadata.CustomMetadata> metadataToInsert = new List<Metadata.CustomMetadata>();
        Map<String, Object> params = new Map<String, Object>();

        metadataToInsert = Opp_StageMappingCMT.createFinalizedOppStageToStateRecord(metadataToInsert);

        Opp_StageMappingCMT.deployOppStageToStateMetadata(metadataToInsert, params);
        Test.stopTest();


    }

    /*********************************************************************************************************
    * @description Tests the createPledgedOppStageToStateRecord Method and creates the pledged record. 
    * verifies that it returns the appropriate values
    * @return void
    **********************************************************************************************************/
    @isTest
    private static void testPledgedOppStageToStateRecordCreation() {
        npe01__Contacts_And_Orgs_Settings__c contactAndOrgSetting = UTIL_CustomSettingsFacade.getContactsSettingsForTests(
                                                                        new npe01__Contacts_And_Orgs_Settings__c(
                                                                            Payments_Auto_Close_Stage_Name__c = UTIL_UnitTestData_TEST.getClosedWonStage()
                                                                        )
                                                                    );

        UTIL_CustomSettingsFacade.getContactsSettings().Payments_Auto_Close_Stage_Name__c = UTIL_UnitTestData_TEST.getClosedWonStage();
        
        Test.startTest();
        // We cannot test the result of this call since the response to this call is async. 
        // The best we can do right now is just execute the code. 
        List<Metadata.CustomMetadata> metadataToInsert = new List<Metadata.CustomMetadata>();
        Map<String, Object> params = new Map<String, Object>();

        metadataToInsert = Opp_StageMappingCMT.createPledgedOppStageToStateRecord(metadataToInsert);

        Opp_StageMappingCMT.deployOppStageToStateMetadata(metadataToInsert, params);
        Test.stopTest();


    }
}
