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
* @description Batch Class for creating Tribute from Opportunity.
*/
public class OPP_CreateTribute_BATCH implements Database.Batchable<sObject> {

    /*******************************************************************************************************
    * @description Opportunity Query used to find Opportunities to Convert
    */ 
    private static final String OPP_QUERY = 'SELECT Id, Tribute_Type__c, Honoree_Contact__c, Honoree_Name__c ' +
                                            'FROM Opportunity WHERE (' +
                                            'Honoree_Contact__c != null OR ' +
                                            'Honoree_Name__c != null OR ' +
                                            'Tribute_Type__c != null)';
    
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
        String soqlQuery = ((additionalWhereClause != null) && (additionalWhereClause.trim().length() > 0)) ?
                            OPP_QUERY + 'AND (' + additionalWhereClause + ')' : OPP_QUERY;

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
        List<Tribute__c> newTributes = new List<Tribute__c>();
        for (Opportunity opp : scope) {
            //Create new Tribute Record based on the Opportunity Tribute Fields
            Tribute__c newTribute = new Tribute__c();

            newTribute.Opportunity__c = opp.Id;
            newTribute.Tribute_Type__c = opp.Tribute_Type__c;
            newTribute.Honoree_Contact__c = opp.Honoree_Contact__c;
            newTribute.Honoree_Name__c = opp.Honoree_Name__c;
            newTributes.add(newTribute);

            //clear the Opportunity fields
            opp.Tribute_Type__c = null;
            opp.Honoree_Contact__c = null;
            opp.Honoree_Name__c = null;

        }
        
        //We do not want to run through opportunity trigger when clear Tribute Fields
        TDTM_TriggerHandler.disableTDTM = true;
        insert newTributes;
        update scope;
        TDTM_TriggerHandler.disableTDTM = false;
    }

    /******************************************************************************************************
    * @description Batch finish method.
    */
    public void finish(Database.BatchableContext info) {

    }
}