/*
    Copyright (c) 2019 Salesforce.org
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
* @group Gift Entry
* @group-content ../../ApexDocContent/GiftEntry.htm
* @description Unit tests to cover methods in GE_ColumnHeaderService_TEST.
*/
@isTest
public with sharing class GE_ColumnHeaderService_TEST {

    /*******************************************************************************************************
    * @description Tests that the default templates list headers list is properly constructed.
    */
    @isTest
    static void shouldReturnDefaultTemplatesListHeaders() {
        // Retrieve a column header service instance
        GE_ColumnHeaderService columnHeaderService = GE_ColumnHeaderService.getInstance();

        String name = SObjectType.Form_Template__c.fields.Name.Name;
        String description = SObjectType.Form_Template__c.fields.Description__c.Name;
        String createdBy = SObjectType.Form_Template__c.fields.CreatedById.Name;
        String lastModifiedDate = SObjectType.Form_Template__c.fields.LastModifiedDate.Name;

        // Confirm the templates headers list is populated
        System.assert(columnHeaderService.defaultTemplatesListHeaders != null);
        // Confirm the correct list size
        System.assert(columnHeaderService.defaultTemplatesListHeaders.size() == 4);
        // Confirm the order is correct
        System.assert(columnHeaderService.defaultTemplatesListHeaders[0].Field_Api_Name__c == name);
        System.assert(columnHeaderService.defaultTemplatesListHeaders[1].Field_Api_Name__c == description);
        System.assert(columnHeaderService.defaultTemplatesListHeaders[2].Field_Api_Name__c == createdBy);
        System.assert(columnHeaderService.defaultTemplatesListHeaders[3].Field_Api_Name__c == lastModifiedDate);
    }
}
