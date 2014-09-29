global class ALLO_MakeDefaultAllocations_BATCH implements Database.Batchable<sObject> {
    

/*
verify settings are enabled?
*/

    private Allocations_Settings__c alloSettings = UTIL_CustomSettingsFacade.getAllocationsSettings();
    private String query = 'SELECT Id, Amount FROM Opportunity';
    
    global ALLO_MakeDefaultAllocations_BATCH() {
        string strExcludeOppRecTypesQuery = '';
        string strExcludeOppTypesQuery = '';

        //build string of opp record type names for query
        if (alloSettings.Excluded_Opp_RecTypes__c != null) {
            strExcludeOppRecTypesQuery = ' WHERE RecordType.Name NOT IN ' + ALLO_Rollup_SCHED.convertToQueryListFormat(alloSettings.Excluded_Opp_Rectypes__c);
        }

        //build string of opp types for query
        if (alloSettings.Excluded_Opp_Types__c != null) {
            if (alloSettings.Excluded_Opp_RecTypes__c != null)
                strExcludeOppTypesQuery = ' AND ';
            else 
                strExcludeOppTypesQuery = ' WHERE ';
            strExcludeOppTypesQuery += ' Type NOT IN ' + ALLO_Rollup_SCHED.convertToQueryListFormat(alloSettings.Excluded_Opp_Types__c);
        }

        query += strExcludeOppRecTypesQuery + strExcludeOppTypesQuery;
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope) {

        list<Opportunity> listOpps = (list<Opportunity>) scope;

        map<id,Opportunity> mapIdOpp = new map<id,Opportunity>();
        map<id,list<Allocation__c>> mapOppIdAllo = new map<id,list<Allocation__c>>();
        list<Allocation__c> listAlloForInsert = new list<Allocation__c>();
        list<Allocation__c> listAlloForUpdate = new list<Allocation__c>();

        for (Opportunity opp : listOpps) {
            mapIdOpp.put(opp.id, opp);
        }

        for (Allocation__c allo : [SELECT Id, General_Accounting_Unit__c, Opportunity__c, Amount__c FROM Allocation__c WHERE Opportunity__c IN :mapIdOpp.keySet()]) {
            if (!mapOppIdAllo.containsKey(allo.Opportunity__c)) 
                mapOppIdAllo.put(allo.Opportunity__c, new list<Allocation__c>());

            mapOppIdAllo.get(allo.Opportunity__c).add(allo);
        }

        for (Opportunity opp : listOpps) {
            //if we have allocations for this opp, create or update the default
            if (mapOppIdAllo.containsKey(opp.id)) {
                decimal remainder = opp.Amount;
                Allocation__c defaultAllo = new Allocation__c();

                for (Allocation__c allo : mapOppIdAllo.get(opp.id)) {
                    if (alloSettings.Default_Allocations_Enabled__c && allo.General_Accounting_Unit__c == alloSettings.Default__c)
                        defaultAllo = allo;
                    else
                        remainder -= allo.Amount__c;
                }

                if (remainder > 0) {
                    if (defaultAllo.id!=null && defaultAllo.Amount__c!=remainder) {
                        defaultAllo.Amount__c = remainder;
                        listAlloForUpdate.add(defaultAllo);
                    } else if (defaultAllo.id==null) {
                        listAlloForInsert.add(new Allocation__c(
                            Opportunity__c = opp.id,
                            Amount__c = remainder,
                            General_Accounting_Unit__c = alloSettings.Default__c
                        ));
                    }
                }
            //if we have no allocations for this opp, create one
            } else {
                listAlloForInsert.add(new Allocation__c(
                    Opportunity__c = opp.id,
                    Amount__c = opp.Amount,
                    General_Accounting_Unit__c = alloSettings.Default__c
                ));
            }
        }

        if (!listAlloForInsert.isEmpty()) {
            ALLO_Allocations_TDTM.resetFlags(true);
            insert listAlloForInsert;
        }
        if (!listAlloForUpdate.isEmpty()) {
            ALLO_Allocations_TDTM.resetFlags(true);
            update listAlloForUpdate;
        }
    }
    
    global void finish(Database.BatchableContext BC) {}
    
}