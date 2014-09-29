/*
    Copyright (c) 2014, Salesforce.com Foundation
    All rights reserved.
    
    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:
    
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Salesforce.com Foundation nor the names of
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
* @author Salesforce.com Foundation
* @date 2014
* @description Allocations Rollups to General Accounting Units
 */
public without sharing class ALLO_Rollup_SCHED extends UTIL_AbstractRollup_BATCH implements UTIL_MasterSchedulableHelper.UTIL_IRecurring {




    public Boolean executeReturnStatus() {
        if(UTIL_JobScheduler.canRunBatch()) {
            ALLO_Rollup_SCHED rollup = new ALLO_Rollup_SCHED(200);
            rollup.runRollups();
            return true;
        }
        return false;
    }

    public ALLO_Rollup_SCHED () {
        super (200);
    }

    public ALLO_Rollup_SCHED (id parentRecId) {
        super (parentRecId);
    }
    
    public ALLO_Rollup_SCHED (string SOQL) {
        super (SOQL);
    }

    public ALLO_Rollup_SCHED (integer batchSz) {
        super (batchSz);
    }
    
    public ALLO_Rollup_SCHED (set<id> parentRecIds) {
        super (parentRecIds);
    }
    
    public override string setParentObjName() {
        return UTIL_Namespace.StrTokenNSPrefix('General_Accounting_Unit__c');
    }

    public virtual override list<RollupSpec> setRollupSpecs() {



        //get allocations settings
        Allocations_Settings__c alloSettings = UTIL_CustomSettingsFacade.getAllocationsSettings();
        string strFiscalOrCalendarYear = alloSettings.Use_Fiscal_Year_for_Rollups__c ? 'Fiscal_Year' : 'Calendar_Year';
        string strExcludeOppRecTypesQuery = '';
        string strExcludeOppTypesQuery = '';

        //build string of opp rec type names for query
        if (alloSettings.Excluded_Opp_RecTypes__c != null) {
            strExcludeOppRecTypesQuery = 'AND Opportunity__r.RecordType.Name NOT IN ' + convertToQueryListFormat(alloSettings.Excluded_Opp_Rectypes__c);
        }

        //make  opp types
        if (alloSettings.Excluded_Opp_Types__c != null) {
            strExcludeOppTypesQuery = 'AND Opportunity__r.Type NOT IN ' + convertToQueryListFormat(alloSettings.Excluded_Opp_Types__c);
        }

        

        list<RollupSpec> mySpecs = new list<RollupSpec>();
        
        //total all time / this year / last year / two years ago
        RollupSpec rs = new RollupSpec('Allocation__c', 'General_Accounting_Unit__c');
        rs.filter = 'Opportunity__r.IsWon = TRUE AND Opportunity__r.IsClosed = TRUE ';
        //add built out exclusions to query
        rs.filter += strExcludeOppRecTypesQuery + strExcludeOppTypesQuery;
        rs.aggregateToParentFieldnameMap = new map<string, string> {
            'SUM(Amount__c)' => 'Total_Allocations__c',
            'COUNT_DISTINCT(ID)' => 'Total_Number_of_Allocations__c',
            'MIN(Amount__c)' => 'Smallest_Allocation__c',
            'MAX(Amount__c)' => 'Largest_Allocation__c',
            'AVG(Amount__c)' => 'Average_Allocation__c',
            'MIN(Opportunity__r.CloseDate)' => 'First_Allocation_Date__c',
            'MAX(Opportunity__r.CloseDate)' => 'Last_Allocation_Date__c'
        };
        
        rs.subgroupExpression = strFiscalOrCalendarYear+'(Opportunity__r.CloseDate)';
        rs.subgroupValueToParentFieldnameMap = new map<string, map<object, string>> {
            'SUM(Amount__c)' => new map<object, string> { 
                System.Today().Year() => 'Total_Allocations_This_Year__c', 
                System.Today().AddYears(-1).Year() => 'Total_Allocations_Last_Year__c',
                System.Today().AddYears(-2).Year() => 'Total_Allocations_Two_Years_Ago__c'
            },
            'COUNT_DISTINCT(ID)' => new map<object, string> { 
                System.Today().Year() => 'Number_of_Allocations_This_Year__c', 
                System.Today().AddYears(-1).Year() => 'Number_of_Allocations_Last_Year__c',
                System.Today().AddYears(-2).Year() => 'Number_of_Allocations_Two_Years_Ago__c'
            }
        };

        if (ALLO_Multicurrency_TDTM.isMultiCurrency())
            rs.additionalQueryFields.add('CurrencyIsoCode');

        mySpecs.add(rs);

        //last 365 days
        RollupSpec rs2 = new RollupSpec('Allocation__c', 'General_Accounting_Unit__c');
        rs2.filter = 'Opportunity__r.IsWon = TRUE AND Opportunity__r.IsClosed = TRUE AND Opportunity__r.CloseDate = LAST_N_DAYS:' + alloSettings.Rollup_N_Day_Value__c.intValue() + ' ';
        rs2.filter += strExcludeOppRecTypesQuery + strExcludeOppTypesQuery;
        rs2.aggregateToParentFieldnameMap = new map<string, string> {
            'SUM(Amount__c)' => 'Total_Allocations_Last_N_Days__c',
            'COUNT_DISTINCT(ID)' => 'Number_of_Allocations_Last_N_Days__c'
        };


        if (ALLO_Multicurrency_TDTM.isMultiCurrency())
            rs.additionalQueryFields.add('CurrencyIsoCode');

        mySpecs.add(rs2);
        
        return mySpecs;
    }

    //converts a semicolon delimited string, e.g. str1;str2;str3, into a SOQL friendly list format, e.g. ('str1','str2','str3')
    public static string convertToQueryListFormat(string str) {
        string results = '(\'';

        for (string s : new set<string>(str.split(';'))) {
            results += s + '\',\'';
        }
        //remove trailing quote and comma, close parenthesis
        results = results.subString(0,results.length()-2);
        results += ') ';

        return results;
    }

    /*public virtual override void finish(Database.BatchableContext bc) {
        system.debug('running finish method in extended class ALLO_Rollup_SCHED');
    }*/

    public override void customResultRowProcessing(SObject rollupRow,RollupSpec spec,SObject parentRec) {
        // this is called for each non-subgroup row of our aggregate result to allow for custom calculation of rollup values
        // you should write code here to insert values into the parent obj in parentRec
        // you must also make sure that any fields you're writing to are contained in specialRollupFields property of the spec
        if (ALLO_Multicurrency_TDTM.isMultiCurrency()) {
           parentRec.put('Total_Allocations__c', ALLO_Multicurrency_TDTM.ConvertFromCorporate((string)parentRec.get('CurrencyIsoCode'),(decimal)rollupRow.get('Total_Allocations__c')));
           parentRec.put('Total_Allocations_This_Year__c', ALLO_Multicurrency_TDTM.ConvertFromCorporate((string)parentRec.get('CurrencyIsoCode'),(decimal)rollupRow.get('Total_Allocations_This_Year__c')));
           parentRec.put('Total_Allocations_Last_Year__c', ALLO_Multicurrency_TDTM.ConvertFromCorporate((string)parentRec.get('CurrencyIsoCode'),(decimal)rollupRow.get('Total_Allocations_Last_Year__c')));
           parentRec.put('Total_Allocations_Two_Years_Ago__c', ALLO_Multicurrency_TDTM.ConvertFromCorporate((string)parentRec.get('CurrencyIsoCode'),(decimal)rollupRow.get('Total_Allocations_Two_Years_Ago__c')));
           parentRec.put('Smallest_Allocation__c', ALLO_Multicurrency_TDTM.ConvertFromCorporate((string)parentRec.get('CurrencyIsoCode'),(decimal)rollupRow.get('Smallest_Allocation__c')));
           parentRec.put('Largest_Allocation__c', ALLO_Multicurrency_TDTM.ConvertFromCorporate((string)parentRec.get('CurrencyIsoCode'),(decimal)rollupRow.get('Largest_Allocation__c')));
           parentRec.put('Average_Allocation__c', ALLO_Multicurrency_TDTM.ConvertFromCorporate((string)parentRec.get('CurrencyIsoCode'),(decimal)rollupRow.get('Average_Allocation__c')));
        }
    }
}