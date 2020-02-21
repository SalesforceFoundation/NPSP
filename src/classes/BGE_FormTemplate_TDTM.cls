/*
    Copyright (c) 2020, Salesforce.org
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
* @date 2020
* @group Form Templates
* @description TDTM trigger handler for Form_Template__c
*/

public with sharing class BGE_FormTemplate_TDTM extends TDTM_Runnable{

    /*******************************************************************************************************
    * @description Trigger Handler on Form Templates.
    * @param newlist the list of Form Templates from trigger new.
    * @param oldlist the list of Form Templates from trigger old.
    * @param triggerAction which trigger event (BeforeInsert, AfterInsert, etc.).
    * @param objResult the describe for Form Template
    * @return dmlWrapper.
    ********************************************************************************************************/
    public override DmlWrapper run(List<SObject> newlist, List<SObject> oldlist,
            TDTM_Runnable.Action triggerAction, Schema.DescribeSObjectResult objResult) {

        if (triggerAction == TDTM_Runnable.Action.BeforeDelete) {
            validateFormTemplateDeletion( oldlist );
        }

        return null;
    }


    /*******************************************************************************************************
     * @description Validates that a Form Template Record is not used by any Data Import Batch record
     *              or defined as default on gift_entry custom setting
     *              (If it is, an error is added to the Form Template record)
     * @param oldlist the list of Form Templates from trigger old.
     *******************************************************************************************************/
    private void validateFormTemplateDeletion ( List<SObject> oldlist ){

        // aux vars
        List<Form_Template__c> formTemplates = (List<Form_Template__c>) oldlist;
        Gift_Entry_Settings__c giftEntrySettings = UTIL_CustomSettings_API.getGiftEntrySettings();
        Map<Id, DataImportBatch__c> batchByFormTemplateId = new Map<Id, DataImportBatch__c>();
        String labelError = System.Label.geToastTemplateDeleteError;

        // search data import batch records using the templates to be deleted
        for (DataImportBatch__c batch : [
                SELECT Form_Template__c
                FROM DataImportBatch__c
                WHERE Form_Template__c IN : formTemplates
        ]) {
            batchByFormTemplateId.put(batch.Form_Template__c, batch);
        }

        // for every template record to be deleted
        for (Form_Template__c formTemplate : formTemplates) {

            // add error to records marked as default on gift entry settings
            if ( String.isNotEmpty(giftEntrySettings.Default_Gift_Entry_Template__c) &&
                    (giftEntrySettings.Default_Gift_Entry_Template__c.equals((String)formTemplate.Id)) ) {

                formTemplate.addError( labelError );

            // add error to template records related to any dataImportBatch record
            } else if (batchByFormTemplateId.containsKey(formTemplate.Id)) {

                formTemplate.addError( labelError );

            }

        }
    }

}