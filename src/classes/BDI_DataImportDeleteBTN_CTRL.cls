/*
    Copyright (c) 2017 Salesforce.org
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
 * @date 2017
 * @group Batch Data Import
 * @group-content ../../ApexDocContent/BatchDataImport.htm
 * @description Controller for the Batch Data Import: Delete Data Import Records buttons' Visualforce page 
 */

public with sharing class BDI_DataImportDeleteBTN_CTRL {
    /** @description Action type specified to delete imported Data Import records */
    public static final String ACTION_DELETE_IMPORTED = 'deleteImported';

    /** @description Action type specified to delete all Data Import records */
    public static final String ACTION_DELETE_ALL = 'deleteAll';
    
    /** @description Controller constructor */
    public BDI_DataImportDeleteBTN_CTRL() {}

    /** 
     * @description Delete all or imported only Data Import records based on the
     * action provided in the Visualforce page 'action' parameter.
     * @return PageReference Page specified in 'retURL' parameter or Home page
     */
    public PageReference buttonClick() {        
        String actionType = ApexPages.currentPage().getParameters().get('action');

        if (actionType == ACTION_DELETE_IMPORTED) {
            return deleteDIRecords(false);    

        } else if (actionType == ACTION_DELETE_ALL) {
            return deleteDIRecords(true);    
        }

        String errMsg = String.isBlank(actionType)
            ? 'Please specify an action type'
            : actionType + ' is not a valid action type'; 

        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errMsg)); 
        return null;
    }

    /** 
     * @description Delete Data Import records
     * @param isDeleteAll If true, delete all Data Import records, otherwise delete imported records only
     * @return PageReference Page specified in the 'retURL' parameter or Home page
     */
    PageReference deleteDIRecords(Boolean isDeleteAll) {
        try {
            if (isDeleteAll) {
                delete [SELECT Id FROM DataImport__c LIMIT 10000];
            } else {
                delete [SELECT Id FROM DataImport__c WHERE Status__c = :BDI_DataImport_API.bdiImported LIMIT 10000];
            }

            return close(); 

        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage())); 
            return null; 
        }
    }

    /** 
     * @description Return either page specified in the 'retURL' parameter or Home page
     * @return PageReference 
     */
    public PageReference close() {
        String retUrl = ApexPages.currentPage().getParameters().get('retURL');
        PageReference p;
        if (!String.isBlank(retUrl)) {
            p = new PageReference(retUrl);
        } else {
            p = USER_UserService.getHomePageReference();
        }
        p.setRedirect(true);
        return p;
    }
}