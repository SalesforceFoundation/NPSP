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
* @description Form Element definition for use in entering gifts.
*/
public with sharing class FORM_Element {

    @AuraEnabled public String elementType;
    @AuraEnabled public String displayRule;
    @AuraEnabled public String validationRule;
    @AuraEnabled public String customLabel;
    @AuraEnabled public String componentName;
    @AuraEnabled public String[] dataImportFieldMappingDevNames;
    @AuraEnabled public String dataImportObjectMappingDevName;
    @AuraEnabled public String fieldApiName;
    @AuraEnabled public String objectApiName;

    /* PS Additional props for FormFields */
    @AuraEnabled public String id;
    @AuraEnabled public String label;
    @AuraEnabled public Boolean required;
    @AuraEnabled public String sectionId;
    @AuraEnabled public String defaultValue;
    @AuraEnabled public String dataType;

    //Constructor for form field
    public FORM_Element(String elementType,
                        String displayRule, 
                        String validationRule,
                        String customLabel,
                        String[] dataImportFieldMappingDevNames) {
        this.elementType = elementType;                    
        this.displayRule = displayRule;
        this.validationRule = validationRule;
        this.customLabel = customLabel;
        this.dataImportFieldMappingDevNames = dataImportFieldMappingDevNames;
        this.required = false;
    }

    //Constructor for widget
    public FORM_Element(String elementType,
                        String displayRule,
                        String componentName,
                        String[] dataImportFieldMappingDevNames) {
        this.elementType = elementType;                    
        this.displayRule = displayRule;
        this.componentName = componentName;
        this.dataImportFieldMappingDevNames = dataImportFieldMappingDevNames;
        this.required = false;
    }
}
