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
* @description Custom_Column_Header__c default instances specifically used for gift entry use cases.
*/
public with sharing class GE_ColumnHeaderService {

    public static GE_ColumnHeaderService columnHeaderServiceInstance = null;
    public Custom_Column_Header__c[] defaultTemplatesListHeaders = new Custom_Column_Header__c[]{};

    /*******************************************************************************************************
    * @description Name of the custom 'Templates' list view in the Gift Entry landing page. Used in the
    * List_Name__c field of Custom_Column_Header__c records.
    */
    private final String TEMPLATES = 'Templates';

    /*******************************************************************************************************
    * @description return singleton instance of the class
    */
    public static GE_ColumnHeaderService getInstance() {
        if (columnHeaderServiceInstance == null) {
            columnHeaderServiceInstance = new GE_ColumnHeaderService();
            columnHeaderServiceInstance.setDefaultTemplatesListHeaders();
        }
        return columnHeaderServiceInstance;
    }

    /*******************************************************************************************************
    * @description Sets a default set of Custom_Column_Header__c for the 'Templates' list
    */
    private void setDefaultTemplatesListHeaders() {
        String[] fields = new String[] {
            SObjectType.Form_Template__c.fields.Name.Name,
            SObjectType.Form_Template__c.fields.Description__c.Name,
            SObjectType.Form_Template__c.fields.CreatedById.Name,
            SObjectType.Form_Template__c.fields.LastModifiedDate.Name
        };

        Custom_Column_Header__c[] templatesColumnHeaders = new Custom_Column_Header__c[] {};
        for (Integer i = 0; i < fields.size(); i++) {
            templatesColumnHeaders.add(
                constructColumnHeader(fields[i], i, TEMPLATES));
        }

        defaultTemplatesListHeaders = templatesColumnHeaders;
    }

    /*******************************************************************************************************
    * @description Constructs an instance of Custom_Column_Header__c
    *
    * @param fieldApiName: Field Api Name from an SObject
    * @param index: Desired position of the column in the table
    * @param listName: Identifier for grouping up a collection of headers
    */
    private Custom_Column_Header__c constructColumnHeader(String fieldApiName,
        Integer index, String listName) {

        Custom_Column_Header__c columnHeader = new Custom_Column_Header__c();
        columnHeader.Name = generateId();
        columnHeader.Field_Api_Name__c = fieldApiName;
        columnHeader.Index__c = index;
        columnHeader.List_Name__c = listName;

        return columnHeader;
    }

    /*******************************************************************************************************
    * @description Creates a 'unique' id made to look like a UUID.
    */
    private String generateId() {
        return generateRandomString(4) +
            generateRandomString(4) +
            '-' + generateRandomString(4) +
            '-' + generateRandomString(4) +
            '-' + generateRandomString(4) +
            '-' + generateRandomString(4) + generateRandomString(4) + generateRandomString(4);
    }

    /*******************************************************************************************************
    * @description Generates a random string
    *
    * @param len: Length of the string to generate
    */
    private String generateRandomString(Integer len) {
        final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
        String randStr = '';
        while (randStr.length() < len) {
        Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
        randStr += chars.substring(idx, idx+1);
        }
        return randStr; 
    }
}
