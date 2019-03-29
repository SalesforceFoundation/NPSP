/*
    Copyright (c) 2014 Salesforce.org
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
* @date 2019
* @group Batch Data Import
* @group-content ../../ApexDocContent/BatchDataImport.htm
* @description define behaviors of field mapping classes
*/

public with sharing class BDI_FieldMapping_HelpText extends BDI_FieldMapping_BASE {
    

    public BDI_FieldMapping_HelpText() {

    }

    public override Map<String,String> getFieldMap(String dataImportObjectName, String targetObjectName, List<String> dataImportFields) {

        Map<String, String> dataImportFieldToTargetField = new Map<String, String>();

        for (String dataImportField : dataImportFields) {

            DescribeFieldResult fieldDescribe =
                UTIL_Describe.getFieldDescribe(UTIL_Namespace.StrTokenNSPrefix('DataImport__c'), dataImportField);
            String helpText = fieldDescribe.getInlineHelpText();

            if (helpText != null && helpText != '') {
                List<String> parts = helpText.split('\\.', 2);

                if (parts.size() == 2 && parts[0] == dataImportObjectName && parts[1] != '') {
                    String fieldName = parts[1];
                    //if we aren't in the npsp namespace, remove those tokens from help text
                    //also removes tokens from actual detected namespace, if we happen to be
                    //in a non-npsp namespace
                    if (UTIL_Namespace.getNamespace() != 'npsp') {
                        String fieldNameOld = fieldName;
                        fieldName = UTIL_Namespace.StrTokenRemoveNSPrefix(fieldName);

                        //if we have a detected namespace, and removed a namespace from the current field
                        //add the current namespace back in, allowing this code to run in any namespace
                        if (fieldName != fieldNameOld && UTIL_Namespace.getNamespace() != '') {
                            fieldName = UTIL_Namespace.StrAllNSPrefix(fieldName);
                        }
                    }

                    // make sure they have permissions to modify the target field
                    // we can't do this in all tests, because many profiles won't have FLS set for all our new fields!
                    if (!Test.isRunningTest() || failFieldLevelSecurity) {
                        fieldDescribe = UTIL_Describe.getFieldDescribe(targetObjectName, fieldName);
                        Set<String> setAuditFields = new Set<String>{
                            'createddate', 'createdbyid', 'lastmodifieddate', 'lastmodifiedbyid'
                        };
                        Boolean isAuditField = setAuditFields.contains(fieldName.toLowerCase());

                        if (failFieldLevelSecurity ||
                            fieldDescribe == null ||
                            !fieldDescribe.isCreateable() ||
                            (!isAuditField && !fieldDescribe.isUpdateable())) {
                                throw (new FLSException(
                                    String.format(System.Label.flsError, new List<String>{ targetObjectName + '.' + fieldName }
                                )));
                        }
                    }

                    dataImportFieldToTargetField.put(dataImportField, fieldName);
                }
            }
        }

        if (isCurrencyMapped(targetObjectName)) {
            addCurrencyIsoCode(dataImportFieldToTargetField);
        }

        return dataImportFieldToTargetField;
    }

}