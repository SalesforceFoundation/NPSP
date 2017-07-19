public with sharing abstract class RLLP_Definition {
    public Schema.SObjectType summaryObject;       //Contact or Account
    public Schema.SObjectType detailObject;        //Opportunity and Payment
    public Schema.SObjectType attributionObject;   //OCR, PSC, or null for direct attribution e.g. opp.Account field
                                            //this depends on the Summary object; if that is for contact, then it can also be soft credit
    public Schema.SObjectField attributionId;
    public Schema.SObjectField amountField;       //use list here eventually so we can climb cross object references
    public Schema.SObjectField closeDateField;    //e.g. allocation date is on opportunity object
    
    public interface IExclusion {
        Boolean isExcluded(SObject detail);
    }

    public class OperationWrapper {
        public IExclusion exclusion;
        public List<RLLP_Operation> operations = new List<RLLP_Operation>();
        public List<RLLP_Exclusion> exclusions = new List<RLLP_Exclusion>();

        public Map<Id, RLLP_Engine> summaries = new Map<Id, RLLP_Engine>();
        
        public OperationWrapper(IExclusion exclusion) {
            this.exclusion = exclusion;
        }

        public Boolean isExcluded(SObject detail) {
            for (RLLP_Exclusion exclusion : this.exclusions) {
                if (exclusion.isExcluded(detail)) {
                    return true;
                }
            }
            return false;
        }
    }
    public List<OperationWrapper> wrappers = new List<OperationWrapper>();

    public Set<String> summaryFields;
    public Set<String> detailFields;

    //parses wrappers to get sets of fields
    public void populateFields() {
        summaryFields = new Set<String>();
        detailFields = new Set<String>();

        detailFields.add(amountField.getDescribe().getName());
        detailFields.add(closeDateField.getDescribe().getName());

        //no attribution object means that the lookup to the summary field is on the attribution object
        if (attributionObject == null) {
            detailFields.add(attributionId.getDescribe().getName());
        }
        //TODO: get detail fields from exclusions, the next line is a hack
        detailFields.add('Type');
        detailFields.add('RecordTypeId');

        for (OperationWrapper wrapper : wrappers) {
            for (RLLP_Operation operation : wrapper.operations) {
                summaryFields.add(operation.destinationField.getDescribe().getName());
                
                if (operation.resultField != null) {
                    detailFields.add(operation.resultField.getDescribe().getName());
                }
            }
        }
    }

    //get detail query, e.g. opps or payments
    public String getDetailQuery() {
        if (detailFields == null) {
            populateFields();
        }
        String query = 'SELECT ';
        query += (String)String.join(new List<String>(detailFields), ', ');
        if (attributionObject != null) {
            query += ', (SELECT ' + attributionId + ' FROM ' + attributionRelationshipName + ')';
        }
        query += ' FROM ' + detailObject.getDescribe().getName();
        return query;
    }

    //get summary object query, e.g. contacts and accounts
    public String getSummaryQuery() {
        if (summaryFields == null) {
            populateFields();
        }
        String query = 'SELECT ';
        query += String.join(new List<String>(summaryFields), ', ');
        query += ' FROM ' + summaryObject.getDescribe().getName();
        return query;
    }

    public void processDetails(List<SObject> details) {
        for (SObject detail : details) {
            Date closeDate = getCloseDate(detail);
            Double amount = getAmount(detail);
            List<Id> attributionIds = getAttribution(detail);

            for (OperationWrapper wrapper : wrappers) {
                //skip if excluded
                if (wrapper.isExcluded(detail)) {
                    continue;
                } else {
                    //for each attribution, instantiate summary and add record to summary
                    for (Id attributionId : attributionIds) {
                        //instantiate summary
                        if (!wrapper.summaries.containsKey(attributionId)) {
                            wrapper.summaries.put(attributionId, new RLLP_Engine(wrapper.operations));
                        }
                        wrapper.summaries.get(attributionId).process(detail, closeDate, amount);
                    }
                }
            }
        }
    }

    //returns all the results from the summary objects
    //TODO: implement a comparison with existing rollup numbers to only update when needed; 
    //remember all to set all 0s if the record doesn't exist in the results, as only summary records exist if there are details for that record
    //TODO: ensure that update logic allows partial success
    public List<SObject> getResults() {
        Map<Id, SObject> results = new Map<Id, SObject>();
        for (OperationWrapper wrapper : wrappers) {
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
    private String attributionRelationshipName {
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

    public List<Id> getAttribution(SObject detail) {
        List<Id> results = new List<Id>();
        if (attributionObject!=null) {
            for (SObject attributionRecords : detail.getSObjects(attributionRelationshipName)) {
                results.add((Id)attributionRecords.get(attributionId)); //TODO: check any user defined filters on the attribution object
            }
        } else {
            results.add((Id)detail.get(attributionId));
        }
        return results;
    }

    public Date getCloseDate(SObject detail) {
        return (Date)detail.get(closeDateField);
    }

    public Double getAmount(SObject detail){ 
        //TODO: handle advanced multicurrency
        return (Double)detail.get(amountField);
    }
}