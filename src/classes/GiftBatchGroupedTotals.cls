public inherited sharing class GiftBatchGroupedTotals {

    private Map<Id, GiftBatchTotals> giftBatchTotalsByBatchId = new Map<Id, GiftBatchTotals>();

    public Map<String, Integer> totalsFor(Id batchId) {
        guardNoBatchTotalsFor(batchId);
        return giftBatchTotalsByBatchId.get(batchId).toMap();
    }

    public GiftBatchGroupedTotals(List<AggregateResultProxy> results) {
        Map<Id, List<AggregateResultProxy>> queryResultsByBatchId = groupQueryResultsByBatchId(results);

        for (Id batchId : queryResultsByBatchId.keySet()) {
            List<AggregateResultProxy> queryResults = queryResultsByBatchId.get(batchId);
            giftBatchTotalsByBatchId.put(batchId, new GiftBatchTotals(queryResults));
        }
    }

    private Map<Id, List<AggregateResultProxy>> groupQueryResultsByBatchId(List<AggregateResultProxy> results) {
        Map<Id, List<AggregateResultProxy>> queryResultsByBatchId = new Map<Id, List<AggregateResultProxy>>();
        for(AggregateResultProxy queryResultProxy : results) {
            addTo(queryResultsByBatchId, queryResultProxy);
        }
        return queryResultsByBatchId;
    }

    private void addTo(
        Map<Id, List<AggregateResultProxy>> queryResultsByBatchId,
        AggregateResultProxy queryResultProxy) {

        Id batchId = (Id) queryResultProxy
            .getValuesByAlias()
            .get(String.valueOf(DataImport__c.fields.NPSP_Data_Import_Batch__c));
        List<AggregateResultProxy> queryResultProxies = queryResultsByBatchId.get(batchId);
        if (queryResultProxies == null) {
            queryResultsByBatchId.put(batchId, new List<AggregateResultProxy> { queryResultProxy });
        } else {
            queryResultProxies.add(queryResultProxy);
        }
    }

    private void guardNoBatchTotalsFor(Id batchId) {
        if (giftBatchTotalsByBatchId.get(batchId) == null) {
            throw new GiftBatchGroupedTotalsException('No gift batch totals found for ' + batchId);
        }
    }

    public class GiftBatchGroupedTotalsException extends Exception {}
}
