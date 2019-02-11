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
* @description Service method explicitly related to batch or queueable rollup operations
*/
public class CRLP_RollupBatch_SVC {

    /** @description Custom Settings record that defines specific Customizable Rollups settings */
    private static final Customizable_Rollup_Settings__c customizableRollupSettings = UTIL_CustomSettingsFacade.getCustomizableRollupSettings();

    /**
     * @description Returns the Summary ObjectType based on the specific JobType
     * @param jobType Rollup Job Type Enum
     */
    public static SObjectType getSummaryObjectType(CRLP_RollupProcessingOptions.RollupType jobType) {
        if (jobType == CRLP_RollupProcessingOptions.RollupType.AccountHardCredit ||
                jobType == CRLP_RollupProcessingOptions.RollupType.AccountContactSoftCredit ||
                jobType == CRLP_RollupProcessingOptions.RollupType.AccountSoftCredit) {
            return Account.SObjectType;
        } if (jobType == CRLP_RollupProcessingOptions.RollupType.ContactHardCredit ||
                jobType == CRLP_RollupProcessingOptions.RollupType.ContactSoftCredit) {
            return Contact.SObjectType;
        } if (jobType == CRLP_RollupProcessingOptions.RollupType.GAU) {
            return General_Accounting_Unit__c.SObjectType;
        } if (jobType == CRLP_RollupProcessingOptions.RollupType.RecurringDonations) {
            return npe03__Recurring_Donation__c.SObjectType;
        }
        return null;
    }

    /**
     * @description Returns a portion of the WHERE clause to use to filter "Skew" or "NonSkew" mode records. This is
     * effectively the only place where the fields needed to make this determination are referenced.
     * @param jobType Rollup Job Type Enum
     * @param jobMode Batch Job Mode (Skew or NonSkew)
     * @return A portion of a WHERE clause without WHERE or AND; or an empty string
     */
    public static String getSkewWhereClause(CRLP_RollupProcessingOptions.RollupType jobType, CRLP_RollupProcessingOptions.BatchJobMode jobMode) {
        return getSkewWhereClause(jobType, jobMode, '');
    }

