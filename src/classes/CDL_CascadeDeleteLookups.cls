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
 * @group Utilities
 * @description Cascade deletion and undeletion Domain Classes
 */

public class CDL_CascadeDeleteLookups {

    @TestVisible private static final String HTML_TEXT_CHILD_RECORDS_FORMAT = '<li><a href="#" onclick="window.open(\'\'/{0}\'\', \'\'\'\');return false;" target="_blank">{1}</a></li>';

    /** @description The single instance of the CascadeDelete. */
    private static CascadeDelete cascadeDelete;

    /** @description The single instance of the CascadeUndelete. */
    private static CascadeUndelete cascadeUndelete;

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

    /*******************************************************************************************************
    * @description Gets a single instance of the CascadeUndelete.
    * @return CascadeUndelete
    ********************************************************************************************************/
    public static CascadeUndelete getCascadeUndelete() {
        if (cascadeUndelete == null) {
            cascadeUndelete = new CascadeUndelete();
        }
        return cascadeUndelete;
    }

    /************************************************************************************************************
    * @description Contains the method a Class needs to implement in order to load the children records to delete.
    * To load the children records to delete, a class should implement this Interface and be passed to the 
    * "CascadeUndelete" object.
    *************************************************************************************************************/
    public interface CascadeDeleteLoader {

        /*******************************************************************************************************
        * @description Gets the children records that need to be validated or deleted.
        * @param Set<Id> The parent ids of the records that need to be retrieved.
        * @return List<SObject> The children records.
        ********************************************************************************************************/
        List<SObject> load(Set<Id> parentIds);
    }

    /*******************************************************************************************************
    * @description Contains the method a Class needs to implement in order to validate the deletion of
    * the children records. This is run by the instance of the "CascadeDelete" Class.
    ********************************************************************************************************/
    public interface CascadeDeleteValidator {

        /*******************************************************************************************************
        * @description Validates the children records.
        * @param List<SObject> The parents records that are being deleted.
        * @param List<SObject> The children records to validate.
        * @return List<SObject> The children records that pass the validation, and can be deleted.
        ********************************************************************************************************/
        List<SObject> validateDeletion(List<SObject> parents, List<SObject> children);
    }

    /*******************************************************************************************************
    * @description Contains the method a Class needs to implement in order to load the children records.
    * To load the children records to undelete, a class should implement this Interface 
    * and be passed to the "CascadeUndelete" object.
    ********************************************************************************************************/
    public interface CascadeUndeleteLoader {

        /*******************************************************************************************************
        * @description Gets the children records that need to be undeleted.
        * @param Set<Id> The parent ids of the records that need to be retrieved.
        * @return List<SObject> The children records.
        ********************************************************************************************************/
        List<SObject> load(Set<Id> parentIds);

        /*******************************************************************************************************
        * @description Gets the next CascadeUndeleteLoader.
        * @return CascadeUndeleteLoader The next CascadeUndeleteLoader.
        ********************************************************************************************************/
        CascadeUndeleteLoader next();
    }

    /*******************************************************************************************************
    * @description Contains Cascade Delete logic. The Trigger Handlers use this class to retrieve  
    * the children of the records being deleted, validate and delete the children records.
    ********************************************************************************************************/
    public class CascadeDelete {
        private Map<Id, SObject> parents;
        private List<SObject> children;
        private List<SObject> validChildren;

        private CascadeDeleteLoader loader;
        private CascadeDeleteValidator childrenValidator;

        /******************************************************************************************************
        * @description The Constructor of CascadeDelete
        */
        public CascadeDelete() {
            parents = new Map<Id, SObject>();
            children = new List<SObject>();
            validChildren = new List<SObject>();
        }

        /*******************************************************************************************************
        * @description Sets the parents records (from the Triggers context) that are being deleted.
        * @return void
        ********************************************************************************************************/
        public void setParents(List<SObject> parents) {
            this.parents = new Map<Id, SObject>(parents);
        }

        /*******************************************************************************************************
        * @description Sets the object that loads the children records.
        * @return void
        ********************************************************************************************************/
        public void setLoader(CascadeDeleteLoader loader) {
            this.loader = loader;
        }

        /*******************************************************************************************************
        * @description Sets the object that validates the children records.
        * @return void
        ********************************************************************************************************/
        public void setValidator(CascadeDeleteValidator childrenValidator) {
            this.childrenValidator = childrenValidator;
        }

        /*******************************************************************************************************
        * @description Checks if the object that loads the children records exists.
        * @return Boolean
        ********************************************************************************************************/
        public Boolean hasLoader() {
            return loader != null;
        }

        /*******************************************************************************************************
        * @description Checks if the object that validates the children records exists.
        * @return Boolean
        ********************************************************************************************************/
        public Boolean hasValidator() {
            return childrenValidator != null;
        }

        /*******************************************************************************************************
        * @description Retrieves the children records, and stores the records. This method uses the injected
        * ChildrenLoader, to load the children records.
        * @return void
        ********************************************************************************************************/
        public void load() {
            if (this.loader == null) {
                return;
            }

            children = loader.load(parents.keySet());
        }

        /*******************************************************************************************************
        * @description Validates the children records. This method uses the injected ChildrenValidator,
        * to load the children records.
        * @return void
        ********************************************************************************************************/
        public void validateDeletion() {
            if (this.childrenValidator != null) {
                validChildren = this.childrenValidator.validateDeletion(parents.values(), children);
            }
            else {
                validChildren = children;
            }
        }

