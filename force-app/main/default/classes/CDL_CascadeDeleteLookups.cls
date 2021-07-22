/*
    Copyright (c) 2017, Salesforce.org
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
 * @group Cascade Delete
 * @description Cascade deletion and undeletion Domain Classes
 */

public class CDL_CascadeDeleteLookups {

    @TestVisible
    private static final String HTML_TEXT_CHILD_RECORDS_FORMAT = '<li><a href="#" onclick="window.open(\'\'/{0}\'\', \'\'\'\');return false;" target="_blank">{1}</a></li>';

    /** @description The single instance of the CascadeDelete. */
    private static CascadeDelete cascadeDelete;

    /*******************************************************************************************************
    * @description Gets the current user Theme Context (Lightning Experience or Classic).
    * @return Boolean.
    ********************************************************************************************************/
    public static Boolean isLightningContext {
        get {
            if (isLightningContext == null) {
                isLightningContext = USER_UserService.isUserRunningLightning() || USER_UserService.isUserRunningMobile();
            }
            return isLightningContext;
        }
        set;
    }

    /*******************************************************************************************************
    * @description Gets a single instance of the CascadeDelete.
    * @return CascadeDelete
    ********************************************************************************************************/
    public static CascadeDelete getCascadeDelete() {
        if (cascadeDelete == null) {
            cascadeDelete = new CascadeDelete();
        }
        return cascadeDelete;
    }

    /************************************************************************************************************
    * @description Contains the method a Class needs to implement in order to load the children of the deleted 
    * records. To load the children of the deleted records, a class should implement this Interface and pass it to the 
    * "CascadeDelete" object.
    *************************************************************************************************************/
    public interface CascadeDeleteLoader {

        /*******************************************************************************************************
        * @description Gets the children of the deleted records.
        * @param Set<Id> The deleted records Ids.
        * @return List<SObject> The children records.
        ********************************************************************************************************/
        List<SObject> load(Set<Id> deletedRecordIds);
    }

    /*******************************************************************************************************
    * @description Contains the method a Class needs to implement in order to validate the children of the 
    * deleted records. To validate the children of the deleted records, a class should implement this 
    * Interface and pass it to the "CascadeDelete" object.
    ********************************************************************************************************/
    public interface CascadeDeleteValidator {

        /*******************************************************************************************************
        * @description Validates the children records.
        * @param List<SObject> The deleted records.
        * @param List<SObject> The children records to validate.
        * @return void
        ********************************************************************************************************/
        void validate(List<SObject> deletedRecords, List<SObject> children);
    }

    /*******************************************************************************************************
    * @description Contains the method a Class needs to implement in order to load children of the undeleted
    * records. To load the children of the undeleted records, a class should implement this Interface 
    * and pass to the "CascadeUndelete" object.
    ********************************************************************************************************/
    public interface CascadeUndeleteLoader {

        /*******************************************************************************************************
        * @description Gets the children of the undeleted records.
        * @param Set<Id> The undeleted records Ids.
        * @return List<SObject> The children records.
        ********************************************************************************************************/
        List<SObject> load(Set<Id> deletedRecordIds);

        /*******************************************************************************************************
        * @description Gets the next group of child records to undelete (CascadeUndeleteLoader).
        * @return CascadeUndeleteLoader The next CascadeUndeleteLoader.
        ********************************************************************************************************/
        CascadeUndeleteLoader next();
    }

    /*******************************************************************************************************
    * @description Contains Cascade Delete logic. The Trigger Handlers use this class to retrieve  
    * the children of the deleted records, validate and delete children records.
    ********************************************************************************************************/
    public class CascadeDelete {
        private Map<Id, SObject> deletedRecords;
        private List<SObject> children;

        private CascadeDeleteLoader loader;
        private CascadeDeleteValidator validator;

        /******************************************************************************************************
        * @description The Constructor of CascadeDelete.
        */
        public CascadeDelete() {
            deletedRecords = new Map<Id, SObject>();
            children = new List<SObject>();
        }

        /*******************************************************************************************************
        * @description Sets the deleted records (from the Triggers context) that are deleted.
        * @param List<SObject> The deleted records (from the Triggers context).
        * @return void
        ********************************************************************************************************/
        public void setDeletedRecords(List<SObject> deletedRecords) {
            this.deletedRecords = new Map<Id, SObject>(deletedRecords);
        }

        /*******************************************************************************************************
        * @description Sets the object that loads the children records.
        * @param CascadeDeleteLoader The Cascade Delete Loader.
        * @return void
        ********************************************************************************************************/
        public void setLoader(CascadeDeleteLoader loader) {
            this.loader = loader;
        }

        /*******************************************************************************************************
        * @description Sets the object that validates the children records.
        * @param CascadeDeleteValidator The Cascade Delete Validator.
        * @return void
        ********************************************************************************************************/
        public void setValidator(CascadeDeleteValidator validator) {
            this.validator = validator;
        }

        /*******************************************************************************************************
        * @description Retrieves the children records, and stores the records. This method uses the injected
        * CascadeDeleteLoader, to load the children records.
        * @return void
        ********************************************************************************************************/
        public void load() {
            if (loader != null) {
                children = loader.load(deletedRecords.keySet());
            }
        }

        /*******************************************************************************************************
        * @description Validates the children records. This method uses the injected CascadeDeleteValidator,
        * to validate the children records.
        * @return void
        ********************************************************************************************************/
        public void validate() {
            if (validator != null) {
                validator.validate(deletedRecords.values(), children);
            }
        }