    /**
     * @description Returns a portion of the WHERE clause to use to filter "Skew" or "NonSkew" mode records. This is
     * effectively the only place where the fields needed to make this determination are referenced.
     * @param jobType Rollup Job Type Enum
     * @param jobMode Batch Job Mode (Skew or NonSkew)
     * @param parentRelationshipField If the query this where clause will be used on is the detail object, then need
     * the parent relationship prefix to use with the conditions
     * @return A portion of a WHERE clause without WHERE or AND; or an empty string
     */
    public static String getSkewWhereClause(CRLP_RollupProcessingOptions.RollupType jobType, CRLP_RollupProcessingOptions.BatchJobMode jobMode,
            String parentRelationshipField) {
        String queryFilter = '';
        Integer maxRelatedOppsForNonLDVMode = CRLP_Rollup_SVC.getMaxRelatedOppsForNonSkewMode();

        // If the Summary Object is the Account, then filter on Accounts that have at least a single
        // Opportunity attached. This is helpful to reduce the overall query size.
        // To handle a scenario where an attached Oppportunity was deleted, but the record not recalculated
        // also include any records where the TotalGifts or TotalMemberships fields are not zero.
        // If the field is null, a query with "< #" will not work. "= null" must be explicitly included in the query.
        if (jobType == CRLP_RollupProcessingOptions.RollupType.ContactHardCredit ||
                jobType == CRLP_RollupProcessingOptions.RollupType.AccountHardCredit) {

            if (jobMode == CRLP_RollupProcessingOptions.BatchJobMode.NonSkewMode) {
                queryFilter = '(' + parentRelationshipField + 'npo02__NumberOfClosedOpps__c = null OR ' + parentRelationshipField +
                    'npo02__NumberOfClosedOpps__c < ' + maxRelatedOppsForNonLDVMode + ') ' +
                    'AND (' + parentRelationshipField + 'npo02__NumberOfMembershipOpps__c = null OR ' + parentRelationshipField +
                    'npo02__NumberOfMembershipOpps__c < ' + maxRelatedOppsForNonLDVMode + ')';
            } else {
                queryFilter = '(' + parentRelationshipField + 'npo02__NumberOfClosedOpps__c >= ' + maxRelatedOppsForNonLDVMode +
                        ' OR ' + parentRelationshipField + 'npo02__NumberOfMembershipOpps__c >= ' + maxRelatedOppsForNonLDVMode + ')';
            }

        } else if (jobType == CRLP_RollupProcessingOptions.RollupType.ContactSoftCredit) {

            String softCreditField = parentRelationshipField + UTIL_Namespace.StrAllNSPrefix('Number_of_Soft_Credits__c');
            if (jobMode == CRLP_RollupProcessingOptions.BatchJobMode.NonSkewMode) {
                queryFilter = '(' + softCreditField + ' = null OR ' + softCreditField + ' < ' + maxRelatedOppsForNonLDVMode + ')';
            } else {
                queryFilter = '(' + softCreditField + ' >= ' + maxRelatedOppsForNonLDVMode + ')';
            }

        } else if (jobType == CRLP_RollupProcessingOptions.RollupType.AccountContactSoftCredit ||
                jobType == CRLP_RollupProcessingOptions.RollupType.AccountSoftCredit) {
            // TODO -- How to get Accounts that require using this method for Soft Credits??
            // For now just use the NumberOfClosedOpportunities field as a proxy for the number of SoftCredits
            String softCreditField = parentRelationshipField + 'npo02__NumberOfClosedOpps__c';
            if (jobMode == CRLP_RollupProcessingOptions.BatchJobMode.NonSkewMode) {
                queryFilter = '(' + softCreditField + ' = null OR ' + softCreditField + ' < ' + maxRelatedOppsForNonLDVMode + ')';
            } else {
                queryFilter = '(' + softCreditField + ' >= ' + maxRelatedOppsForNonLDVMode + ')';
            }

        } else if (jobType == CRLP_RollupProcessingOptions.RollupType.GAU) {
            // no extra filter on this type since we're always processing all GAU's using the skew method

        } else if (jobType == CRLP_RollupProcessingOptions.RollupType.RecurringDonations) {

            String rdInstallmentCountField = 'npe03__Total_Paid_Installments__c';
            if (jobMode == CRLP_RollupProcessingOptions.BatchJobMode.NonSkewMode) {
                queryFilter = '(' + rdInstallmentCountField + ' = null OR ' + rdInstallmentCountField + ' < ' + maxRelatedOppsForNonLDVMode + ')';
            } else {
                queryFilter = '(' + rdInstallmentCountField + ' >= ' + maxRelatedOppsForNonLDVMode + ')';
            }

        }

        return queryFilter;
    }

    /**
     * @description Determine if a given record Id needs to use the Skew rollup method.
     * @param recordId The specific record Id to verify
     * @param jobType Rollup Job Type Enum
     * @return True or False
     */
    public static Boolean doesRecordNeedSkewRollupMethod(Id recordId, CRLP_RollupProcessingOptions.RollupType jobType) {
        if (jobType == CRLP_RollupProcessingOptions.RollupType.AccountHardCredit ||
                jobType == CRLP_RollupProcessingOptions.RollupType.ContactHardCredit ||
                jobType == CRLP_RollupProcessingOptions.RollupType.AccountContactSoftCredit ||
                jobType == CRLP_RollupProcessingOptions.RollupType.ContactSoftCredit) {
            String objName = recordId.getSobjectType().getDescribe().getName();
            String soql = 'SELECT Id FROM ' + objName + ' WHERE Id = :recordID ';
            String filter = getSkewWhereClause(jobType, CRLP_RollupProcessingOptions.BatchJobMode.SkewMode);
            if (!String.isEmpty(filter)) {
                soql += ' AND ' + filter;
            }
            List<SObject> cntObj = database.query(soql);
            return cntObj.size() == 1;
        }
        return true;
    }

