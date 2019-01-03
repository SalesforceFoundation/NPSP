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
* @description Batch Class for creating Tribute from Opportunity.
*/
public with sharing class OPP_CreateTribute_BATCH implements Database.Batchable<sObject> {

    /*******************************************************************************************************
    * @description Opportunity Query used to find Opportunities to Convert
    */
    private static final String OPP_QUERY = 'SELECT Id, ' +
                                                    'Tribute_Type__c, ' +
                                                    'Honoree_Contact__c, ' + 
                                                    'Honoree_Name__c ' + 
                                            'FROM Opportunity';
    
    private String additionalWhereClause = null;

    /*******************************************************************************************************
    * @description no argument constructor for the class
    */
    public OPP_CreateTribute_BATCH() {

    }

    /*******************************************************************************************************
    * @description constructor for the class
    * @param additionalWhereClause - String allowing batch job to be invoked with alternative/additional constraints
    */ 
    public OPP_CreateTribute_BATCH(String additionalWhereClause) {
        this.additionalWhereClause = additionalWhereClause;
    }

    /******************************************************************************************************
    * @description Batch start method. Runs through all the Opportunities to be converted.
    */
    public Database.QueryLocator start(Database.BatchableContext info) {
        String soqlQuery = (String.isNotBlank(additionalWhereClause)) ? OPP_QUERY + ' WHERE (' + additionalWhereClause + ')' : OPP_QUERY;

        // Deliberately not trapping this potentially invalid query (since Where Clause might be invalid).
        // This will display an error in the job widget used on the settings page, and send the person who 
        // launched it a script error.  Decided this was best option with Nicolas Campbell
        return Database.getQueryLocator(soqlQuery);
    }

    /*******************************************************************************************************
    * @description Batch execute method.
    * @return void.
    ********************************************************************************************************/
    public void execute(Database.BatchableContext BC, List<Opportunity> scope) {

        List<Opportunity> updOpportunities = new List<Opportunity>();

        List<Tribute__c> newTributes = new List<Tribute__c>();
        for (Opportunity opp : scope) {
            if (hasTributeInfo(opp)) {
                newTributes.add(
                    new Tribute__c(
                        Opportunity__c = opp.Id,
                        Tribute_Type__c = opp.Tribute_Type__c,
                        Honoree_Contact__c = opp.Honoree_Contact__c,
                        Honoree_Name__c = opp.Honoree_Name__c
                    )
                );

                //clear the Opportunity fields
                opp.Tribute_Type__c = null;
                opp.Honoree_Contact__c = null;
                opp.Honoree_Name__c = null;
                
                updOpportunities.add(opp);
            }
        }
        
        if (updOpportunities.size() > 0) {
            // Moving Honoree from Opportunity to a related Tribute record, with no other changes means there is no point to running the triggers (as there will be no changes in
            // OCRs, etc.), so we are disabling the triggers
            TDTM_TriggerHandler.disableTDTM = true;
            insert newTributes;
            update updOpportunities;
            TDTM_TriggerHandler.disableTDTM = false;
        }
    }

    /*******************************************************************************************************
    * @description Checks to see if there is Tribute Information on the Opportunity
    * It returns true if one or more of the following fields null/blank: Honoree_Contact__c (null only),
    * Honoree_Name__c (null/blank), Tribute_Type__c (null/blank).
    * @param Opportunity opp - The opportunity to check
    * @return Boolean true if Tribute info is present, false otherwise
    ********************************************************************************************************/
    @testVisible private static Boolean hasTributeInfo(Opportunity opp) {
        return (opp.Honoree_Contact__c != null || String.isNotBlank(opp.Honoree_Name__c) || String.isNotBlank(opp.Tribute_Type__c));
    }

    /******************************************************************************************************
    * @description Batch finish method.
    */
    public void finish(Database.BatchableContext info) {

    }
}