        /*******************************************************************************************************
        * @description Deletes the children records.
        * @return void
        ********************************************************************************************************/
        public void deleteRecords() {
            if (children.isEmpty()) {
                return;
            }

            List<Database.DeleteResult> deletionResults = Database.delete(children, false);
            ERR_Handler.Errors errorResult = ERR_Handler.getErrors(deletionResults, children);
            if (errorResult.errorsExist) {
                ERR_Handler.processErrors(errorResult.errorRecords, 'TDTM');
            }
        }
    }

    /*******************************************************************************************************
    * @description Contains Cascade Undelete logic. The Trigger Handlers use this class to retrieve 
    * the children of the undeleted records, and undelete the children records.
    ********************************************************************************************************/
    public class CascadeUndelete {
        private Set<Id> undeletedRecordIds;
        private CascadeUndeleteLoader loader;

        /*********************************************************************************************************
        * @description The Constructor of CascadeUndelete.
        */
        public CascadeUndelete() {
            undeletedRecordIds = new Set<Id>();
        }

        /*******************************************************************************************************
        * @description Sets the records (from the Triggers context) that are undeleted.
        * @param List<SObject> The undeleted records (from the Triggers context).
        * @return void
        ********************************************************************************************************/
        public void setUndeletedRecords(List<SObject> undeletedRecords) {
            this.undeletedRecordIds = new Map<Id, SObject>(undeletedRecords).keySet();
        }

        /*******************************************************************************************************
        * @description Sets the object that loads the children records.
        * @param CascadeUndeleteLoader The Cascade Undelete loader
        * @return void.
        ********************************************************************************************************/
        public void setLoader(CascadeUndeleteLoader loader) {
            this.loader = loader;
        }

        /*******************************************************************************************************
        * @description Undeletes the children records.
        * @return void.
        ********************************************************************************************************/
        public void undeleteRecords() {
            CascadeUndeleteLoader currentChildrenLoader = loader;

            // The Undeletion runs in a loop because some children records need to be undeleted first.
            // Undelete all the records at once can break the references.
            while (currentChildrenLoader != null) {
                List<SObject> children = currentChildrenLoader.load(undeletedRecordIds);
                if (children.isEmpty()) {
                    break;
                }

                List<Database.UndeleteResult> undeleteResults = Database.undelete(children, false);
                ERR_Handler.Errors errorResult = ERR_Handler.getErrors(undeleteResults, children);
                if (errorResult.errorsExist) {
                    ERR_Handler.processErrors(errorResult.errorRecords, 'TDTM');
                }
                
                currentChildrenLoader = currentChildrenLoader.next();
            }
        }
    }

    /*******************************************************************************************************
    * @description Contains the logic that displays the error messages for a deleted record.
    ********************************************************************************************************/
    public class Error {
        private String deletedRecordName;
        private Map<String, Map<Id, String>> childrenByErrorType;

        /******************************************************************************************************
        * @description The Constructor of Error.
        * @param String The name of the deleted record.
        */
        public Error(String deletedRecordName) {
            this.deletedRecordName = deletedRecordName;
            childrenByErrorType = new Map<String, Map<Id, String>>();
        }

        /*******************************************************************************************************
        * @description Adds the information about child that prevents the deletion, and the type of error.
        * @param String The type of error.
        * @param Id The Id of the child record.
        * @param String The name of the child record.
        * @return void.
        ********************************************************************************************************/
        public void addChildError(String errorType, Id childRecordId, String childRecordName) {
            if (childrenByErrorType.containsKey(errorType) == false) {
                childrenByErrorType.put(errorType, new Map<Id, String>());
            }

            childrenByErrorType.get(errorType).put(childRecordId, childRecordName);
        }

        /*******************************************************************************************************
        * @description Gets the error message. The message contains the error type and the list of the children
        * preventing the deletion.
        * @return String The error message.
        ********************************************************************************************************/
        public String getMessage() {
            List<String> result = new List<String>();
            if (childrenByErrorType.isEmpty()) {
                return '';
            }

            if (CDL_CascadeDeleteLookups.isLightningContext) {
                for (String errorType : childrenByErrorType.keySet()) {
                    result.add(errorType + ' (' + getPlainTextChildrenList(childrenByErrorType.get(errorType)) + ')');
                }
                return String.format(Label.CascadeDeletionErrorLightning, new List<String>{deletedRecordName, String.join(result, ',')});
            }
            else {
                for (String errorType : childrenByErrorType.keySet()) {
                    result.add(errorType + ':' + getHTMLChildrenList(childrenByErrorType.get(errorType)));
                }
                return String.format(Label.CascadeDeletionError, new List<String>{deletedRecordName, String.join(result, '<br/>')});
            }
        }

        /*******************************************************************************************************
        * @description Returns a HTML list of the child records preventing the deletion, with links to those records.
        * @param Map<Id, String> The child records preventing the deletion.
        * @return String The HTML text that contains a list of the child records.
        ********************************************************************************************************/
        private String getHTMLChildrenList(Map<Id, String> childRecords) {
            List<String> result = new List<String>{'<ul>'};
            for (Id childrenRecordId : childRecords.keySet()) {
                result.add(String.format(HTML_TEXT_CHILD_RECORDS_FORMAT,
                    new List<String>{childrenRecordId, childRecords.get(childrenRecordId).escapeHtml4()}));
            }
            result.add('</ul>');
            
            return String.join(result, '');
        }

        /*******************************************************************************************************
        * @description Returns a plain text list of the child records preventing the deletion.
        * @param Map<Id, String> The child records preventing the deletion.
        * @return String The plain text that contains a list of the child records.
        ********************************************************************************************************/
        private String getPlainTextChildrenList(Map<Id, String> childRecords) {
            List<String> result = new List<String>();
            for (Id childrenRecordId : childRecords.keySet()) {
                result.add(childRecords.get(childrenRecordId).escapeHtml4());
            }
            
            return String.join(result, ', ');
        }
    }
}