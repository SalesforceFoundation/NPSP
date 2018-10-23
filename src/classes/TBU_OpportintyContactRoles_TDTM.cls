/*
    Copyright (c) 2018, Salesforce.org
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
* @group Tribute
* @group-content ../../ApexDocContent/Tribute.htm
* @description Provides opportunity and contact role support for create/update Tribute
*/
public with sharing class TBU_OpportintyContactRoles_TDTM extends TDTM_Runnable {

    public static Boolean clearTributeFieldsFromOpportunity = false;

    /*******************************************************************************************************
    * @description Trigger Handler on Tribute that handles Contact Role support.
    * @param listNew the list of Tributes from trigger new.
    * @param listOld the list of Tributes from trigger old.
    * @param triggerAction which trigger event (BeforeInsert, AfterInsert, etc.).
    * @param objResult the describe for Tributes
    * @return dmlWrapper Always null. DML can't be deferred in this case as too many of our other opp related
    * triggers depend on Opportunity Contact Roles existing.
    ********************************************************************************************************/
    public override DmlWrapper run(List<SObject> newList, List<SObject> oldList,
            TDTM_Runnable.Action triggerAction, Schema.DescribeSObjectResult objResult) {

        if (triggerAction == TDTM_Runnable.Action.BeforeInsert) {
            //prevent create Tribute based on the setting
            if(UTIL_CustomSettingsFacade.getContactsSettings().Multiple_Tributes__c == Label.stgMultipleTributesSingleOpp) {
                preventInsertTributeRecord((List<Tribute__c>) newList);
            }

            OPP_OpportunityContactRoles_TDTM.updateHonoreeNotificationFields(newList, null, 'Tribute__c');
        } else if (triggerAction == TDTM_Runnable.Action.BeforeUpdate) {
            //prevent update Tribute record based on the setting
            if(UTIL_CustomSettingsFacade.getContactsSettings().Multiple_Tributes__c == Label.stgMultipleTributesSingleOpp) {
                preventInsertTributeRecord((List<Tribute__c>) newList);
            }

            OPP_OpportunityContactRoles_TDTM.updateHonoreeNotificationFields(newList, oldList, 'Tribute__c');
        } else if (triggerAction == TDTM_Runnable.Action.AfterInsert) {
            upsertContactRolesAfterInsert((List<Tribute__c>) newList);

            if(clearTributeFieldsFromOpportunity) {
                clearTributeFieldsOnOpportunity((List<Tribute__c>) newList);
            }

        } else if (triggerAction == TDTM_Runnable.Action.AfterUpdate) {
            upsertContactRolesAfterUpdate((List<Tribute__c>) newList, (List<Tribute__c>) oldList);
        }

        return new DmlWrapper();
    }

    private void preventInsertTributeRecord(List<Tribute__c> tributes) {
        for(Tribute__c tri : tributes) {
            tri.addError(Label.stgMultipleTributePreventInsert);
        }
    }

    private void upsertContactRolesAfterInsert(List<Tribute__c> tributes) {
        List<OpportunityContactRole> listOCRForInsert = new List<OpportunityContactRole>();

        Map<Id, Id> mapOppIdPrimaryContact = new Map<Id, Id>();

        OPP_OpportunityContactRoles_TDTM oppOCRTDTM = new OPP_OpportunityContactRoles_TDTM();

        //Get the opportunity information
        List<Id> oppIds = new List<Id>();
        for(Tribute__c tri : tributes) {
            oppIds.add(tri.Opportunity__c);
        }

        //Get existing primary contact roles for the trigger opps.
        for (Opportunity opp : [SELECT Id, Primary_Contact__c FROM Opportunity WHERE Id IN :oppIds]) {
            mapOppIdPrimaryContact.put(opp.Id, opp.Primary_Contact__c);
        }

        for(Tribute__c tri : tributes) {
            //using cloned opp to check if these OCRs need to be managed, as it relies on the Primary Contact field being populated
            if (oppOCRTDTM.needsManageOCR(tri, new Tribute__c(), 'Honoree_Contact__c', mapOppIdPrimaryContact.get(tri.Opportunity__c))) {
                listOCRForInsert.add(oppOCRTDTM.getOCR(tri,'Honoree_Contact__c'));
            }

            if (oppOCRTDTM.needsManageOCR(tri, new Tribute__c(), 'Notification_Recipient_Contact__c', mapOppIdPrimaryContact.get(tri.Opportunity__c))) {
                listOCRForInsert.add(oppOCRTDTM.getOCR(tri, 'Notification_Recipient_Contact__c'));
            }
        }

        if(listOCRForInsert != null && listOCRForInsert.size() > 0) {
            insert listOCRForInsert;
        }
    }

    private void upsertContactRolesAfterUpdate(list<Tribute__c> tributes, list<Tribute__c> oldTributes) {
        Map<Id, Id> mapOppIdPrimaryContact = new Map<Id, Id>();

        OPP_OpportunityContactRoles_TDTM oppOCRTDTM = new OPP_OpportunityContactRoles_TDTM();

        //Get the opportunity information
        List<Id> oppIds = new List<Id>();
        for(Tribute__c tri : tributes) {
            oppIds.add(tri.Opportunity__c);
        }

        //Get existing primary contact roles for the trigger opps.
        for (Opportunity opp : [SELECT Id, Primary_Contact__c FROM Opportunity WHERE Id IN :oppIds]) {
            mapOppIdPrimaryContact.put(opp.Id, opp.Primary_Contact__c);
        }

        Map<Id, Map<Id,OpportunityContactRole>> mapOppIdMapConIdOCR = new Map<Id, Map<Id,OpportunityContactRole>>();

        //find changed opportunities and instantiate a map entry to hold OCRs
        for (integer i = 0; i< tributes.size(); i++) {
            Tribute__c newTri = tributes[i];
            Tribute__c oldTri = oldTributes[i];
            if (oppOCRTDTM.needsManageOCR(newTri, oldTri, 'Honoree_Contact__c', mapOppIdPrimaryContact.get(newTri.Opportunity__c)) ||
                    oppOCRTDTM.needsManageOCR(newTri, oldTri, 'Notification_Recipient_Contact__c', mapOppIdPrimaryContact.get(newTri.Opportunity__c))) {

                mapOppIdMapConIdOCR.put(newTri.Opportunity__c, new Map<Id,OpportunityContactRole>());
            }
        }

        //query for OCRs, hand off to processing methods
        if (!mapOppIdMapConIdOCR.isEmpty()) {
            for (OpportunityContactRole ocr : [SELECT OpportunityId, ContactId, isPrimary, Role FROM OpportunityContactRole
            WHERE OpportunityId IN :mapOppIdMapConIdOCR.keyset()]) {
                mapOppIdMapConIdOCR.get(ocr.OpportunityId).put(ocr.ContactId, ocr);
            }

            for (integer i = 0; i < tributes.size(); i++) {
                Tribute__c newTri = tributes[i];
                Tribute__c oldTri = oldTributes[i];
                //then manage honoree, if it has changed and it's not the same as the primary contact
                if (oppOCRTDTM.needsManageOCR(newTri, oldTri, 'Honoree_Contact__c', mapOppIdPrimaryContact.get(newTri.Opportunity__c))) {
                    oppOCRTDTM.manageOtherOCR(newTri, oldTri, mapOppIdMapConIdOCR.get(newTri.Opportunity__c), 'Honoree_Contact__c', new Map<Id, List<OpportunityContactRole>> (), 
                    new List<OpportunityContactRole> (), true);
                }
                //finally, manage the notification, if it has changed and it's not the same as either contact already dealt with
                if (oppOCRTDTM.needsManageOCR(newTri, oldTri, 'Notification_Recipient_Contact__c', mapOppIdPrimaryContact.get(newTri.Opportunity__c))) {
                    oppOCRTDTM.manageOtherOCR(newTri, oldTri, mapOppIdMapConIdOCR.get(newTri.Opportunity__c), 'Notification_Recipient_Contact__c', new Map<Id, List<OpportunityContactRole>> (), 
                    new List<OpportunityContactRole> (),  true);
                }
            }
        }
    }

    private void clearTributeFieldsOnOpportunity(List<Tribute__c> tributes) {
        //We do not want the Trigger to run when just clear the field
        TDTM_TriggerHandler.disableTDTM = true;
        Map<Id, Opportunity> oppsToUpdateMap = new Map<Id, Opportunity>();
        for(Tribute__c tri : tributes) {
            Opportunity opp = new Opportunity(Id = tri.Opportunity__c);
            //clear the Opportunity fields
            opp.Tribute_Type__c = null;
            opp.Honoree_Contact__c = null;
            opp.Honoree_Name__c = null;
            opp.Notification_Recipient_Contact__c = null;
            opp.Notification_Recipient_Name__c = null;
            opp.Notification_Recipient_Information__c = null;
            opp.Notification_Preference__c = null;
            opp.Notification_Message__c = null;
            oppsToUpdateMap.put(opp.Id, opp);
        }
        if(oppsToUpdateMap != null && oppsToUpdateMap.values().size() > 0) {
            update oppsToUpdateMap.values();
        }
        TDTM_TriggerHandler.disableTDTM = false;
    }
}