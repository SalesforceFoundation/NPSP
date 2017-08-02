public with sharing abstract class RLLP_Definition {
    public Schema.SObjectType summaryObject;       //Contact or Account
    public Schema.SObjectType detailObject;        //Opportunity and Payment; TODO: special case payment for generating query and parsing everything
    public Schema.SObjectType attributionObject;   //OCR, PSC, or null for direct attribution e.g. opp.Account field

                                            //this depends on the Summary object; if that is for contact, then it can also be soft credit

    public Schema.SObjectField attributionField;
    public Schema.SObjectField amountField;       //use list here eventually so we can climb cross object references
    public Schema.SObjectField closeDateField;    //e.g. allocation date is on opportunity object
    

    public List<RLLP_Wrapper> wrappers = new List<RLLP_Wrapper>();

    public Map<Schema.SObjectType, Set<String>> queryFields = new Map<Schema.SObjectType, Set<String>>();

    //parses wrappers to get all fields for generating queries
    public void populateQueryFields() {
        queryFields.put(summaryObject, new Set<String>());
        queryFields.put(detailObject, new Set<String>());

        queryFields.get(detailObject).add(amountField.getDescribe().getName());
        queryFields.get(detailObject).add(closeDateField.getDescribe().getName());

        //no attribution object means that the lookup to the summary field is on the attribution object
        if (attributionObject == null) {
            queryFields.get(detailObject).add(attributionField.getDescribe().getName());
        } else {
            queryFields.put(attributionObject, new Set<String>());
            queryFields.get(attributionObject).add(attributionField.getDescribe().getName());
        }

        //process operations and exclusions to parse out fields for query
        for (RLLP_Wrapper wrapper : wrappers) {
            for (RLLP_Operation operation : wrapper.operations) {
                queryFields.get(summaryObject).add(operation.destinationField.getDescribe().getName());
                
                if (operation.resultField != null) {
                    queryFields.get(detailObject).add(operation.resultField.getDescribe().getName());
                }
            }
            for (Schema.SObjectType objType : wrapper.exclusions.keySet()) {
                for (RLLP_Exclusion exclusion : wrapper.exclusions.get(objType)) {
                    if (!queryFields.containsKey(objType)) {
                        queryFields.put(objType, new Set<String>());
                    }
                    queryFields.get(objType).add(exclusion.field.getDescribe().getName());
                }
            }
        }
    }

    //get detail query, e.g. opps or payments
    public String getDetailQuery() {
        if (queryFields.isEmpty()) {
            populateQueryFields();
        }
        String query = 'SELECT ';
        query += (String)String.join(new List<String>(queryFields.get(detailObject)), ', ');
        if (attributionObject != null) {
            query += ', (SELECT ' + (String)String.join(new List<String>(queryFields.get(attributionObject)), ', ') + ' FROM ' + attributionRelationshipName + ')';
        }
        query += ' FROM ' + detailObject.getDescribe().getName();
        return query;
    }

    //get summary object query, e.g. contacts and accounts
    public String getSummaryQuery() {
        if (queryFields.isEmpty()) {
            populateQueryFields();
        }
        String query = 'SELECT ';
        query += String.join(new List<String>(queryFields.get(summaryObject)), ', ');
        query += ' FROM ' + summaryObject.getDescribe().getName();
        return query;
    }

    public void processDetails(List<SObject> details) {
        for (SObject detail : details) {
            Date closeDate = getCloseDate(detail);
            Double amount = getAmount(detail);
            System.debug('njjc processing details' + detail);

            for (RLLP_Wrapper wrapper : wrappers) {
                wrapper.processDetail(detail, closeDate, amount);
            }
        }
    }

    //returns all the results from the summary objects
    //TODO: implement a comparison with existing rollup numbers to only update when needed; 
    //remember all to set all 0s if the record doesn't exist in the results, as only summary records exist if there are details for that record
    //TODO: ensure that update logic allows partial success
    public List<SObject> getResults() {
        Map<Id, SObject> results = new Map<Id, SObject>();
        for (RLLP_Wrapper wrapper : wrappers) {
            for (Id resultId : wrapper.summaries.keySet()) {
                if (!results.containsKey(resultId)) {
                    results.put(resultId, summaryObject.newSObject(resultId));
                }
                SObject result = results.get(resultId);
                RLLP_Engine summary = wrapper.summaries.get(resultId);
                for (RLLP_Operation operation : wrapper.operations) {
                    result.put(operation.destinationField, summary.getResult(operation));
                }
            }
        }
        return results.values();
    }

    /**
    * @description The name of the child relationship between the detail object and the attribution object.
    */
    public String attributionRelationshipName {
        get {
            if (attributionRelationshipName == null) {
                for (Schema.ChildRelationship relationship : detailObject.getDescribe().getChildRelationships()) {
                    if (relationship.getChildSObject() == attributionObject) {
                        attributionRelationshipName = relationship.getRelationshipName(); 
                    }
                }
                if (attributionRelationshipName == null) {
                    //TODO: throw exception: relationship between detail and attribution object not found
                }
            }
            return attributionRelationshipName;
        }
        set;
    }

/*    public List<Id> getAttributions(SObject detail) {
        List<Id> results = new List<Id>();
        if (attributionObject!=null) {
            for (SObject attributionRecords : detail.getSObjects(attributionRelationshipName)) {
                results.add((Id)attributionRecords.get(attributionField)); //TODO: check any user defined filters on the attribution object
            }
        } else {
            results.add((Id)detail.get(attributionField));
        }
        return results;
    }
*/
    public Date getCloseDate(SObject detail) {
        return (Date)detail.get(closeDateField);
    }

    public Double getAmount(SObject detail){ 
        //TODO: handle advanced multicurrency
        return (Double)detail.get(amountField);
    }
}