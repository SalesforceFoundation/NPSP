/*
    Copyright (c) 2020, Salesforce.org
    All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Salesforce.org nor the names of
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
* @author Salesforce.org
* @date 2020
* @group HGE
* @group-content
* @description Controller for the Gift Entry lightning web components and processing
* form save.
*/
public with sharing class GE_GiftEntryController {

    public static final Integer TIMEOUT_STATUS_CODE = 408;
    public static final String TIMED_OUT = 'timed out';
    public static final String PURCHASE_CALL_TIMEOUT_MESSAGE = System.Label.geErrorRequestTimedout;

    @AuraEnabled(cacheable=true)
    public static OrgDomainInfo getOrgDomainInfo() {
        String url = System.Url.getOrgDomainUrl().getHost();
        String[] urlParts = url.split('\\.');
        String podName = [SELECT InstanceName FROM Organization].InstanceName.toLowerCase();
        return new OrgDomainInfo (urlParts[0], podName);
    }

    /*******************************************************************************************************
    * @description Creates and posts an elevate purchase request
    *
    * @param requestBodyParameters: JSON containing parameters for the purchase call request body
    * @param dataImportRecordId: Record ID of the related Data Import
    *
    * @return String: http response wrapper
    */
    @AuraEnabled
    public static String sendPurchaseRequest(String requestBodyParameters, String dataImportRecordId) {
        try {
            GE_PaymentServices paymentServices = new GE_PaymentServices();
            paymentServices.setPurchaseCallBody(requestBodyParameters);
            GE_PaymentServices.ResponseWrapper response = paymentServices.createTransaction();

            return JSON.serialize(response);
        } catch (Exception ex) {
            Boolean isCalloutException = ex instanceof System.CalloutException;
            Boolean hasTimedOut = isCalloutException && ex.getMessage().contains(TIMED_OUT);

            if (hasTimedOut) {
                return getPurchaseCallTimeoutResponse(ex, dataImportRecordId);
            } else {
                String JSONExceptionData = ERR_ExceptionData.createExceptionWrapperJSONString(ex);
                throw returnDmlException(JSONExceptionData);
            }
        }
    }

    /*******************************************************************************************************
    * @description Creates an http request wrapper for a timeout
    *
    * @param ex: A timeout System.CalloutException
    * @param dataImportRecordId: Record ID of the related Data Import to include in our error logs
    *
    * @return String: http response wrapper
    */
    private static String getPurchaseCallTimeoutResponse(Exception ex, String dataImportRecordId) {
        GE_PaymentServices.ResponseWrapper response = new GE_PaymentServices.ResponseWrapper();
        response.statusCode = TIMEOUT_STATUS_CODE;
        response.status = ex.getMessage();
        response.body = JSON.serialize(new Map<String, String>{ 'message' => PURCHASE_CALL_TIMEOUT_MESSAGE });

        // Log NPSP Error record
        String objectAndRecordId = String.format(
            System.Label.stgErrorInvalidNameFormat,
            new String[] {
                Schema.SObjectType.DataImport__c.getLabel(),
                dataImportRecordId
            });
        ex.setMessage(PURCHASE_CALL_TIMEOUT_MESSAGE + ' ' + objectAndRecordId);
        ERR_Handler.processError(ex, ERR_Handler_API.Context.GE);

        return JSON.serialize(response);
    }

    /*******************************************************************************************************
    * @description Creates an AuraHandledException with the specified error message
    *
    * @param errorMsg contents of the exception error messagae
    *
    * @return AuraHandledException
    */
    public static AuraHandledException returnAuraException(String errorMsg) {
        AuraHandledException ex = new AuraHandledException(errorMsg);
        ex.setMessage(errorMsg);
        return ex;
    }

    /*******************************************************************************************************
    * @description Creates an DmlException with the specified error message
    *
    * @param errorMsg contents of the exception error messagae
    *
    * @return DmlException
    */
    public static DmlException returnDmlException(String errorMsg) {
        DmlException ex = new DmlException(errorMsg);
        ex.setMessage(errorMsg);
        return ex;
    }

    /*******************************************************************************************************
    * @description Saves the data import record, dry runs the record, and returns updated
    * totals with the new row.
    * @param batchId: ID of the NPSP_Data_Import_Batch__c
    * @param dataImport: the NPSP_Data_Import__c record to update
    * @return String serialized DataImportModel
    */
    @AuraEnabled
    public static String saveAndDryRunDataImport(Id batchId, DataImport__c dataImport) {

        try {
            dataImport.Additional_Object_JSON__c =
                GE_FormRendererService.convertWidgetDataToObjectJSON(dataImport.Additional_Object_JSON__c);
            upsertDataImport(dataImport);
            return BGE_DataImportBatchEntry_CTRL.runSingleDryRun(dataImport.Id, batchId);

        } catch (Exception ex) {
            // create custom lwc exception and throw it
            String JSONExceptionData = ERR_ExceptionData.createExceptionWrapperJSONString(ex);

            throw returnDmlException(JSONExceptionData);
        }
    }

    /*******************************************************************************************************
    * @description Saves the data import record, dry runs the record, and returns updated
    * totals with the new row.
    * @param dataImport: the NPSP_Data_Import__c record to update
    * @param updateGift: If true, BDI will attempt to match to an existing opportunity/payment
    * @return String serialized DataImportModel
    */
    @AuraEnabled
    public static Id submitDataImportToBDI(DataImport__c dataImport, Boolean updateGift) {
        // Check for widget data and convert it to the correct format for processing
        dataImport.Additional_Object_JSON__c =
            GE_FormRendererService.convertWidgetDataToObjectJSON(dataImport.Additional_Object_JSON__c);

        // Run the BDI process on this new Data Import
        processDataImport(dataImport, false, updateGift);

        // Get the ID of the created Opportunity so we can return it
        Id oppId = getOpportunityIdFromImport(dataImport.Id);

        return oppId;
    }

    /*******************************************************************************************************
    * @description Set DataImport Settings that are important to Gift Entry matching
    * @return Data_Import_Settings__c diSettings object used to process gifts
    */
    private static Data_Import_Settings__c getGiftEntrySettings(Boolean updateGift) {
        Data_Import_Settings__c diSettings = Data_Import_Settings__c.getOrgDefaults();
        // If we are updating an existing gift, set the matching logic accordingly
        diSettings.Donation_Matching_Behavior__c = 
            updateGift ? BDI_DataImport_API.ExactMatchOrCreate : BDI_DataImport_API.DoNotMatch;
        return diSettings;
    }

    /*******************************************************************************************************
    * @description Takes a Data Import record and saves it to the database. If the id is already defined
    * update the record; otherwise, insert it.
    *
    * @param dataImport - The DataImport__c record, as filled in by the user.
    * @return The DataImport__c record that was saved
    */
    @AuraEnabled
    public static DataImport__c upsertDataImport(DataImport__c dataImport) {
        try {
            upsert dataImport Id;

            return dataImport;
        } catch (Exception e) {
            String JSONExceptionData = ERR_ExceptionData.createExceptionWrapperJSONString(e);

            throw returnDmlException(JSONExceptionData);
        }
    }

    /*******************************************************************************************************
    * @description Run the DataImport process on a single gift
    * @param dataImport DataImport record to be processed
    * @param isDryRun Boolean to set if the process should only return import results and not process
    * @param updateGift Boolean to determine our matching criteria.
    *                   true = "single match or create" and means we are updating
    *                   false = "do not match"
    */
    private static void processDataImport(DataImport__c dataImport, Boolean isDryRun, Boolean updateGift) {
        try {

            Data_Import_Settings__c diSettings = getGiftEntrySettings(updateGift);

            List<DataImport__c> listDI = new List<DataImport__c>{dataImport};

            BDI_DataImport_API.processDataImportRecords(diSettings, listDI, isDryRun);
        } catch (Exception e) {
            String JSONExceptionData = ERR_ExceptionData.createExceptionWrapperJSONString(e);

            throw returnDmlException(JSONExceptionData);
        }
    } 

    /*******************************************************************************************************
    * @description Return the imported Opportunity (Donation) from a DataImport process
    * @param dataImportId Id of DataImport object that created or matching this Opportunity
    * @return Id of the Opportunity
    */
    private static String getOpportunityIdFromImport(Id dataImportId) {
        try {
            DataImport__c di = [
                    SELECT DonationImported__c,
                            FailureInformation__c
                    FROM DataImport__c
                    WHERE Id = :dataImportId
            ];
            if(di.FailureInformation__c != null) {
                throw new BDIException(di.FailureInformation__c);
            }
            return di.DonationImported__c;
        } catch(Exception e) {

            String JSONExceptionData = ERR_ExceptionData.createExceptionWrapperJSONString(e);

            throw returnAuraException(JSONExceptionData);
        }
    }

    @AuraEnabled
    public static Boolean isElevateCustomer() {
        try {
            return GE_PaymentServices.isElevateCustomer;
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    public class OrgDomainInfo {
        @AuraEnabled public String orgDomain;
        @AuraEnabled public String podName;

        public OrgDomainInfo (String orgDomain, String podName) {
            this.orgDomain = orgDomain;
            this.podName = podName;
        }
    }

    private class BDIException extends Exception {}
}
