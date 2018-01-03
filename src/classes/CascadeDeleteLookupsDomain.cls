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
 * @description Cascade deletion Domain Classes
 */

public class CascadeDeleteLookupsDomain {

    @TestVisible private static final String HTML_TEXT_CHILD_RECORDS_FORMAT = '<li><a href="#" onclick="window.open(\'\'/{0}\'\', \'\'\'\');return false;" target="_blank">{1}</a></li>';

    /*******************************************************************************************************
    * @description Contains the method that a Class needs to implements in order to pass the Children records
    * to the instance of the "CascadeDelete" Class. 
    ********************************************************************************************************/
    public interface ChildrenLoader {
        List<SObject> loadChildren(Set<Id> parentsIds);
    }

    /*******************************************************************************************************
    * @description Contains the method that a Class needs to implements in order to validate the deletion of
    * the children records. This is run by the instance of the "CascadeDelete" Class.
    ********************************************************************************************************/
    public interface ChildrenValidator {
        void validateChildrenDeletion(List<SObject> parentRecords, List<SObject> childrenRecords);
    }

    /*******************************************************************************************************
    * @description Contains the logic for performing the Cascade Deletion. The Triggers use this class to 
    * retrieve the children of the records being deleted, validate the deletion of the children and delete them.
    ********************************************************************************************************/
    public class CascadeDelete {
        private Map<Id, SObject> parentsRecords;
        private Map<Id, SObject> childrenRecords;

        private ChildrenLoader childrenLoader;
        private ChildrenValidator childrenValidator;

        private Boolean isValidateOnly;

        /*********************************************************************************************************
        * @description The Constructor of CascadeDelete
        */
        public CascadeDelete() {
            parentsRecords = new Map<Id, SObject>();
            childrenRecords = new Map<Id, SObject>();
            isValidateOnly = false;
        }

        /*******************************************************************************************************
        * @description Sets the parents records that are being deleted. 
        * @return void
        ********************************************************************************************************/
        public void setParents(List<SObject> parentsRecords) {
            this.parentsRecords = new Map<Id, SObject>(parentsRecords);
        }

        /*******************************************************************************************************
        * @description Sets the parents records that are being deleted. 
        * @return void
        ********************************************************************************************************/
        public void validateOnly() {
            isValidateOnly = true;
        }

        /*******************************************************************************************************
        * @description Sets the object that loads the children records.
        * @return void
        ********************************************************************************************************/
        public void setChildrenLoader(ChildrenLoader childrenLoader) {
            this.childrenLoader = childrenLoader;
        }

        /*******************************************************************************************************
        * @description Sets the object that validates the deletion of the children records.
        * @return void
        ********************************************************************************************************/
        public void setChildrenValidator(ChildrenValidator childrenValidator) {
            this.childrenValidator = childrenValidator;
        }

        /*******************************************************************************************************
        * @description Checks if the object that loads the children records exists.
        * @return Boolean
        ********************************************************************************************************/
        public Boolean hasChildrenLoader() {
            return childrenLoader != null;
        }

        /*******************************************************************************************************
        * @description Checks if the object that validate the deletion of the children records exists.
        * @return Boolean
        ********************************************************************************************************/
        public Boolean hasChildrenValidator() {
            return childrenValidator != null;
        }

        /*******************************************************************************************************
        * @description Retrieves the children records, and store the records.
        * @return void
        ********************************************************************************************************/
        public void loadChildren() {
            if (this.childrenLoader != null) {
                List<SObject> loadedChildrenRecords = childrenLoader.loadChildren(parentsRecords.keySet());
                if (childrenRecords != null) {
                    childrenRecords = new Map<Id, SObject>(loadedChildrenRecords);
                }
            }   
        }

        /*******************************************************************************************************
        * @description Validates the deletion of the children records.
        * @return void
        ********************************************************************************************************/
        public void validateChildrenDeletion() {
            if (this.childrenValidator != null) {
                this.childrenValidator.validateChildrenDeletion(parentsRecords.values(), childrenRecords.values());
            }
        }

