#!/bin/bash

echo "###############################################################################################"
echo "What this script does:"
echo "1. Reset and/or delete any metadata that is unrelalated to translations"
echo "2. Execute the cci 'cleanup_translation_metadata' task against the metadata to strip invalid or extranous xml content"
echo "3. Update the RD2 unpackaged metadata translations to include special deprecated label overrides"
echo ""
echo ""
echo "When the script has fully completed, the developer should review any pending changes in an IDE, such as VSCode"
echo "to verify that all changes are expected."
echo ""
echo "ONLY changes to the 'objectTranslation' and 'translation' files should be commited to the repository."
echo "ALL OTHER CHANGED FILES SHOULD BE IGNORED."
echo "###############################################################################################"
read -s -n 1 -p "Press any key to continue ..."
echo ""

echo "# ==== CLEANUP task to strip out extraneous elements from the translation files ===="
cci task run cleanup_translation_metadata


echo "# ==== CLEANUP Empty Unpackaged ObjectTranslation Files ===="

rm force-app/main/default/objectTranslations/DuplicateRecordSet*.objectTranslation

rm unpackaged/config/trial/objectTranslations/___NAMESPACE___Allocation__c-*.objectTranslation
rm unpackaged/config/trial/objectTranslations/___NAMESPACE___Batch__c-*.objectTranslation
rm unpackaged/config/trial/objectTranslations/___NAMESPACE___DataImportBatch__c-*.objectTranslation
rm unpackaged/config/trial/objectTranslations/___NAMESPACE___Engagement_Plan_Task__c-*.objectTranslation
rm unpackaged/config/trial/objectTranslations/___NAMESPACE___Engagement_Plan_Template__c-*.objectTranslation
rm unpackaged/config/trial/objectTranslations/___NAMESPACE___Error__c-*.objectTranslation
rm unpackaged/config/trial/objectTranslations/___NAMESPACE___Fund__c-*.objectTranslation
rm unpackaged/config/trial/objectTranslations/___NAMESPACE___Partial_Soft_Credit__c-*.objectTranslation
rm unpackaged/config/trial/objectTranslations/___NAMESPACE___Schedulable__c-*.objectTranslation
rm unpackaged/config/trial/objectTranslations/___NAMESPACE___Trigger_Handler__c-*.objectTranslation

rm unpackaged/post/first/objectTranslations/Global-*.objectTranslation

echo "# ==== Insert special translation overrides for Enhanced Recurring Donations unpackaged metadata ===="

# The GREP command looks for the word "DEPRECATED" in the translation file.
# If it is NOT found, then SED is used to insert the 5 override translations for the fields deprecated in RD2
# and then the backup file created by SED is deleted.
if ! grep -q 'DEPRECATED' unpackaged/config/rd2_post_config/objectTranslations/npe03__Recurring_Donation__c-de.objectTranslation 
then 
    sed -i -e '/<CustomObjectTranslation xmlns="http:\/\/soap.sforce.com\/2006\/04\/metadata">/r localization/rd2_post_config/npe03__Recurring_Donation__c/german.txt' \
        unpackaged/config/rd2_post_config/objectTranslations/npe03__Recurring_Donation__c-de.objectTranslation
    rm unpackaged/config/rd2_post_config/objectTranslations/npe03__Recurring_Donation__c-de.objectTranslation-e
fi

if ! grep -q 'DEPRECATED' unpackaged/config/rd2_post_config/objectTranslations/npe03__Recurring_Donation__c-fr.objectTranslation 
then 
    sed -i -e '/<CustomObjectTranslation xmlns="http:\/\/soap.sforce.com\/2006\/04\/metadata">/r localization/rd2_post_config/npe03__Recurring_Donation__c/french.txt' \
        unpackaged/config/rd2_post_config/objectTranslations/npe03__Recurring_Donation__c-fr.objectTranslation
    rm unpackaged/config/rd2_post_config/objectTranslations/npe03__Recurring_Donation__c-fr.objectTranslation-e
fi

if ! grep -q 'DEPRECATED' unpackaged/config/rd2_post_config/objectTranslations/npe03__Recurring_Donation__c-nl_NL.objectTranslation 
then 
    sed -i -e '/<CustomObjectTranslation xmlns="http:\/\/soap.sforce.com\/2006\/04\/metadata">/r localization/rd2_post_config/npe03__Recurring_Donation__c/dutch.txt' \
        unpackaged/config/rd2_post_config/objectTranslations/npe03__Recurring_Donation__c-nl_NL.objectTranslation
    rm unpackaged/config/rd2_post_config/objectTranslations/npe03__Recurring_Donation__c-nl_NL.objectTranslation-e
fi

if ! grep -q 'DEPRECATED' unpackaged/config/rd2_post_config/objectTranslations/npe03__Recurring_Donation__c-es.objectTranslation 
then 
    sed -i -e '/<CustomObjectTranslation xmlns="http:\/\/soap.sforce.com\/2006\/04\/metadata">/r localization/rd2_post_config/npe03__Recurring_Donation__c/spanish.txt' \
        unpackaged/config/rd2_post_config/objectTranslations/npe03__Recurring_Donation__c-es.objectTranslation
    rm unpackaged/config/rd2_post_config/objectTranslations/npe03__Recurring_Donation__c-es.objectTranslation-e
fi

if ! grep -q 'DEPRECATED' unpackaged/config/rd2_post_config/objectTranslations/npe03__Recurring_Donation__c-ja.objectTranslation 
then 
    sed -i -e '/<CustomObjectTranslation xmlns="http:\/\/soap.sforce.com\/2006\/04\/metadata">/r localization/rd2_post_config/npe03__Recurring_Donation__c/japanese.txt' \
        unpackaged/config/rd2_post_config/objectTranslations/npe03__Recurring_Donation__c-ja.objectTranslation
    rm unpackaged/config/rd2_post_config/objectTranslations/npe03__Recurring_Donation__c-ja.objectTranslation-e
fi

echo "###############################################################################################"
echo "# ==== DONE! - Review the remaining modified translation files before committing back into the branch"
echo "###############################################################################################"
