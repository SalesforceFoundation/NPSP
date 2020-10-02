public inherited sharing class CRLP_PlatformCache {    

    // ====================================================================
    // CACHEBUILDER CLASS TO MANAGE RETRIEVING/PUTTING ELEMENTS INTO THE CACHE
    // ====================================================================

    /**
     * @description CacheBuilder implementation to retrieve/load TriggerHandler__c records.
     * CacheBuilder is smart enough to use the values in the cache if they exist and if not it will call the
     * code witin the doLoad() method below to retrieve the values and then store them in the cache so they're
     * available on the next call.
     * The string param in the doLoad() method is not used in the TriggerHandlerCache implementation, but is required
     * by CacheBuilder.
     */
    public class RollupDefinitionsCache implements Cache.CacheBuilder {
        public List<Rollup__mdt> doLoad(String dummyParam) {
            return CRLP_Rollup_SEL.queryRollupRecords();
        }
    }

    /**
     * @description CacheBuilder implementation to retrieve/load TriggerHandler__c records.
     */
    public class RollupFilterGroupsCache implements Cache.CacheBuilder {
        public List<Filter_Group__mdt> doLoad(String dummyParam) {
            return new List<Filter_Group__mdt>();
        }
    }

    /**
     * @description CacheBuilder implementation to retrieve/load TriggerHandler__c records.
     */
    public class RollupFilterRulesCache implements Cache.CacheBuilder {
        public List<Filter_Rule__mdt> doLoad(String dummyParam) {
            return new List<Filter_Rule__mdt>();
        }
    }
}
