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
* @group Rollups
* @group-content ../../ApexDocContent/Rollups2.htm
* @description Service class for general rollup operations. Includes the interface for the per-rollup-type
*   handler service classes.
*
*   This class should pertain only to service operations shared across the rollup engine.
*/
public class CRLP_Rollup_SVC {

    /**
     * @description Interface class that the each of the 5 handler classes will implement
     */
    public interface IRollupHandler {
        void processRollups(List<SObject> details);
        void setRecordId(Id objectId);
        void setRollupsList(List<CRLP_Rollup> rollups);
        SObject getPopulatedSObject();
    }

    /**
     * @description Returns the DescribeFieldResult
     * @param rollup fully qualified api field name (Object.Field)
     * @return DescribeFieldResult
     */
    public static Schema.DescribeFieldResult getSobjectFieldFromRollup(String objName, String fldName) {
        if (fldName  != null) {
            return UTIL_Describe.getAllFieldsDescribe(objName).get(fldName.toLowerCase());
        } else {
            return null;
        }
    }

    /**
     * @description Creates an empty target (summmary) SObject with all of the specific rollup target fields
     * set to null, but only for the specific rollups passed as a parameter.
     * TODO: Support extending this for archived records.
     * @param objectId Target object Id.
     * @param rollups The specific list of Rollups to clear the target field values.
     * @return An empty SObject.
     */
    public static SObject createEmptyResultObject(Id objectId, List<CRLP_Rollup> rollups) {
        SObject emptyObject = UTIL_Describe.getPrototypeObject(objectId.getSobjectType().getDescribe().getName());
        emptyObject.put('Id', objectId);
        for (CRLP_Rollup rollup : rollups) {
            for (Rollup__mdt r : rollup.rollupsMdt) {
                emptyObject.put(r.Summary_Field__r.QualifiedApiName, null);
            }
        }
        return emptyObject;
    }

    /**
     * @description Returns true if the updated object (as returned by getPopulatedSObject()) has any different
     * values in the summary object fields affected by the rollups. Note that NULL is not equivalent to ZERO
     * for purposes of this comparison.
     * @param originalObject
     * @param updatedObject
     * @param rollups List of RLLP_Rollup_SVC.Rollup instances of the specific Rollups that were calculated and
     * need to be compared.
     * @return True (changed) or False (not changed)
     */
    public static Boolean resultsNeedUpdate(SObject originalObject, SObject updatedObject,
                List<CRLP_Rollup> rollups) {
        Boolean hasValueChanged = false;
        for (CRLP_Rollup rollup : rollups) {
            for (Rollup__mdt r : rollup.rollupsMdt) {
                Schema.DescribeFieldResult summaryField = getSobjectFieldFromRollup(r.Summary_Object__r.QualifiedApiName, r.Summary_Field__r.QualifiedApiName);
                Object origValue = originalObject.get(summaryField.getName());
                Object newValue = updatedObject.get(summaryField.getName());
                if (origValue != newValue) {
                    hasValueChanged = true;
                }
                /*if (rollup.fldType == SoapType.DOUBLE) {
                    // If the value in the object is null and the updated value is something other than null or zero,
                    // then the record has been changed
                    if (origValue == null && newValue != null & (Double)newValue != 0) {
                        hasValueChanged = true;
                    } else if (origValue != null && (Double)origValue != (Double)newValue) {
                        hasValueChanged = true;
                    }
                }*/
                if (hasValueChanged) {
                    break;
                }
            }
        }
        return hasValueChanged;
    }

    /**
     * @description Called by Update triggers to determine if a rollup recalculation is required for a given record
     * @param newRecord
     * @param oldRecord
     * @return Boolean
     */
    public static Boolean isRollupRecalcNeeded(SObject newRecord, SObject oldRecord) {

        if (oldRecord == null) {
            return true;
        }

        SObjectType objType = newRecord.getSObjectType();

        // Start by getting all the fields referenced by any Filter Group or active Rollup
        List<Schema.DescribeFieldResult> fieldsToCompare = new List<DescribeFieldResult>();
        fieldsToCompare.addAll(CMT_FilterRule_SEL.getReferencedFieldsByObject(objType));
        fieldsToCompare.addAll(CRLP_Rollup_SEL.getReferencedFieldsByObject(objType));

        // Loop through the FieldDescribeResults list and compare the value of each field between the
        // old and new objects.
        Boolean changed = false;
        for (DescribeFieldResult dfr : fieldsToCompare) {
            Object oldVal = oldRecord.get(dfr.name);
            Object newVal = newRecord.get(dfr.name);
            if (oldVal != newVal) {
                changed = true;
                break;
            }
        }
        return changed;
    }
}