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
* @description Displays errors for a specified record or for all records
*/
public inherited sharing class ERR_Log_CTRL {

    /**
    * @description Error log service
    */
    @TestVisible
    private static ERR_LogService logService {
        get {
            if (logService == null) {
                logService = new ERR_LogService();
            }
            return logService;
        }
        set;
    }

    @AuraEnabled(cacheable=false)
    public static Map<String, Object> getData(Id recordId) {
        Map<String, Object> data = new Map<String, Object>();
         try {
            SObjectType sObjType = recordId.getSObjectType();
            data.put('sObjectType', String.valueOf(sObjType));
            data.put('sObjectTypeLabelPlural', sObjType.getDescribe().getLabelPlural());

            String soql = new UTIL_Query()
                .withSelectFields(new String[]{ 'Name' })
                .withFrom(String.valueOf(sObjType))
                .withWhere('Id = :recordId')
                .build();

            List<SObject> records = Database.query(soql);
            if (records != null && !records.isEmpty()) {
                data.put('recordName', (String) records[0].get('Name'));
            }

            data.put('errorLogs', logService.getErrors(recordId));

        } catch (Exception e) {
            UTIL_AuraEnabledCommon.throwAuraHandledException(e.getMessage());
        }

        return data;
    }
    
}
