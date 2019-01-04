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
public class TBU_OpportunityContactRoles_TDTM extends TDTM_Runnable {

    private static final String FIELD_NAME_PRIMARY_CONTACT = 'Primary_Contact__c';
    private static final String FIELD_NAME_HONOREE_CONTACT = 'Honoree_Contact__c';
    private static final String FIELD_NAME_NOTIFICATION_RECIPIENT_CONTACT = 'Notification_Recipient_Contact__c';

    /** @description clearTributeFieldsFromOpportunity boolean value to control
    * if we need to clear Tribute fields on Opportunity
    */
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
            //Prevent insert tribute if the setting does not indicate that the system allow Multiple Tribute
            if (TBU_MultipleTributesSettingsFacade.isMultipleTributesSingle()) {
                preventTributeRecordOperations((List<Tribute__c>) newList);
            }

            //Prevent insert Tribute if the setting allow Mix but the Opportunity has Tribute Info
            if (TBU_MultipleTributesSettingsFacade.isMultipleTributesFlexible()) {
                preventInsertTributeForMixMode((List<Tribute__c>) newList);
            }

            //we will populate Name field if the setting allow Multiple Tribute
            if (TBU_MultipleTributesSettingsFacade.isMultipleTributesFlexible() || TBU_MultipleTributesSettingsFacade.isMultipleTributesLimited()) {
                OPP_OpportunityContactRoles_TDTM.updateHonoreeNotificationFields(newList, null, Tribute__c.SObjectType);
            }

        } else if (triggerAction == TDTM_Runnable.Action.BeforeUpdate) {
            //Prevent update tribute if the setting does not indicate that the system allow Multiple Tribute
            if (TBU_MultipleTributesSettingsFacade.isMultipleTributesSingle()) {
                preventTributeRecordOperations((List<Tribute__c>) newList);
            }

            //we will populate Name field if the setting allow Multiple Tribute
            if (TBU_MultipleTributesSettingsFacade.isMultipleTributesFlexible() || TBU_MultipleTributesSettingsFacade.isMultipleTributesLimited()) {
                OPP_OpportunityContactRoles_TDTM.updateHonoreeNotificationFields(newList, oldList, Tribute__c.SObjectType);
            }

        } else if (triggerAction == TDTM_Runnable.Action.AfterInsert) {
            //If the Tribute comes from Opportuniy, then we do not want to create OCR again
            if (!clearTributeFieldsFromOpportunity) {
                upsertContactRolesAfterInsert((List<Tribute__c>) newList);
            }

            if (clearTributeFieldsFromOpportunity) {
                clearTributeFieldsOnOpportunity((List<Tribute__c>) newList);
            }

        } else if (triggerAction == TDTM_Runnable.Action.AfterUpdate) {
            upsertContactRolesAfterUpdate((List<Tribute__c>) newList, (List<Tribute__c>) oldList);
        }

        return new DmlWrapper();
    }

    /******************************************************************************************************
    * @description Add Error to the tribute record
    * @param tributes The list of tributes
    * @return void
    ******************************************************************************************************/
    private void preventTributeRecordOperations(List<Tribute__c> tributes) {
        for (Tribute__c tri : tributes) {
            tri.addError(Label.errMultipleTributesEnforceSingle);
        }
    }

    /******************************************************************************************************
    * @description Add Error to the tribute record if Opportunity contains the Tribute Info
    * @param tributes The list of tributes
    * @return void
    ******************************************************************************************************/
    private void preventInsertTributeForMixMode(List<Tribute__c> tributes) {
        Set<Id> oppIds = new Set<Id>();

        for (Tribute__c tri : tributes) {
            oppIds.add(tri.Opportunity__c);
        }

        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();

        //Build the map of Opportunity which has the Tribute info on it
        for (Opportunity opp : [SELECT  Id,
                                        Tribute_Type__c,
                                        Honoree_Contact__c,
                                        Honoree_Name__c,
                                        Notification_Recipient_Contact__c,
                                        Notification_Recipient_Name__c,
                                        Notification_Recipient_Information__c,
                                        Notification_Preference__c,
                                        Notification_Message__c
                                FROM Opportunity
                                WHERE  Id in:oppIds]) {

            if (opp.Honoree_Contact__c != null || opp.Honoree_Name__c != null ||
                    opp.Tribute_Type__c != null) {
                oppMap.put(opp.Id, opp);
            }
        }

        for (Tribute__c tri : tributes) {
            if (oppMap.get(tri.Opportunity__c) != null) {
                tri.addError(Label.errMultipleTributesFlexibleUpdate);
            }
        }
    }

    /******************************************************************************************************
    * @description upsert OCR when insert the Tribute record
    * @param tributes The list of tributes
    * @return void
    ******************************************************************************************************/
    private void upsertContactRolesAfterInsert(List<Tribute__c> tributes) {
        //Get the opportunity Ids from Tributes
        Set<String> oppIds = new Set<String>();

        Map<Id, List<Tribute__c>> tributesByOpp = new Map<Id, List<Tribute__c>>();

        for (Tribute__c tri : tributes) {
            oppIds.add(tri.Opportunity__c);

            if(tributesByOpp.get(tri.Opportunity__c) == null) {
                tributesByOpp.put(tri.Opportunity__c, new List<Tribute__c>{tri});
            } else {
                tributesByOpp.put(tri.Opportunity__c, (List<Tribute__c>) tributesByOpp.get(tri.Opportunity__c).add(tri));
            }
        }

        String soql = buildOpportunitySOQL();

        List<Opportunity> opps = Database.query(soql);

        OPP_OpportunityContactRoles_TDTM oppOCRTDTM = new OPP_OpportunityContactRoles_TDTM();

        //Call OPP_OpportunityContactRoles_TDTM class to handle the OCR stuff
        oppOCRTDTM.upsertContactRolesAfterInsert(opps, tributesByOpp, true);

    }

    /******************************************************************************************************
    * @description upsert OCR when update the Tribute record
    * @param tributes The list of tributes
    * @return void
    ******************************************************************************************************/
    private void upsertContactRolesAfterUpdate(list<Tribute__c> tributes, list<Tribute__c> oldTributes) {
        //Get the opportunity Ids from Tributes
        Set<String> oppIds = new Set<String>();

        Map<Id, List<Tribute__c>> tributesByOpp = new Map<Id, List<Tribute__c>>();
        Map<Id, List<Tribute__c>> oldtributesByOpp = new Map<Id, List<Tribute__c>>();

        for (Tribute__c tri : tributes) {
            oppIds.add(tri.Opportunity__c);

            if(tributesByOpp.get(tri.Opportunity__c) == null) {
                tributesByOpp.put(tri.Opportunity__c, new List<Tribute__c>{ tri });
            } else {
                tributesByOpp.put(tri.Opportunity__c, (List<Tribute__c>) tributesByOpp.get(tri.Opportunity__c).add(tri));
            }
        }

        for (Tribute__c tri : oldTributes) {
            oppIds.add(tri.Opportunity__c);

            if(oldtributesByOpp.get(tri.Opportunity__c) == null) {
                oldtributesByOpp.put(tri.Opportunity__c, new List<Tribute__c>{ tri });
            } else {
                oldtributesByOpp.put(tri.Opportunity__c, (List<Tribute__c>) oldtributesByOpp.get(tri.Opportunity__c).add(tri));
            }
        }

        String soql = buildOpportunitySOQL();

        List<Opportunity> opps = Database.query(soql);

        OPP_OpportunityContactRoles_TDTM oppOCRTDTM = new OPP_OpportunityContactRoles_TDTM();

        //Call OPP_OpportunityContactRoles_TDTM class to handle the OCR stuff

        oppOCRTDTM.upsertContactRolesAfterUpdate(opps, opps, tributesByOpp, oldtributesByOpp, true);
    }

    /******************************************************************************************************
    * @description Clear Tribute fields on the Opportunity
    * @param tributes The list of tributes
    * @return void
    ******************************************************************************************************/
    private void clearTributeFieldsOnOpportunity(List<Tribute__c> tributes) {
        Map<Id, Opportunity> oppsToUpdateMap = new Map<Id, Opportunity>();
        for (Tribute__c tri : tributes) {
            Opportunity opp = new Opportunity(Id = tri.Opportunity__c);
            //clear the Opportunity fields
            opp.Tribute_Type__c = null;
            opp.Honoree_Contact__c = null;
            opp.Honoree_Name__c = null;
            oppsToUpdateMap.put(opp.Id, opp);
        }
        if (oppsToUpdateMap != null && (!oppsToUpdateMap.isEmpty())) {
            TDTM_TriggerHandler.disableTDTM = true;
            update oppsToUpdateMap.values();
            TDTM_TriggerHandler.disableTDTM = false;
        }
    }

    /******************************************************************************************************
    * @description Get All fields from the Opportunity object
    * @return String SOQL
    ******************************************************************************************************/
    private String buildOpportunitySOQL() {

        // Get all of the fields on the object
        Set<String> fieldNames = UTIL_Describe.getAllFieldsDescribe('Opportunity').keySet();

        // Build a Dynamic Query String.
        return new UTIL_Query()
                .withSelectFields(fieldNames)
                .withFrom('Opportunity')
                .withWhere('Id IN :oppIds')
                .build();
    }
}