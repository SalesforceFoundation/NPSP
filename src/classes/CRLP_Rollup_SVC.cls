/*
    Copyright (c) 2018, Salesforce.org
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
* @date 2018
* @group Rollups
* @group-content ../../ApexDocContent/Rollups2.htm
* @description Service class for general rollup operations. Includes the interface for the per-rollup-type
* handler service classes.
* This class Service Class is limited to generic Service Methods used throughout the entire scope of the
* Customizable Rollups engine. Methods that are specific to data operations (Triggers, Batch, and Queueables)
* are stored in the CRLP_RollupProcessor_SVC class.
*/
public class CRLP_Rollup_SVC {

    private static final Boolean DO_NOT_UPDATE_NULL_TO_ZERO = false;

    /** @description Custom Settings record that defines specific Customizable Rollups settings */
    private static final Customizable_Rollup_Settings__c customizableRollupSettings = UTIL_CustomSettingsFacade.getCustomizableRollupSettings();

    /**
     * @description Interface class that the each of the 5 handler classes will implement
     */
    public interface IRollupHandler {
        void processRollups(List<SObject> details, Map<Id, List<SObject>> childRecordsByDetailId);
        void setRecordId(Id objectId);
        void setRollupsList(List<CRLP_Rollup> rollups);
        void setRollupTypeFilter(CRLP_RollupProcessingOptions.RollupTypeFilter jobFilter);
        List<CRLP_Rollup> getRollupsList();
        SObject getPopulatedSObject();
        Set<Id> getListOfOppIdsThatWereRolledUp();
    }

    /**
     * @description Returns the DescribeFieldResult
     * @param rollup fully qualified api field name (Object.Field)
     * @return DescribeFieldResult
     */
    public static Schema.DescribeFieldResult getSObjectFieldDescribe(String objName, String fldName) {
        if (fldName  != null) {
            return UTIL_Describe.getAllFieldsDescribe(objName).get(fldName.toLowerCase());
        } else {
            return null;
        }
    }

    /**
     * @description Rather than recreate the empty Summary SObject every time, we'll cache an empty version
     * of the record with no Id. This will be cloned each time and the Id set before returning the record.
     * Testing shows that caching an empty SObject and cloning is nearly 10 times faster than recreating each time.
     */
    private static Map<SObjectType, SObject> cachedEmptyObjects = new Map<SObjectType, SObject>();

