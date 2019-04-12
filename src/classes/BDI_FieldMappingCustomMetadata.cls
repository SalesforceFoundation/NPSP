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
* @description Implement field mapping behavior for mapping with custom metadata types
*/

public with sharing class BDI_FieldMappingCustomMetadata implements BDI_FieldMapping {

    /*******************************************************************************************************
    * @description For the provided fields (in the form DIObject.developerfieldname) and target object, 
    * return a map of DI field (key) to mapped field name on the destination record (value). 
    *
    * @param dataImportObjectName the bdi object we care about (Contact1, Contact2, Account1, etc)
    * @param targetObjectName the underlying object the bdi object is (ie, Contact, Account, etc)
    * @param dataImportFields the DataImport fields to consider
    * @return Map<String, String> a map of DataImport fields to underlying object fields (eg, Donation_Amount__c => Amount)
    *
    * TODO: Implement this method
    */

    public Map<String,String> getFieldMap(String dataImportObjectName, 
        String targetObjectName, List<String> dataImportFields) {

        // TODO: Map fields based on CMT here

        return new Map<String,String>();
    }
}