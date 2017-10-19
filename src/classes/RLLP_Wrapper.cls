/* ======================================================================================================= */
/* **************                   THIS CLASS WILL BE REPLACED WITH A TBD CLASS            ************** */
/* ======================================================================================================= */
public class RLLP_Wrapper {
    public RLLP_Definition definition;
    public List<RLLP_Operation> operations = new List<RLLP_Operation>();
    public Map<Schema.SObjectType, List<RLLP_Exclusion>> exclusions = new Map<Schema.SObjectType, List<RLLP_Exclusion>>();

    public Map<Id, RLLP_Engine> summaries = new Map<Id, RLLP_Engine>();

    public RLLP_Wrapper(RLLP_Definition definition) {
        this.definition = definition;
    }

    public Boolean isExcluded(SObject detail) {
        SObjectType objType = detail.getSObjectType();
        if (exclusions.containsKey(objType)) {
            for (RLLP_Exclusion exclusion : exclusions.get(objType)) {
                if (exclusion.isExcluded(detail)) {
                    system.debug('njjc Excluded! ' + exclusion.field + ' ' + exclusion.operation + ' ' + exclusion.constant);
                    return true;
                }
            }
        }
        return false;
    }

    public void processDetail(SObject detail, Date closeDate, Double amount) {
        
        if (isExcluded(detail)) {
            return;
        }
        for (Id attributionId : getAttributionsNotExcluded(detail)) {
            addToSummary(attributionId, detail, closeDate, amount);
        }
    }

    public List<Id> getAttributionsNotExcluded(SObject detail) {
        List<Id> results = new List<Id>();
        //no attribution object, just use the lookup on the detail
        if (definition.attributionObject==null) {
            Id attributionId = (Id)detail.get(definition.attributionField);
            if (attributionId != null) {
                results.add(attributionId);
            }

        } else {
            //look at each attribution object, checking if any are excluded
            for (SObject attributionRecord : detail.getSObjects(definition.attributionRelationshipName)) {
                if (!isExcluded(attributionRecord)) {
                    Id attributionId = (Id)attributionRecord.get(definition.attributionField);
                    if (attributionId != null) {
                        results.add(attributionId);
                    }
                }
            }
        }
        return results;
    }

    public void addToSummary(Id attributionId, SObject detail, Date closeDate, Double amount) {
        if (attributionId == null) {
            return;
        }

        if (!this.summaries.containsKey(attributionId)) {
            this.summaries.put(attributionId, new RLLP_Engine(this.operations));
        }
        this.summaries.get(attributionId).process(detail, closeDate, amount);
    }
}