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
 * @description Extend this to allow cascade delete and undelete of child objects through lookup relationships.
 * 
 * The only differences in functionality with standard cascade deletion is that child records show up separately from
 * their parent in the recycle bin, and all triggers run on cascade deleted objects.
 *
 * To enable cascade delete for a new object type: extend this class, override the getDeletionChildrenLoader(), 
 * getUndeletionChildrenLoader() and getDeletionChildrenValidator() methods. The method getDeletionChildrenValidator()
 * is optional, and should override only validation of the children is needed.
 *
 * NOTE: Since standard cascade deletes don't run triggers on deleted children, records in the "cascades" map can also
 * be created for children further down the chain, e.g. grandchildren, great-grandchildren, etc. The relationship to 
 * the deleted parent object can be provided to allow cascade functionality for those parent objects.
 */
//TBD making this class global so managed package users can add lookup cascade deletions

public abstract class CascadeDeleteLookups_TDTM extends TDTM_Runnable {

    /*******************************************************************************************************
    * @description Performs cascade delete for lookup fields. Stashes records, deletes records, or undeletes
    * records depending on trigger action.
    * @param listNew The list of sobjects from trigger new.
    * @param listOld The list of sobjects from trigger old.
    * @param triggerAction Which action triggered the current context. (Before or After; Insert, Update, 
    * Delete, or Undelete.)
    * @param objResult The field describe object for the current trigger set.
    * @return dmlWrapper Objects that need to be inserted or updated after the processing of the trigger.
    ********************************************************************************************************/
    public override DmlWrapper run(List<SObject> newlist, List<SObject> oldlist, 
        TDTM_Runnable.Action triggerAction, Schema.DescribeSObjectResult objResult) {

        if (TDTM_ProcessControl.isRecursive(TDTM_ProcessControl.flag.CascadeDeletes)) {
            return null;
        }

        if (triggerAction == TDTM_Runnable.Action.BeforeDelete) {
            CascadeDeleteLookupsDomain.CascadeDelete cascadeDelete = CascadeDeleteLookupsDomain.getCascadeDelete();
            cascadeDelete.setParents(oldlist);
            if (cascadeDelete.hasChildrenLoader() == false) {
                cascadeDelete.setChildrenLoader(getDeletionChildrenLoader());
            }
            if (cascadeDelete.hasChildrenValidator() == false) {
                cascadeDelete.setChildrenValidator(getDeletionChildrenValidator());
            }
            cascadeDelete.loadChildren();
            cascadeDelete.validateChildrenDeletion();
        }

        if (triggerAction == TDTM_Runnable.Action.AfterDelete) {
            //if this trigger context is the result of a merge, exit trigger without performing deletion
            try {
                if (String.isNotBlank(String.valueOf(oldlist[0].get('MasterRecordId')))) {
                    return null;
                }
            } catch (Exception ex) {}

            TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.flag.CascadeDeletes, true);
            CascadeDeleteLookupsDomain.CascadeDelete cascadeDelete = CascadeDeleteLookupsDomain.getCascadeDelete();
            cascadeDelete.deleteChildren();
            TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.flag.CascadeDeletes, false);
        }

        if (triggerAction == TDTM_Runnable.Action.AfterUndelete) {
            TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.flag.CascadeDeletes, true);
            CascadeDeleteLookupsDomain.CascadeUndelete cascadeUndelete = CascadeDeleteLookupsDomain.getCascadeUndelete();
            cascadeUndelete.setParents(newlist);
            cascadeUndelete.setChildrenLoader(getUndeletionChildrenLoader());
            cascadeUndelete.undeleteChildren();
            TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.flag.CascadeDeletes, false);
        }

        return null;
    }

    /*******************************************************************************************************
    * @description Gets the Delete ChildrenLoader Object of the running Trigger.
    * @return CascadeDeleteLookupsDomain.DeleteChildrenLoader
    ********************************************************************************************************/
    protected virtual CascadeDeleteLookupsDomain.DeleteChildrenLoader getDeletionChildrenLoader() {
        return null;
    }

    /*******************************************************************************************************
    * @description Gets the Undelete ChildrenLoader Object of the running Trigger. 
    * @return CascadeDeleteLookupsDomain.UndeleteChildrenLoader
    ********************************************************************************************************/
    protected virtual CascadeDeleteLookupsDomain.UndeleteChildrenLoader getUndeletionChildrenLoader() {
        return null;
    }

    /*******************************************************************************************************
    * @description Gets the ChildrenValidator Object of the running Trigger. 
    * @return CascadeDeleteLookupsDomain.DeleteChildrenValidator
    ********************************************************************************************************/
    protected virtual CascadeDeleteLookupsDomain.DeleteChildrenValidator getDeletionChildrenValidator() {
        return null;
    }
}