    /**
     * @description Creates an empty target (summary) SObject with all of the specific rollup target fields
     * set to null, but only for the specific rollups passed as a parameter.
     * TODO: Support extending this for archived records.
     * @param objectId Target object Id.
     * @param rollups The specific list of Rollups to clear the target field values.
     * @return An empty SObject.
     */
    public static SObject createEmptyResultObject(Id objectId, List<CRLP_Rollup> rollups) {
        SObjectType objType = objectId.getSobjectType();
        if (!cachedEmptyObjects.containsKey(objType)) {
            SObject emptyObject = UTIL_Describe.getPrototypeObject(objType.getDescribe().getName());
            for (CRLP_Rollup rollup : rollups) {
                for (Integer ns=0, listSize=rollup.rollupsMdt.size(); ns<listSize; ns++) {
                    emptyObject.put(rollup.rollupsMdt[ns].summaryField, null);
                }
            }
            cachedEmptyObjects.put(objType, emptyObject);
        }
        SObject emptyObject = cachedEmptyObjects.get(objType).clone(false, true);
        emptyObject.put('Id', objectId);
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
            for (Integer ns=0, listSize=rollup.rollupsMdt.size(); ns<listSize; ns++) {
                CRLP_Rollup.Rollupmdt r = rollup.rollupsMdt[ns];
                Schema.DescribeFieldResult summaryField = getSObjectFieldDescribe(r.summaryObject, r.summaryField);
                SoapType summaryFieldType = summaryField.getSoapType();
                Object origValue = originalObject.get(summaryField.getName());
                Object newValue = updatedObject.get(summaryField.getName());
                if (summaryFieldType == SoapType.STRING && (origValue != null || newValue != null)) {
                    // Handle an empty string as null to prevent unecessary DML updates
                    String origString = (origValue != null ? (String)origValue : null);
                    String newString = (newValue != null ? (String)newValue : null);
                    origString = (String.isEmpty(origString) ? null : origString);
                    newString = (String.isEmpty(newString) ? null : newString);
                    if (origString != newString) {
                        hasValueChanged = true;
                    }
                } else if (DO_NOT_UPDATE_NULL_TO_ZERO == false && summaryFieldType == SoapType.DOUBLE) {
                    // If the value in the object is null and the updated value is something other than null or zero,
                    // then the record has been changed. Otherwise, don't update a NULL value to zero or vice-versa.
                    Double origNumber = (origValue != null ? (Double)origValue : 0);
                    Double newNumber = (newValue != null ? (Double)newValue : 0);
                    if (origNumber != newNumber) {
                        hasValueChanged = true;
                    }
                } else if (origValue != newValue) {
                    hasValueChanged = true;
                }
                if (hasValueChanged) {
                    break;
                }
            }
        }
        return hasValueChanged;
    }

    /**
    * @description Returns true if the new Customizable Rollups Engine is enabled (i.e., Do Not Run Legacy Rollups)
    */
    public static Boolean isCustomizableRollupEngineEnabled {
        get {
            return (customizableRollupSettings.Customizable_Rollups_Enabled__c == true);
        } private set;
    }

    /**
     * @description Get the setting that defines the max number of attached Opportunities an Account can
     * have before it's considered an LDV data scenario.
     * @return Integer value
     */
    public static Integer getMaxRelatedOppsForNonSkewMode() {
        return customizableRollupSettings.Rollups_Limit_on_Attached_Opps_for_Skew__c.intValue();
    }

    /**
     * @description Are there active Rollup Definition records for the provided SObject?
     * @param SObjectType
     * @return True or False
     */
    public static Boolean hasActiveRollupsForSObject(SObjectType sObj) {
        try {
            for (Rollup__mdt r : CRLP_Rollup_SEL.getRollupsBySummaryType().get(sObj)) {
                if (r.Active__c == true) {
                    return true;
                }
            }
        } catch (Exception ex){ }
        return false;
    }

    /**
     * @description Are there active Partial Soft Credit Rollup Definition records for the provided SObject?
     * @param SObjectType
     * @return True or False
     */
    public static Boolean hasActivePartialSoftCreditRollupsForSObject(SObjectType sObj) {
        String pscObjectName = UTIL_Describe.getObjectDescribe(UTIL_Namespace.StrAllNSPrefix('Partial_Soft_Credit__c')).getName();
        try {
            for (Rollup__mdt r : CRLP_Rollup_SEL.getRollupsBySummaryType().get(sObj)) {
                if (r.Active__c == true && r.Amount_Object__r.QualifiedApiName == pscObjectName) {
                    return true;
                }
            }
        } catch (Exception ex){ }
        return false;
    }

    /**
     * @description Are there active Account Soft Credit Rollup Definition records for the provided SObject?
     * @param SObjectType
     * @return True or False
     */
    public static Boolean hasActiveAccountSoftCreditRollupsForSObject(SObjectType sObj) {
        String accSCObjectName = UTIL_Describe.getObjectDescribe(UTIL_Namespace.StrTokenNSPrefix('Account_Soft_Credit__c')).getName();
        try {
            for (Rollup__mdt r : CRLP_Rollup_SEL.getRollupsBySummaryType().get(sObj)) {
                if (r.Active__c == true && r.Amount_Object__r.QualifiedApiName == accSCObjectName) {
                    return true;
                }
            }
        } catch (Exception ex){ }
        return false;
    }


    /**
     * @description Are there active Payment Rollup Definition records for the provided SObject?
     * @param SObjectType
     * @return True or False
     */
    public static Boolean hasActivePaymentRollupsForSObject(SObjectType sObj) {
        String pmtObjectName = UTIL_Describe.getObjectDescribe('npe01__OppPayment__c').getName();
        try {
            for (Rollup__mdt r : CRLP_Rollup_SEL.getRollupsBySummaryType().get(sObj)) {
                if (r.Active__c == true && r.Amount_Object__r.QualifiedApiName == pmtObjectName) {
                    return true;
                }
            }
        } catch (Exception ex){ }
        return false;
    }

    public class CRLP_Exception extends Exception {}
}