    public static void executeBatchRollupJob(CRLP_RollupProcessingOptions.RollupType jobType,
            CRLP_RollupProcessingOptions.BatchJobMode jobMode) {
        executeBatchRollupJob(jobType, jobMode, null, null);
    }

    /**
     * @description Centralized Rollup Batch Job execution based on the Job Type, Batch Job Mode, etc.
     * @param jobType Rollup Job Type Enum
     * @param jobMode Batch Mode Enum (Skew or NonSkew)
     * @param recordIds (Optional) List of Record Id's to be rolled up
     * @param lastIdProcessed (Optional) If this is being called by the SkewDispatcher class, the last record id of
     * the parent records is passed into the batch job to allow it to be passed back to the SkewDispatcher to
     * support chunking by Id.
     */
    public static void executeBatchRollupJob(CRLP_RollupProcessingOptions.RollupType jobType, 
            CRLP_RollupProcessingOptions.BatchJobMode jobMode, List<Id> recordIds, Id lastIdProcessed) {

        Integer batchSize = getBatchSize(jobType, jobMode);
        if (jobMode == CRLP_RollupProcessingOptions.BatchJobMode.SkewMode) {
            if (jobType == CRLP_RollupProcessingOptions.RollupType.AccountHardCredit) {
               database.executeBatch(new CRLP_AccountSkew_BATCH(recordIds, lastIdProcessed), batchSize);
            } else if (jobType == CRLP_RollupProcessingOptions.RollupType.AccountSoftCredit) {
                database.executeBatch(new CRLP_AccountSkew_AccSoftCredit_BATCH(recordIds, lastIdProcessed), batchSize);
            } else if (jobType == CRLP_RollupProcessingOptions.RollupType.ContactHardCredit) {
                database.executeBatch(new CRLP_ContactSkew_BATCH(recordIds, lastIdProcessed), batchSize);
            } else if (jobType == CRLP_RollupProcessingOptions.RollupType.AccountContactSoftCredit) {
               database.executeBatch(new CRLP_AccountSkew_SoftCredit_BATCH(recordIds, lastIdProcessed), batchSize);
            } else if (jobType == CRLP_RollupProcessingOptions.RollupType.ContactSoftCredit) {
               database.executeBatch(new CRLP_ContactSkew_SoftCredit_BATCH(recordIds, lastIdProcessed), batchSize);
            } else if (jobType == CRLP_RollupProcessingOptions.RollupType.GAU) {
               database.executeBatch(new CRLP_GAU_BATCH(recordIds, lastIdProcessed), batchSize);
            } else if (jobType == CRLP_RollupProcessingOptions.RollupType.RecurringDonations) {
               database.executeBatch(new CRLP_RDSkew_BATCH(recordIds, lastIdProcessed), batchSize);
            }
        } else {
            if (jobType == CRLP_RollupProcessingOptions.RollupType.AccountHardCredit) {
                database.executeBatch(new CRLP_Account_BATCH(recordIds), batchSize);
            } else if (jobType == CRLP_RollupProcessingOptions.RollupType.AccountSoftCredit) {
                database.executeBatch(new CRLP_Account_AccSoftCredit_BATCH(recordIds), batchSize);
            } else if (jobType == CRLP_RollupProcessingOptions.RollupType.ContactHardCredit) {
                database.executeBatch(new CRLP_Contact_BATCH(recordIds), batchSize);
            } else if (jobType == CRLP_RollupProcessingOptions.RollupType.AccountContactSoftCredit) {
                database.executeBatch(new CRLP_Account_SoftCredit_BATCH(recordIds), batchSize);
            } else if (jobType == CRLP_RollupProcessingOptions.RollupType.ContactSoftCredit) {
                database.executeBatch(new CRLP_Contact_SoftCredit_BATCH(recordIds), batchSize);
            } else if (jobType == CRLP_RollupProcessingOptions.RollupType.GAU) {
                // Technically this job is always processed in "skew" mode
                database.executeBatch(new CRLP_GAU_BATCH(recordIds, lastIdProcessed), batchSize);
            } else if (jobType == CRLP_RollupProcessingOptions.RollupType.RecurringDonations) {
                database.executeBatch(new CRLP_RD_BATCH(recordIds), batchSize);
            }
        }
    }

