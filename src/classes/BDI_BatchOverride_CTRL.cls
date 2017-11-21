/*
    Copyright (c) 2017, Salesforce.org
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
* @date 2017
* @group Batch Data Import
* @group-content ../../ApexDocContent/BatchDataImport.htm
* @description controller for the NPSP Data Import Batch edit override visualforce page
*/
public with sharing class BDI_BatchOverride_CTRL {

    /*******************************************************************************************************
    * @description holds the Batch currently being edited by the page
    */
    public DataImportBatch__c diBatch { get; set; }

    /*******************************************************************************************************
    * @description after successful save set to true to redirect page
    */ 
    public Boolean redirect {get; set;}

    /*******************************************************************************************************
    * @description constructor for the page
    * @param controller the StandardController for the page
    * @return nothing
    */
    public BDI_BatchOverride_CTRL(ApexPages.StandardController controller) {
        redirect = false;
        // since our page doesn't directly refer to the Batch fields, we must explicitly list them
        if (!Test.isRunningTest()) {
            List<String> listFields = new List<String>{
                'Id',
                'Name',
                UTIL_Namespace.StrTokenNSPrefix('Account_Custom_Unique_ID__c'),
                UTIL_Namespace.StrTokenNSPrefix('Batch_Description__c'),
                UTIL_Namespace.StrTokenNSPrefix('Batch_Process_Size__c'),
                UTIL_Namespace.StrTokenNSPrefix('Contact_Custom_Unique_ID__c'),
                UTIL_Namespace.StrTokenNSPrefix('Contact_Matching_Rule__c'),
                UTIL_Namespace.StrTokenNSPrefix('Donation_Date_Range__c'),
                UTIL_Namespace.StrTokenNSPrefix('Donation_Matching_Behavior__c'),
                UTIL_Namespace.StrTokenNSPrefix('Donation_Matching_Implementing_Class__c'),
                UTIL_Namespace.StrTokenNSPrefix('Donation_Matching_Rule__c'),
                UTIL_Namespace.StrTokenNSPrefix('Process_Using_Scheduled_Job__c')
            };
            controller.addFields(listFields);
        }

        diBatch = (DataImportBatch__c) controller.getRecord();

        // for some reason, New override doesn't get default values set
        if (diBatch.Donation_Matching_Rule__c == null) {
            diBatch.Donation_Matching_Rule__c = UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c') + ';' +
                UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c');
        }

        // our multiselect list of donation related fields holds keys in lowercase
        diBatch.Donation_Matching_Rule__c = diBatch.Donation_Matching_Rule__c.toLowerCase();

        //if clone param is set, this is the clone button override
        Map<String, String> params = ApexPages.currentPage().getParameters();
        if (params.containsKey('clone') && params.get('clone') == '1') {
            diBatch.Id = null;
            diBatch.Name += ' - ' + Label.lblCloned;
        }

    }

    /*********************************************************************************************************
    * @description actionMethod to Save the current Batch.
    */
    public PageReference save() {
        try {
            BDI_DataImportService.validateSettings(diBatch);
            UTIL_DMLService.upsertRecord(diBatch);
            redirect = true;
        } catch (Exception ex) {
            ApexPages.addMessages(ex);
        }
        return null;
    }

}