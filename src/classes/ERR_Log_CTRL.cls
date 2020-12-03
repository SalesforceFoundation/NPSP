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
    public static String KEY_SOBJECT_TYPE = 'sObjectType';
    public static String KEY_SOBJECT_LABEL = 'sObjectLabelPlural';
    public static String KEY_ACCESS = 'hasAccess';
    public static String KEY_RECORD_NAME = 'recordName';
    public static String KEY_DATA = 'data';

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

    /***
    * @description Permissions class used to determine if the running user has permissions
    */
    @TestVisible
    private static UTIL_Permissions permissions {
        get {
            if (permissions == null) {
                permissions = new UTIL_Permissions();
            }
            return permissions;
        }
        set;
    }

    /**
     * @description Returns data to help render record Error Log page
     * @param recordId Record Id
     * @return Map<String, Object>
     */
    @AuraEnabled(cacheable=false)
    public static Map<String, Object> getData(Id recordId) {
        Map<String, Object> data = new Map<String, Object>();
         try {
            SObjectType sObjType = recordId.getSObjectType();
            data.put(KEY_SOBJECT_TYPE, String.valueOf(sObjType));
            data.put(KEY_SOBJECT_LABEL, sObjType.getDescribe().getLabelPlural());

            Boolean hasAccess = hasAccess(sObjType);
            data.put(KEY_ACCESS, hasAccess);

            if (hasAccess) {
                data.put(KEY_RECORD_NAME, getRecordName(recordId, sObjType));
                data.put(KEY_DATA, logService.getErrors(recordId));
            }

        } catch (Exception e) {
            UTIL_AuraEnabledCommon.throwAuraHandledException(e.getMessage());
        }

        return data;
    }

    /**
     * @description Determines if user has permissions to view the record
     * @param sObjType Record SObject Type
     * @return Boolean
     */
    private static Boolean hasAccess(SObjectType sObjType) {
        return permissions.canRead(sObjType)
            && permissions.canRead(Error__c.getSObjectType());
    }

    /**
     * @description Returns record name
     * @param recordId Record Id
     * @param sObjType Record SObject Type
     * @return String
     */
    private static String getRecordName(Id recordId, SObjectType sObjType) {
        String soql = new UTIL_Query()
            .withSelectFields(new String[]{ 'Name' })
            .withFrom(String.valueOf(sObjType))
            .withWhere('Id = :recordId')
            .build();

        List<SObject> records = Database.query(soql);

        return records == null || records.isEmpty()
            ? null
            : (String) records[0].get('Name');
    }
    
}