    /**
     * @description Return the batch size to use for the specified Rollup Job and Rollup Type. Note that this is
     * usedd to return a batch size for legacy rollup jobs as well since technically they fall into the same Account &
     * Contact Hard/Soft credit operations. Only "Rollup" batch jobs should use this method though. Other batch jobs,
     * such as SeasonalAddresses can access their specific batch size setting through the appropriate
     * CustomSettingsFacade method.
     * @param jobType Job Type Enum
     * @param jobMode Batch Job Mode Enum
     * @return Integer value
     */
    public static Integer getBatchSize(CRLP_RollupProcessingOptions.RollupType jobType, CRLP_RollupProcessingOptions.BatchJobMode jobMode) {
        Integer batchSize;

        try {
            if (jobMode == CRLP_RollupProcessingOptions.BatchJobMode.NonSkewMode) {
                if (jobType == CRLP_RollupProcessingOptions.RollupType.AccountHardCredit) {
                    batchSize = customizableRollupSettings.Rollups_Account_Batch_Size__c.intValue();

                } else if (jobType == CRLP_RollupProcessingOptions.RollupType.ContactHardCredit) {
                    batchSize = customizableRollupSettings.Rollups_Contact_Batch_Size__c.intValue();

                } else if (jobType == CRLP_RollupProcessingOptions.RollupType.AccountContactSoftCredit) {
                    batchSize = customizableRollupSettings.Rollups_Account_Soft_Credit_Batch_Size__c.intValue();

                } else if (jobType == CRLP_RollupProcessingOptions.RollupType.ContactSoftCredit) {
                    batchSize = customizableRollupSettings.Rollups_Contact_Soft_Credit_Batch_Size__c.intValue();

                } else if (jobType == CRLP_RollupProcessingOptions.RollupType.GAU) {
                    batchSize = customizableRollupSettings.Rollups_GAU_Batch_Size__c.intValue();

                } else if (jobType == CRLP_RollupProcessingOptions.RollupType.RecurringDonations) {
                    batchSize = UTIL_CustomSettingsFacade.getRecurringDonationsSettings().Recurring_Donation_Batch_Size__c.intValue();
                }

            } else {

                if (jobType == CRLP_RollupProcessingOptions.RollupType.AccountHardCredit) {
                    batchSize = customizableRollupSettings.Rollups_Account_SkewMode_Batch_Size__c.intValue();

                } else if (jobType == CRLP_RollupProcessingOptions.RollupType.ContactHardCredit) {
                    batchSize = customizableRollupSettings.Rollups_Contact_SkewMode_Batch_Size__c.intValue();

                } else if (jobType == CRLP_RollupProcessingOptions.RollupType.AccountContactSoftCredit) {
                    batchSize = customizableRollupSettings.Rollups_Account_SkewMode_Batch_Size__c.intValue();

                } else if (jobType == CRLP_RollupProcessingOptions.RollupType.ContactSoftCredit) {
                    batchSize = customizableRollupSettings.Rollups_Contact_SkewMode_Batch_Size__c.intValue();

                } else if (jobType == CRLP_RollupProcessingOptions.RollupType.GAU) {
                    batchSize = customizableRollupSettings.Rollups_GAU_Batch_Size__c.intValue();

                } else if (jobType == CRLP_RollupProcessingOptions.RollupType.RecurringDonations) {
                    batchSize = UTIL_CustomSettingsFacade.getRecurringDonationsSettings().Recurring_Donation_Batch_Size__c.intValue();
                }
            }
        } catch (Exception ex) {
            // ignore null pointer exception errors because a default will be returned
        }

        // Legacy Batch Job Sizes are limited to 200 (this is hardcoded in UTIL_AbstractRollup_BATCH)
        if (customizableRollupSettings.Customizable_Rollups_Enabled__c != true && batchSize > 200) {
            batchSize = 200;
        }
        return (batchSize != null ? batchSize : 200);
    }
}