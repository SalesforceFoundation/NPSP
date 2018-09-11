/*
    Copyright (c) 2018 Salesforce.org
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
* @date 2018
* @group Batch Data Import
* @group-content ../../ApexDocContent/BatchDataImport.htm
* @description Tests for BDI_DataImportService
*/
@isTest
private with sharing class BDI_DataImportService_TEST {
    
    
    /*******************************************************************************************************************
    * @description Verifies UniqueID handling.
    * The method returns expected results for various types of fields.
    */
    @isTest
    private static void testUniqueIdHandling() {
        System.assertEquals(
            UTIL_Namespace.StrTokenNSPrefix('Contact1_Website__c'),
            BDI_DataImportService.strDICustomIDField('Contact1', 'Website')
        );

        System.assertEquals('Contact1_Foo__c', BDI_DataImportService.strDICustomIDField('Contact1', 'Foo__c'));

        String expectedCustomIdField = UTIL_Namespace.getNamespace().equalsIgnoreCase('npsp')
            ? 'npsp__Contact1_Bar__c'
            : 'Contact1_Bar__c';
        System.assertEquals(expectedCustomIdField, BDI_DataImportService.strDICustomIDField('Contact1', 'npsp__Bar__c'));

        System.assertEquals('Contact1_Baz__c', BDI_DataImportService.strDICustomIDField('Contact1', 'randomNS__Baz__c'));

        System.assertEquals(
            UTIL_Namespace.StrTokenNSPrefix('Contact1_Buz__c'),
            BDI_DataImportService.strDICustomIDField('Contact1', UTIL_Namespace.StrTokenNSPrefix('Buz__c'))
        );
    }

    /*******************************************************************************************************************
    * @description Verifies rollup trigger handlers are not deactivated if the data import settings to process rollups
    * is checked.
    */
    @isTest
    private static void rollupTriggersAreNotDeactivatedWhenRunRollupSettingsIsChecked() {
        Data_Import_Settings__c diSettings = getDataImportSettings();
        diSettings.Run_Opportunity_Rollups_while_Processing__c = true;

        Boolean isDryRun = false;
        BDI_DataImportService service = new BDI_DataImportService(isDryRun);
        service.injectDataImportSettings(diSettings);

        List<Trigger_Handler__c> expectedHandlers = TDTM_Config_API.getCachedRecords();

        service.disableAllOppRollups();

        System.assertEquals(expectedHandlers, TDTM_Config_API.getCachedRecords());
    }

    /*******************************************************************************************************************
    * @description Verifies rollup trigger handlers are deactivated if the data import settings to process rollups
    * is not checked.
    */
    @isTest
    private static void rollupTriggersAreDeactivatedWhenRunRollupSettingsIsNotChecked() {
        Data_Import_Settings__c diSettings = getDataImportSettings();
        diSettings.Run_Opportunity_Rollups_while_Processing__c = false;

        Boolean isDryRun = false;
        BDI_DataImportService service = new BDI_DataImportService(isDryRun);
        service.injectDataImportSettings(diSettings);

        Map<String, Trigger_Handler__c> handlerByKey = new Map<String, Trigger_Handler__c>();
        for (Trigger_Handler__c handler : TDTM_Config_API.getCachedRecords()) {
            handlerByKey.put(handler.Object__c + handler.Class__c, handler);
        }

        service.disableAllOppRollups();

        for (Trigger_Handler__c handler : TDTM_Config_API.getCachedRecords()) {
            Boolean isActive = isRollupTriggerHandler(handler) 
                ? false 
                : handlerByKey.get(handler.Object__c + handler.Class__c).Active__c;

            System.assertEquals(isActive, handler.Active__c, 'Only rollup trigger handlers should be deactivated: ' + handler);
        }
    }


    // Helpers
    ////////////

    /*******************************************************************************************************************
    * @description Retrieves and sets default on the data import settings
    */
    private static Data_Import_Settings__c getDataImportSettings() {
        Data_Import_Settings__c diSettings = UTIL_CustomSettingsFacade.getDataImportSettings();

        diSettings.Donation_Matching_Rule__c = UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c') + ';' +
            UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c');
        diSettings.Donation_Matching_Behavior__c = BDI_DataImport_API.ExactMatchOrCreate;

        return diSettings;
    }


    /*******************************************************************************************************************
    * @description Returns true if the trigger handler calculates rollups
    */
    private static Boolean isRollupTriggerHandler(Trigger_Handler__c handler) {
         return (handler.Object__c == 'Opportunity' && handler.Class__c == 'RLLP_OppRollup_TDTM') ||
            (handler.Object__c == 'Opportunity' && handler.Class__c == 'CRLP_Rollup_TDTM') ||
            (handler.Object__c == 'npe01__OppPayment__c' && handler.Class__c == 'CRLP_Rollup_TDTM'); 
    }
}