        /*******************************************************************************************************
        * @description Deletes the children records.
        * @return void
        ********************************************************************************************************/
        public void deleteChildren() {
            if (this.isValidateOnly == false) {
                List<Database.DeleteResult> delResults = Database.delete(childrenRecords.values(), false);
            
                ERR_Handler.Errors errorResult = ERR_Handler.getErrors(delResults, childrenRecords.values());
                if (errorResult.errorsExist) {
                    ERR_Handler.processErrors(errorResult.errorRecords, 'TDTM');
                }
            }
        }

        /*******************************************************************************************************
        * @description Undeletes the children records.
        * @return void
        ********************************************************************************************************/
        public void unDeleteChildren() {
            if (childrenRecords.values().size() > 0) {
                List<Database.UndeleteResult> undelResults = Database.undelete(childrenRecords.values(), false);
                ERR_Handler.Errors errorResult = ERR_Handler.getErrors(undelResults, childrenRecords.values());
                if (errorResult.errorsExist) {
                    ERR_Handler.processErrors(errorResult.errorRecords, 'TDTM');
                }
            }
        }
    }

    /*******************************************************************************************************
    * @description Contains the logic for displaying the error messages
    ********************************************************************************************************/
    public class DeletionError {
        private String parentToDeleteName;
        private Map<String, Map<Id, String>> childrenByErrorType;

        /*********************************************************************************************************
        * @description The Constructor of CascadeDelete
        */
        public DeletionError(String parentToDeleteName) {
            this.parentToDeleteName = parentToDeleteName;
            childrenByErrorType = new Map<String, Map<Id, String>>();
        }

        /*******************************************************************************************************
        * @description Adds a Child record that prevents the parent record deletion
        * @return void
        ********************************************************************************************************/
        public void addChildError(String errorType, Id childRecordId, String childRecordName) {
            if (childrenByErrorType.containsKey(errorType) == false) {
                childrenByErrorType.put(errorType, new Map<Id, String>());
            }

            childrenByErrorType.get(errorType).put(childRecordId, childRecordName);
        }

        /*******************************************************************************************************
        * @description Adds a Child record that prevents the parent record deletion
        * @return The error message
        ********************************************************************************************************/
        public String getMessage() {
            List<String> result = new List<String>();
            if (childrenByErrorType.isEmpty()) {
                return '';
            }

            if (USER_UserService.isUserRunningLightning() || USER_UserService.isUserRunningMobile()) {
                for (String errorType : childrenByErrorType.keySet()) {
                    result.add(errorType + ' (' + getPlainTextChildRecords(childrenByErrorType.get(errorType)) + ')');
                }
                return String.format(Label.CascadeDeletionErrorLightning, new List<String>{parentToDeleteName, String.join(result, ',')});
            }
            else {
                for (String errorType : childrenByErrorType.keySet()) {
                    result.add(errorType + ':' + getHTMLTextChildRecords(childrenByErrorType.get(errorType)));
                }
                return String.format(Label.CascadeDeletionError, new List<String>{parentToDeleteName, String.join(result, '')});
            }
        }

        /*******************************************************************************************************
        * @description Returns an HTML list of the child records preventing deletion, with links to those records.
        * @param childRecords The queried child records preventing the deletion
        * @return String An HTML text that contains a list of the child records.
        ********************************************************************************************************/
        private String getHTMLTextChildRecords(Map<Id, String> childRecords) {
            List<String> result = new List<String>{'<ul>'};
            for (Id childrenRecordId : childRecords.keySet()) {
                result.add(String.format(HTML_TEXT_CHILD_RECORDS_FORMAT, new List<String>{childrenRecordId, childRecords.get(childrenRecordId)}));
            }
            result.add('</ul>');
            
            return String.join(result, '');
        }

        /*******************************************************************************************************
        * @description Returns a Plain Text list of the child records preventing deletion.
        * @param childRecords The queried child records preventing the deletion
        * @return String Plain text that contains a list of the child records.
        ********************************************************************************************************/
        private String getPlainTextChildRecords(Map<Id, String> childRecords) {
            List<String> result = new List<String>();
            for (Id childrenRecordId : childRecords.keySet()) {
                result.add(childRecords.get(childrenRecordId));
            }
            
            return String.join(result, ', ');
        }
    }
}