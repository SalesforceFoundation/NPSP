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

    private static CascadeDelete cascadeDelete;
    private static CascadeUndelete cascadeUndelete;

    public static CascadeDeleteLookupsDomain.CascadeDelete getCascadeDelete() {
        if (cascadeDelete == null) {
            cascadeDelete = new CascadeDelete();
        }
        return cascadeDelete;
    }

    public static CascadeDeleteLookupsDomain.CascadeUndelete getCascadeUndelete() {
        if (cascadeUndelete == null) {
            cascadeUndelete = new CascadeUndelete();
        }
        return cascadeUndelete;
    }

    /*******************************************************************************************************
    * @description Contains the method that a Class needs to implements in order to pass the Children records
    * to the instance of the "CascadeDelete" Class. 
    ********************************************************************************************************/
    public interface DeleteChildrenLoader {
        List<SObject> load(Set<Id> parentIds);
    }

    /*******************************************************************************************************
    * @description Contains the method that a Class needs to implements in order to validate the deletion of
    * the children records. This is run by the instance of the "CascadeDelete" Class.
    ********************************************************************************************************/
    public interface DeleteChildrenValidator {
        List<SObject> validateDeletion(List<SObject> parents, List<SObject> children);
    }

    /*******************************************************************************************************
    * @description Contains the method that a Class needs to implements in order to pass the Children records
    * to the instance of the "CascadeDelete" Class. 
    ********************************************************************************************************/
    public interface UndeleteChildrenLoader {
        List<SObject> load(Set<Id> parentIds);
        UndeleteChildrenLoader next();
    }

    /*******************************************************************************************************
    * @description Contains the logic for performing the Cascade Deletion. The Triggers use this class to 
    * retrieve the children of the records being deleted, validate the deletion of the children and delete them.
    ********************************************************************************************************/
    public class CascadeDelete {
        private Map<Id, SObject> parents;
        private List<SObject> children;

        private DeleteChildrenLoader childrenLoader;
        private DeleteChildrenValidator childrenValidator;

        /*********************************************************************************************************
        * @description The Constructor of CascadeDelete
        */
        public CascadeDelete() {
            parents = new Map<Id, SObject>();
            children = new List<SObject>();
        }

        /*******************************************************************************************************
        * @description Sets the parents records that are being deleted. 
        * @return void
        ********************************************************************************************************/
        public void setParents(List<SObject> parents) {
            this.parents = new Map<Id, SObject>(parents);
        }

        /*******************************************************************************************************
        * @description Sets the object that loads the children records.
        * @return void
        ********************************************************************************************************/
        public void setChildrenLoader(DeleteChildrenLoader childrenLoader) {
            this.childrenLoader = childrenLoader;
        }

        /*******************************************************************************************************
        * @description Sets the object that validates the deletion of the children records.
        * @return void
        ********************************************************************************************************/
        public void setChildrenValidator(DeleteChildrenValidator childrenValidator) {
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
            if (this.childrenLoader == null) {
                return;
            }

            children = childrenLoader.load(parents.keySet());
        }

        /*******************************************************************************************************
        * @description Validates the deletion of the children records.
        * @return void
        ********************************************************************************************************/
        public void validateChildrenDeletion() {
            // separate the statement
            if (this.childrenValidator != null) {
                children = this.childrenValidator.validateDeletion(parents.values(), children);
            }
        }

        /*******************************************************************************************************
        * @description Deletes the children records.
        * @return void
        ********************************************************************************************************/
        public void deleteChildren() {
            if (children.isEmpty()) {
                return;
            }

            List<Database.DeleteResult> deletionResults = Database.delete(children, false);
            ERR_Handler.Errors errorResult = ERR_Handler.getErrors(deletionResults, children);
            if (errorResult.errorsExist) {
                ERR_Handler.processErrors(errorResult.errorRecords, 'TDTM');
            }
        }

        /*******************************************************************************************************
        * @description Undeletes the children records.
        * @return void
        ********************************************************************************************************/
        public void undeleteChildren() {
            if (children.isEmpty()) {
                return;
            }

            List<Database.UndeleteResult> undeleteResults = Database.undelete(children, false);
            ERR_Handler.Errors errorResult = ERR_Handler.getErrors(undeleteResults, children);
            if (errorResult.errorsExist) {
                ERR_Handler.processErrors(errorResult.errorRecords, 'TDTM');
            }
        }
    }

    /*******************************************************************************************************
    * @description Contains the logic for performing the Cascade Deletion. The Triggers use this class to 
    * retrieve the children of the records being deleted, validate the deletion of the children and delete them.
    ********************************************************************************************************/
    public class CascadeUndelete {
        private Set<Id> parentIds;
        private UndeleteChildrenLoader childrenLoader;

        /*********************************************************************************************************
        * @description The Constructor of CascadeUndelete
        */
        public CascadeUndelete() {
            parentIds = new Set<Id>();
        }

        /*******************************************************************************************************
        * @description Sets the parents records that are being deleted. 
        * @return void
        ********************************************************************************************************/
        public void setParents(List<SObject> parents) {
            this.parentIds = new Map<Id, SObject>(parents).keySet();
        }

        /*******************************************************************************************************
        * @description Sets the object that loads the children records.
        * @return void
        ********************************************************************************************************/
        public void setChildrenLoader(UndeleteChildrenLoader childrenLoader) {
            this.childrenLoader = childrenLoader;
        }

        /*******************************************************************************************************
        * @description Undeletes the children records.
        * @return void
        ********************************************************************************************************/
        public void undeleteChildren() {
            UndeleteChildrenLoader currentChildrenLoader = childrenLoader;

            while (currentChildrenLoader != null) {
                List<SObject> children = currentChildrenLoader.load(parentIds);

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
    * @description Contains the logic for displaying the error messages
    ********************************************************************************************************/
    public class DeleteError {
        private String parentToDeleteName;
        private Map<String, Map<Id, String>> childrenByErrorType;

        /*********************************************************************************************************
        * @description The Constructor of CascadeDelete
        */
        public DeleteError(String parentToDeleteName) {
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
        * @description Returns an HTML list of the child records preventing deletion, with links to those records.
        * @param childRecords The queried child records preventing the deletion
        * @return String An HTML text that contains a list of the child records.
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
        * @description Returns a Plain Text list of the child records preventing deletion.
        * @param childRecords The queried child records preventing the deletion
        * @return String Plain text that contains a list of the child records.
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