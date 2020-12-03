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
* @group ErrorHandling
* @description Service to log errors and retrieve them.
*/
public inherited sharing class ERR_LogService {

    /**
    * @description Finds error logs
    */
    @TestVisible
    private static Finder logFinder {
        get {
            if (logFinder == null) {
                logFinder = new Finder();
            }
            return logFinder;
        }
        set;
    }
    

    /**
    * @description Retrieves all errors for the specified record
    * @param recordId Record Id
    * @return List<Error__c>
    */
    public List<Error__c> getErrors(Id recordId) {
        return logFinder.getErrors(recordId);
    }


    /**
    * @description Retrieves the latest error (if any) for the specified record
    * @param recordId Record Id
    * @return Error__c
    */
    public Error__c getLatestError(Id recordId) {
        return logFinder.getLatestError(recordId);
    }



    /***
     * @description Retrieves errors
     */
    private without sharing class Finder {

        /**
        * @description Retrieves errors for the specified record
        * @param recordId Record Id
        * @return List<Error__c>
        */
        private List<Error__c> getErrors(Id recordId) {
            if (recordId == null) {
                return new List<Error__c>();
            }

            return [
                SELECT 
                    Name,
                    Context_Type__c, 
                    Related_Record_ID__c,               
                    Datetime__c,
                    Error_Type__c,
                    Full_Message__c
                FROM Error__c
                WHERE Related_Record_ID__c = :recordId
                ORDER BY CreatedDate DESC
            ];
        }

        /***
         * @description Returns the latest error (if any) for the provided record
         * @param recordId Record Id
         * @return Error__c
         */
        private Error__c getLatestError(Id recordId) {
            List<Error__c> errors = [
                SELECT Related_Record_ID__c, Full_Message__c, CreatedDate
                FROM Error__c
                WHERE Related_Record_ID__c = :recordId
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];

            return errors == null || errors.isEmpty()
                ? null
                : errors[0];
        }
    }


    /**
    * @description Builds and creates logs for errors and exceptions.
    * The current logger version is the ERR_Handler wrapper.
    */
    public inherited sharing class Logger {
        private final String context;
        private final String sObjType;

        /* @description Contains errors */
        @TestVisible
        private ERR_Handler.Errors errorResult = new ERR_Handler.Errors();

        public Logger(ERR_Handler_API.Context context, SObjectType sObjType) {
            this.context = context.name();
            this.sObjType = String.valueOf(sObjType);
        }

        /**
        * @description Constructs log record and adds it into the error log container
        * @param recordId Id An SObject record Id
        * @param message An error message
        * @param errorType An error type
        * @return void
        */
        public void addError(Id recordId, String message, String errorType) {
            Error__c error = new Error__c(
                Context_Type__c = context,
                Datetime__c = System.now(),
                Object_Type__c = sObjType,
                Related_Record_ID__c = recordId,
                Record_URL__c = ERR_Handler.getRecordURL(recordId),
                Error_Type__c = errorType,
                Full_Message__c = message
            );

            errorResult.errorRecords.add(error);
        }

        /**
        * @description Constructs and collects error logs for records that failed in the DML operation
        * @param dmlResults Insert/update/delete DML operation results
        * @param records Records which were saved/deleted by the DML operation
        * @return void
        */
        public void addErrors(List<Object> dmlResults, List<SObject> records) {
            if (records.isEmpty()) {
                return;
            }

            ERR_Handler.Errors dmlErrors = ERR_Handler.getErrorsOnly(dmlResults, records);

            if (!dmlErrors.errorsExist) {
                return;
            }

            errorResult.errorRecords.addAll(
                dmlErrors.errorRecords
            );
        }

        /**
        * @description Saves errors
        * @return void
        */
        public void processErrors() {
            errorResult.errorsExist = !errorResult.errorRecords.isEmpty();

            ERR_Handler.processErrorsOnly(errorResult, context);
        }
    }
    
}
