@RestResource(urlMapping='/pkbanding')
global with sharing class pkBandingService {

    // consts
    public static final String ERR_CLASS_NAME = 'PKBanding_REST:';
    public static final Integer HTTP_SUCCESS = 200;
    public static final Integer HTTP_FORBIDDEN = 403;
    // attrs
    Integer recordCount = 0;
    Integer failCount = 0;
    List<String> failedList = new List<String>();

    @HttpPost
    global static void pkbanding() {

        // set default response
        RestResponse response = RestContext.response;
        response.statusCode = HTTP_SUCCESS;

        // aux vars
        Cursor request;
        dispatcherResponse dResponse = new dispatcherResponse();
        SObject[] events;

        // class vars
        Integer band;
        SObject auxEvent;
        Integer numberOfEvents;
        Integer eventLimit;
        String lastOffset;
        Boolean completed = false;

        try {

            // deserialize payload
            request = (Cursor) JSON.deserialize(
                    RestContext.request.requestBody.toString(),
                    Cursor.class
            );

            // init class attributes
            numberOfEvents = 0;
            band = request.band;
            eventLimit = request.batchSize;
            lastOffset = request.offset;

            // init response
            dResponse.init(request);

            // init events
            UTIL_pkBanding pkb = new UTIL_pkBanding();
            pkb.resp = dResponse;
            events = pkb.getNextBatch();
            dResponse = pkb.resp;

            // fire if we have events to process
            if (numberOfEvents>0) {

                // fire event handler
                Integer recordsProcessed = events.size();
                // disable rollups
                TDTM_Config_API.disableAllRollupTriggers();
                // execute RD service
                RD2_OpportunityEvaluationService evalService = new RD2_OpportunityEvaluationService()
                                                                    .withBatchContext()
                                                                    .withRds(UTIL_SObject.extractIds(events))
                                                                    .withCurrentDate(Date.Today())
                                                                    .evaluateOpportunities();
                // todo: maybe get ids to replay
                Integer recordsFailed = evalService.getRecordsFailed();

            }

        } catch (Exception e) {

            // update response object
            dResponse.cursor.offset = lastOffset;
            dResponse.numberProcessed = numberOfEvents;
            dResponse.result = false;
            dResponse.error =  ERR_CLASS_NAME + e.getMessage();
            response.responseBody = Blob.valueOf(JSON.serialize(dResponse));
            return;
        }

        // service response
        response.responseBody = Blob.valueOf(JSON.serialize(dResponse));
    }

    public class dispatcherResponse {
        public Boolean result;
        public String error;
        public Integer numberProcessed;
        public Boolean completed; // consumed all records in band
        public Cursor cursor = new Cursor();

        public void init(Cursor request) {
            cursor = request;
            result = true;
            completed = false;
            numberProcessed = 0;
            error = '';
        }
    }
    public class Cursor {
        public Integer band; // same as shard/subshard in TL
        public Integer partitionBits; // Not yet used (currently 3 bits - 8 bands)
        public Integer chunkBits; // Not yet used (currently ~14.90839 bits - 30752 recs/chunk)
        public Integer batchSize; // Max number of records to pull
        public Boolean sparse; // Will be true if last chunk in band was empty
        public String offset; // Last Id queried (not necessarily processed)
        public String url;
        public String session;
    }

}