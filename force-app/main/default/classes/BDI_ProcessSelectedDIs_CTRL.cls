/**
    Copyright (c) 2022, Salesforce.org
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
* @date 2022
* @description Controller for visualforce page enabling a selected set of Data Import records 
* to be processed via list view button
*/
public with sharing class BDI_ProcessSelectedDIs_CTRL {

    private String diIds = '';
    PageReference listView = new ApexPages.Action('{!List}').invoke();
    @TestVisible private Integer maxNumOfDi = Test.isRunningTest() ? 5 : 200;
    public Boolean error {get; set;}
    private String retURL = null;

    /*********************************************************************************************************
    * @description Constructor that extracts the Data Import Ids from the URL and performs some checks on them
    * before reformatting the ids for the redirect.
    */
    public BDI_ProcessSelectedDIs_CTRL(ApexPages.StandardSetController setCtrl) {

        DataImport__c[] diRecs = (List<DataImport__c>)setCtrl.getSelected();

        // Redirect to the processing page only if there are more than 1 but less than max number of records
        // and none of the records are already 'Imported'
        if (diRecs != null && diRecs.size() > 0 && diRecs.size() <= maxNumOfDi) {
            
            Map<Id,DataImport__c> diMap = new Map<Id,DataImport__c>(diRecs);

            populateDataImportIds(diMap);

        // Throw an error if no records were selected
        } else if (diRecs == null || diRecs.size() == 0) { 
            error = true;
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 
                                    System.label.bdiSelectNoDIRecordsSelected));

        // Throw an error if too many records were selected
        } else if (diRecs.size() > maxNumOfDi) {
            error = true;
            String errorMsg = String.format(System.label.bdiSelectTooManyDIRecords, 
                new String[]{String.valueOf(maxNumOfDi)});
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, errorMsg));
        }
    }

    /*********************************************************************************************************
    * @description Redirects user to the Data Import configuration page if there are no errors and at least
    * some data import ids defined
    * @return PageReference
    */
    public PageReference directToDataImportPage() {
        
        if (diIds.length() > 0 && !error) {
            PageReference diPage = Page.BDI_DataImport;
            
            if (listView != null) {
                retURL = listView.getUrl();
            }
            
            // Passing through the originating list view for return at the end of processing
            diPage.getParameters().put('retURL',retURL);
            
            // Put the selected Data Import Ids into the URL to pass to the DataImport page
            diPage.getParameters().put('diIds',diIds);

            diPage.setRedirect(true);
            return diPage;
        }
        return null;
    }

    /*********************************************************************************************************
    * @description Returns the user to the list view they last accessed.
    * @return PageReference for the last list view they accessed.
    */
    public PageReference returnToListView() {
        return listView;
    }

    /*********************************************************************************************************
    * @description Confirms that the data import records are not already imported and adds the diIds to a 
    * string for passing in the URL.
    * @param diMap Map of Data Import Id to Data Import record for processing.
    */
    private void populateDataImportIds (Map<Id,DataImport__c> diMap) {
            // Query the Data import records to see if any of them are imported.  The try/catch is to handle
            // and display any field / object level security error.
            try {
                for (DataImport__c di: [SELECT Id, Status__c, NPSP_Data_Import_Batch__c 
                                        FROM DataImport__c WHERE Id IN: diMap.keySet()                        
                                        WITH SECURITY_ENFORCED]) {
                    diIds += di.Id + ',';

                    // If an already imported record is found then throw an error and prevent redirect.
                    if (di.Status__c == BDI_DataImport_API.bdiImported) {
                        error = true;
                        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 
                                                System.label.bdiSelectCantProcessImportedRecords));
                        break;

                    // If a data import record linked to a data import batch is found then throw an error
                    } else if (!String.isBlank(di.NPSP_Data_Import_Batch__c)) {
                        error = true;
                        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 
                                                System.label.bdiSelectCantProcessBatchDIRecords));
                        break;
                    } else {
                        error = false;
                    }
                }
            } catch (Exception e) {
                error = true;
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, e.getMessage()));
            }
                
            diIds = diIds.removeEnd(',');
    }
}