        /*******************************************************************************************************
        * @description Deletes the valid children records.
        * @return void
        ********************************************************************************************************/
        public void deleteRecords() {
            if (validChildren.isEmpty()) {
                return;
            }

            List<Database.DeleteResult> deletionResults = Database.delete(validChildren, false);
            ERR_Handler.Errors errorResult = ERR_Handler.getErrors(deletionResults, validChildren);
            if (errorResult.errorsExist) {
                ERR_Handler.processErrors(errorResult.errorRecords, 'TDTM');
            }
        }
    }

    /*******************************************************************************************************
    * @description Contains Cascade Undelete logic. The Trigger Handlers use this class to retrieve 
    * the children of the records being undeleted and undelete the children records.
    ********************************************************************************************************/
    public class CascadeUndelete {
        private Set<Id> parentIds;
        private CascadeUndeleteLoader loader;

        /*********************************************************************************************************
        * @description The Constructor of CascadeUndelete
        */
        public CascadeUndelete() {
            parentIds = new Set<Id>();
        }

        /*******************************************************************************************************
        * @description Sets the parents records (from the Triggers context) that are being undeleted.
        * @return void
        ********************************************************************************************************/
        public void setParents(List<SObject> parents) {
            this.parentIds = new Map<Id, SObject>(parents).keySet();
        }

        /*******************************************************************************************************
        * @description Sets the object that loads the children records.
        * @return void
        ********************************************************************************************************/
        public void setLoader(CascadeUndeleteLoader loader) {
            this.loader = loader;
        }

        /*******************************************************************************************************
        * @description Undeletes the children records.
        * @return void
        ********************************************************************************************************/
        public void undeleteRecords() {
            CascadeUndeleteLoader currentChildrenLoader = loader;

            // The Undeletion runs in a loop because some children records need to be undeleted first.
            // Undelete all the records at once can cause a broken reference.
            while (currentChildrenLoader != null) {
                List<SObject> children = currentChildrenLoader.load(parentIds);
                if (children.isEmpty()) {
                    currentChildrenLoader = currentChildrenLoader.next();
                    continue;
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
    * @description Contains the logic that displays the error messages on one parent
    ********************************************************************************************************/
    public class Error {
        private String parentToDeleteName;
        private Map<String, Map<Id, String>> childrenByErrorType;

        /******************************************************************************************************
        * @description The Constructor of Error
        * @param String The name of the Parent record
        */
        public Error(String parentToDeleteName) {
            this.parentToDeleteName = parentToDeleteName;
            childrenByErrorType = new Map<String, Map<Id, String>>();
        }

        /*******************************************************************************************************
        * @description Adds the information about child that prevents the deletion, and the type of error.
        * @param String The type of error
        * @param Id The Id of the child record
        * @param String The name of the child record
        * @return void
        ********************************************************************************************************/
        public void addChildError(String errorType, Id childRecordId, String childRecordName) {
            if (childrenByErrorType.containsKey(errorType) == false) {
                childrenByErrorType.put(errorType, new Map<Id, String>());
            }

            childrenByErrorType.get(errorType).put(childRecordId, childRecordName);
        }

        /*******************************************************************************************************
        * @description Get the error message. The message contains the error type and the list of the children 
        * records preventing the parent deletion.
        * @return String The error message
        ********************************************************************************************************/
        public String getMessage() {
            List<String> result = new List<String>();
            if (childrenByErrorType.isEmpty()) {
                return '';
            }

            if (USER_UserService.isUserRunningLightning() || USER_UserService.isUserRunningMobile()) {
                for (String errorType : childrenByErrorType.keySet()) {
                    result.add(errorType + ' (' + getPlainTextChildrenList(childrenByErrorType.get(errorType)) + ')');
                }
                return String.format(Label.CascadeDeletionErrorLightning, new List<String>{parentToDeleteName, String.join(result, ',')});
            }
            else {
                for (String errorType : childrenByErrorType.keySet()) {
                    result.add(errorType + ':' + getHTMLChildrenList(childrenByErrorType.get(errorType)));
                }
                return String.format(Label.CascadeDeletionError, new List<String>{parentToDeleteName, String.join(result, '')});
            }
        }

        /*******************************************************************************************************
        * @description Returns a HTML list of the child records preventing deletion, with links to those records.
        * @param Map<Id, String> The child records preventing the deletion
        * @return String The HTML text that contains a list of the child records.
        ********************************************************************************************************/
        private String getHTMLChildrenList(Map<Id, String> childRecords) {
            List<String> result = new List<String>{'<ul>'};
            for (Id childrenRecordId : childRecords.keySet()) {
                result.add(String.format(HTML_TEXT_CHILD_RECORDS_FORMAT, new List<String>{childrenRecordId, childRecords.get(childrenRecordId)}));
            }
            result.add('</ul>');
            
            return String.join(result, '');
        }

        /*******************************************************************************************************
        * @description Returns a plain text list of the child records preventing deletion
        * @param Map<Id, String> The child records preventing the deletion
        * @return String The plain text that contains a list of the child records.
        ********************************************************************************************************/
        private String getPlainTextChildrenList(Map<Id, String> childRecords) {
            List<String> result = new List<String>();
            for (Id childrenRecordId : childRecords.keySet()) {
                result.add(childRecords.get(childrenRecordId));
            }
            
            return String.join(result, ', ');
        }
    }
}