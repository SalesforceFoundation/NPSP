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
* @date 2017
* @group Rollups
* @group-content ../../ApexDocContent/Rollups.htm
* @description Selector class for Rollup Field Definition custom metadata.
*/
public with sharing class RLLP_Definition_SEL {

    public static List<Rollup__mdt> rollups = [SELECT Id,
                                                    DeveloperName,
                                                    MasterLabel,
                                                    Active__c,
                                                    Amount_Field__r.QualifiedApiName,
                                                    Amount_Object__r.QualifiedApiName,
                                                    Attribution_Field__r.QualifiedApiName,
                                                    Attribution_Object__r.QualifiedApiName,
                                                    Date_Field__r.QualifiedApiName,
                                                    Date_Object__r.QualifiedApiName,
                                                    Description__c,
                                                    Detail_Field__r.QualifiedApiName,
                                                    Detail_Object__r.QualifiedApiName,
                                                    Summary_Field__r.QualifiedApiName,
                                                    Summary_Object__r.QualifiedApiName,
                                                    Filter_Group__c,
                                                    Operation__c,
                                                    Integer__c
                                                FROM Rollup__mdt];

    //It would be cool to refactor these lazy loaders to only loop over rollups a single time in order to create the various maps
    public static Map<Schema.SObjectType, List<Rollup__mdt>> rollupsBySummaryType {
        get {
            if (rollupsBySummaryType == null) {
                rollupsBySummaryType = new Map<Schema.SObjectType, List<Rollup__mdt>>();
                for (Rollup__mdt rollup : rollups) {
                    Schema.SObjectType objType = UTIL_Describe.getSObjectType(rollup.Summary_Object__r.QualifiedApiName);
                    if (!rollupsBySummaryType.containsKey(objType)) {
                        rollupsBySummaryType.put(objType, new List<Rollup__mdt>());
                    }
                    rollupsBySummaryType.get(objType).add(rollup);
                }
            }
            return rollupsBySummaryType;
        }
        private set;
    }

    public static Map<Schema.SObjectType, List<Rollup__mdt>> rollupsByDetailType {
        get {
            if (rollupsBySummaryType == null) {
                rollupsBySummaryType = new Map<Schema.SObjectType, List<Rollup__mdt>>();
                for (Rollup__mdt rollup : rollups) {
                    Schema.SObjectType objType = UTIL_Describe.getSObjectType(rollup.Detail_Object__r.QualifiedApiName);
                    if (!rollupsBySummaryType.containsKey(objType)) {
                        rollupsBySummaryType.put(objType, new List<Rollup__mdt>());
                    }
                    rollupsBySummaryType.get(objType).add(rollup);
                }
            }
            return rollupsBySummaryType;
        }
        private set;
    }

    public static Map<Id, List<Rollup__mdt>> rollupsByFilterGroup {
        get {
            if (rollupsByFilterGroup == null) {
                rollupsByFilterGroup = new Map<Id, List<Rollup__mdt>>();
                for (Rollup__mdt rollup : rollups) {
                    if (!rollupsByFilterGroup.containsKey(rollup.Filter_Group__c)) {
                        rollupsByFilterGroup.put(rollup.Filter_Group__c, new List<Rollup__mdt>());
                    }
                    rollupsByFilterGroup.get(rollup.Filter_Group__c).add(rollup);
                }
            }
            return rollupsByFilterGroup;
        }
        private set;
    }

}

/*
We can deserialize JSON into CMT objects as below, for testing/mocking purposes: (TEST THIS with cross CMT relationships)

Rollup__mdt foo = [SELECT Id, DeveloperName, MasterLabel,Amount_Field__c,Amount_Field__r.QualifiedApiName,
                                    Attribution_Field__r.QualifiedApiName,
                                    Attribution_Object__r.QualifiedApiName,
                                    Date_Field__r.QualifiedApiName,
                                    Description__c,
                                    Detail_Field__r.QualifiedApiName,
                                    Detail_Object__r.QualifiedApiName,
                                    Filter_Group__c,
                                    Is_Active__c,
                                    Operation__c,
                                    Rollup_Definition__c,
                                    Years_Back__c
                                FROM Rollup__mdt WHERE id = 'm016A000000c16v'];


String mdt = JSON.serialize(foo);
system.debug(mdt);

Rollup__mdt foo3 = (Rollup__mdt)JSON.deserialize(mdt, Rollup__mdt.class);
system.debug(foo3);

String mdt = '{"attributes":{"type":"Rollup__mdt","url":"/services/data/v40.0/sobjects/Rollup__mdt/m016A000000c16vQAA"},"Id":"m016A000000c16vQAA","DeveloperName":"Test","MasterLabel":"Test","Amount_Field__c":"Opportunity.00N6A000006NHTb","Date_Field__c":"Opportunity.CloseDate","Detail_Object__c":"Opportunity","Is_Active__c":true,"Operation__c":"Count","Years_Back__c":1,"Amount_Field__r":{"attributes":{"type":"FieldDefinition","url":"/services/data/v40.0/sobjects/FieldDefinition/Opportunity.000000000000000AAA"},"Id":"000000000000000AAA","DurableId":"Opportunity.000000000000000AAA","QualifiedApiName":"Matching_Gift__c"},"Date_Field__r":{"attributes":{"type":"FieldDefinition","url":"/services/data/v40.0/sobjects/FieldDefinition/Opportunity.CloseDate"},"Id":"000000000000000AAA","DurableId":"Opportunity.CloseDate","QualifiedApiName":"CloseDate"},"Detail_Object__r":{"attributes":{"type":"EntityDefinition","url":"/services/data/v40.0/sobjects/EntityDefinition/Opportunity"},"Id":"000000000000000AAA","DurableId":"Opportunity","QualifiedApiName":"Opportunity"}}';

*/