public with sharing class ALLO_ManageAllocations_CTRL {

	public list<Allocation__c> listAllo {
        get{
            if (listAllo == null) {
                listAllo = [SELECT Id, Name, Amount__c, Percent__c, General_Accounting_Unit__c FROM Allocation__c WHERE Opportunity__c = :parentId OR Campaign__c = :parentId OR Recurring_Donation__c = :parentId];
                if (listAllo.isEmpty())
                    addRow();
            }
            return listAllo;
        }
        set;
    }
    public list<Allocation__c> listAlloForDelete = new list<Allocation__c>();

    public id parentId {get;set;}
    public Opportunity opp {get;set;}
    public Campaign cam {get;set;}
    public npe03__Recurring_Donation__c rd {get;set;}
    public decimal parentAmount {get;set;}

    public string parentName {get;set;}

    //row number sent back by page for add and delete row methods
    public integer rowNumber {get;set;}

    public pageReference addRow() {
        Allocation__c allo = new Allocation__c();

        if (opp!=null)
            allo.Opportunity__c = parentId;
        else if (cam!=null)
            allo.Campaign__c = parentId;
        else if (rd!=null)
            allo.Recurring_Donation__c = parentId;

        //enable adding to the last row
        if (rowNumber == null || rowNumber == listAllo.size() - 1)
            listAllo.add(allo);
        else
            listAllo.add(rowNumber+1, allo);
        return null;
    }

    public pageReference delRow() {
        //add to deletion list if the allocation has an id
        if (listAllo[rowNumber].id!=null)
            listAlloForDelete.add(listAllo[rowNumber]);
        listAllo.remove(rowNumber);
        return null;
    }


    public pageReference saveClose() {
        try {
            if (!listAlloForDelete.isEmpty())
                delete listAlloForDelete;
            upsert listAllo;
            pageReference source = new pageReference('/'+parentId);
            return source;
        } catch (Exception e) {
            ApexPages.addMessages(e);
            return null;
        }
    }

    public pageReference cancel() {
        pageReference source = new pageReference('/'+parentId);
        return source;
    }

    //constructor finds parent object, queries it, and sets parentId and parentAmount if possible
    public ALLO_ManageAllocations_CTRL() {
        map<string,string> params = ApexPages.currentPage().getParameters();
        parentAmount = 0;        
        if (params.containsKey('opp')) {
            parentId = String.escapeSingleQuotes(params.get('opp'));
            opp = (Opportunity) getSObject(parentId, Schema.SObjectType.Opportunity);
            //only Opportunities have parent amounts and enforce being below this amount
            parentAmount = opp.Amount;
        } else if (params.containsKey('cam')) {
            parentId = String.escapeSingleQuotes(params.get('cam'));
            cam = (Campaign) getSObject(parentId, Schema.SObjectType.Campaign);
        } else if (params.containsKey('rd')) {
            parentId = string.escapeSingleQuotes(params.get('rd'));
            rd = (npe03__Recurring_Donation__c) getSObject(parentId, Schema.SObjectType.npe03__Recurring_Donation__c);
        }

    }

    //queries all fields for a generic sObject
    public sObject getSObject (id objId, DescribeSObjectResult objResult) {
        Map<String, Schema.SObjectField> fieldMap = objResult.fields.getMap();
        list<String> fields = new list<String>();
        fields.addAll(fieldMap.keySet());
        String objQuery = 'SELECT ';
        Integer i = 1;
        for (String fld : fields) {
            objQuery += fld;
            if (i != fields.size()) objQuery += ', ';
            i += 1;
        }
        objQuery += ' FROM ' + objResult.getName() + ' WHERE Id = \''+objId+'\'';
        sObject result = database.query(objQuery);
        return result;
    }

}