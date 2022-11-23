/**
 * Created by voduyemi on 8/17/22.
 */

/**
* @description Handles sending commitment create and edit requests
*/
public without sharing class RD2_CommitmentService {

    /**
    * @description Sends commitment create/update requests, and constructs a response
    */
    private UTIL_Http.RequestService requestService {
        get {
            if (requestService == null) {
                requestService = new UTIL_Http.RequestService();
            }
            return requestService;
        }
        set;
    }

    /**
    * Used to adjust and validate Recurring Donation data
    */
    private RD2_DataRegulationService dataService {
        get {
            if (dataService == null) {
                dataService = new RD2_DataRegulationService();
            }
            return dataService;
        }
        set;
    }

    /**
    * @description Handles validation and Elevate recurring commitment creation
    * @param rd Recurring Donation
    * @param oldRd oldRecurring Donation
    * @param paymentMethodToken Payment Method Token
    * @return UTIL_Http.Response Payments API response
    */
    public UTIL_Http.Response handleCommitment(npe03__Recurring_Donation__c rd, npe03__Recurring_Donation__c oldRd, String paymentMethodToken) {
        UTIL_Http.Response response;

        if (shouldSendToElevate(rd, oldRd, paymentMethodToken)) {
            PS_CommitmentRequest.RequestBody requestBody = new PS_CommitmentRequest().getRequestBody(rd, oldRd, paymentMethodToken);

            UTIL_Http.Method method = String.isBlank(rd.CommitmentId__c)
                    ? UTIL_Http.Method.POST
                    : UTIL_Http.Method.PATCH;

            response = sendRequest(rd.CommitmentId__c, JSON.serialize(requestBody),
                PS_Request.ElevateEndpoint.COMMITMENT, method);

            processResponse(rd, response);
        }

        return response;
    }

    public UTIL_Http.Response handleCommitmentPause(RD2_ScheduleService.ElevatePauseSchedule schedule, RD2_RecurringDonation rd) {
        UTIL_Http.Response response;

        PS_CommitmentRequest.PauseRequestBody requestBody = new PS_CommitmentRequest().getPauseRequestBody(schedule);

        UTIL_Http.Method method = schedule.shouldEditPause ? UTIL_Http.Method.PATCH : UTIL_Http.Method.POST;

        response = sendRequest(rd.getSObject()?.CommitmentId__c, JSON.serialize(requestBody),
            PS_Request.ElevateEndpoint.COMMITMENT_PAUSE, method);

        processResponse(rd, response);

        return response;
    }

    public UTIL_Http.Response handleRemoveCommitmentPause(RD2_RecurringDonation rd) {
        UTIL_Http.Response response;

        response = sendDeleteRequest(rd.getSObject()?.CommitmentId__c, PS_Request.ElevateEndpoint.COMMITMENT_PAUSE);

        processResponse(rd, response);

        return response;
    }


    /**
    * @description Constructs Recurring Donation record from received fields specified in the JSON string,
    * updates defaults that are otherwise updated in the trigger context, and
    * validates user entered values for a new or existing RD record.
    * @param rd Modified Recurring Donation record that is not created/updated in DB yet
    * @param oldRd oldRecurring Donation
    */
    public void adjustAndValidateRD(npe03__Recurring_Donation__c rd, npe03__Recurring_Donation__c oldRd) {
        // Populate defaults otherwise applied by the DML operation and available in the trigger context
        if (String.isBlank(rd.Status__c)) {
            rd.Status__c = UTIL_Describe.getDefaultSelectOption(
                'npe03__Recurring_Donation__c', String.valueOf(npe03__Recurring_Donation__c.Status__c)
            );
        }

        List<npe03__Recurring_Donation__c> newRds = new List<npe03__Recurring_Donation__c>{rd};
        List<npe03__Recurring_Donation__c> oldRds = new List<npe03__Recurring_Donation__c>();
        if (rd.Id != null) {
            oldRds.add(oldRd);
        }

        RD2_DataRegulationService regulationService = new RD2_DataRegulationService();
        regulationService.adjust(newRds, oldRds);
        regulationService.markRDsAsElevate(newRds);

        List<ErrorRecord> errorRds = new RD2_ValidationService(newRds, oldRds)
            .validate();

        regulationService.removeElevateMarker(newRds);

        if (!errorRds.isEmpty()) {
            UTIL_AuraEnabledCommon.throwAuraHandledException(
                errorRds[0].getFirstError()
            );
        }
    }

    /**
    * @description Checks if the commitment record should be sent to Elevate
    * @param rd Recurring Donation record
    * @param oldRd oldRecurring Donation
    * @param paymentMethodToken Token for Elevate requests
    * @return Boolean
    */
    private Boolean shouldSendToElevate(npe03__Recurring_Donation__c rd, npe03__Recurring_Donation__c oldRd, String paymentMethodToken) {
        if(new RD2_RecurringDonation(rd).isClosed()) {
            return false;
        }
        PS_CommitmentRequest request = new PS_CommitmentRequest();
        Boolean isElevatedFieldsChanged = request.isElevateScheduleFieldsChanged(rd, oldRd)
            || request.isElevateCampaignChanged(rd, oldRd);


        return rd.Id == null
            || (isElevatedFieldsChanged && rd.CommitmentId__c != null)
            || String.isNotBlank(paymentMethodToken);
    }

    /**
    * @description Sends commitment request to Elevate
    * @param commitmentId Elevate recurring commitment Id
    * @param jsonRequestBody Payment API request in JSON format
    * @return response Payments API response
    */
    private UTIL_Http.Response sendRequest(String commitmentId, String jsonRequestBody,
        PS_Request.ElevateEndpoint endpoint, UTIL_Http.Method method) {
        UTIL_Http.Response response;

        try {
            HttpRequest request = PS_CommitmentRequest.buildRequest(commitmentId, jsonRequestBody,
                endpoint, method);
            response = requestService.sendRequest(request);

        } catch (Exception ex) {
            response = requestService.buildErrorResponse(ex);
        }

        return response;
    }

    private UTIL_Http.Response sendDeleteRequest(String commitmentId, PS_Request.ElevateEndpoint endpoint) {
        UTIL_Http.Response response;

        try {
            HttpRequest request = PS_CommitmentRequest.buildRequest(commitmentId,
                UTIL_Http.Method.DEL, endpoint);
            response = requestService.sendRequest(request);
        } catch (Exception ex) {
            response = requestService.buildErrorResponse(ex);
        }

        return response;
    }

    /**
    * @description Logs an error record on an commitment error response
    * @param rd Recurring Donation record
    * @param response Payments API response
    */
    private void processResponse(npe03__Recurring_Donation__c rd, UTIL_Http.Response response) {
        if (isCommitmentSuccess(response)) {
            return;
        }

        logError(getRecordId(rd), response.getErrorMessages());
    }

    private Id getRecordId(npe03__Recurring_Donation__c rd) {
        Id recordId = rd.Id != null
            ? rd.Id
            : rd.npe03__Contact__c != null
                ? rd.npe03__Contact__c
                : rd.npe03__Organization__c;
        return recordId;
    }

    /**
* @description Logs an error record on an commitment error response
* @param rd Recurring Donation record
* @param response Payments API response
*/
    private void processResponse(RD2_RecurringDonation donation, UTIL_Http.Response response) {
        if (isCommitmentSuccess(response)) {
            return;
        }

        logError(getRecordId(donation.getSObject()), response.getErrorMessages());
    }

    /**
    * @description Determines if the commitment has been created or updated successfully
    * @param response Payments API response
    * @return Boolean
    */
    public Boolean isCommitmentSuccess(UTIL_Http.Response response) {
        return response.statusCode == UTIL_Http.STATUS_CODE_CREATED
            || response.statusCode == UTIL_Http.STATUS_CODE_OK
            || response.statusCode == UTIL_Http.STATUS_CODE_NO_CONTENT;
    }

    /**
    * @description Creates an error record for the specified record Id and error message
    * @param recordId A Recurring Donation or a donor (Contact/Account) Id
    * @param errorMessage Error message
    */
    public void logError(Id recordId, String errorMessage) {
        ERR_LogService.Logger logger = new ERR_LogService.Logger(
            ERR_Handler_API.Context.Elevate,
            npe03__Recurring_Donation__c.SObjectType
        );

        String errorType = (recordId.getSobjectType() == Schema.npe03__Recurring_Donation__c.getSObjectType())
            ? RD2_ElevateIntegrationService.LOG_TYPE_COMMITMENT_EDIT
            : RD2_ElevateIntegrationService.LOG_TYPE_COMMITMENT_CREATE;

        logger.addError(recordId, errorMessage, errorType);

        logger.processErrors();
    }
}