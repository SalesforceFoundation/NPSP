#!/bin/bash

echo "###############################################################################################"
echo "What this script does:"
echo "1. Create a temporary Scratch Org definition that has the 'sampleData' attribute disabled"
echo "2. Install all underlying package dependencies into the scratch org - using any available beta packages"
echo "3. Deploy all unpackaged metadata to the scratch org"
echo "4. Use the cci 'retrieve_unpackaged' command to retrieve all configuration from the org into the src folder"
echo "5. Reset and/or delete any retrieved metadata that is unrelalated to translations"
echo "6. Execute the cci 'cleanup_translation_metadata' task against the metadata to strip invalid or extranous xml content"
echo "7. Update the RD2 unpackaged metadata translations to include special deprecated label overrides"
echo ""
echo ""
echo "When the script has fully completed, the developer should review any pending changes in an IDE, such as VSCode"
echo "to verify that all changes are expected."
echo ""
echo "ONLY changes to the 'objectTranslation' and 'translation' files should be commited to the repository."
echo "ALL OTHER CHANGED FILES SHOULD BE IGNORED."
echo "###############################################################################################"

read -s -n 1 -p "Press any key to continue ..."

## Verify that JQ is installed before continuing
if ! command -v jq &> /dev/null
then
    echo "JQ is not installed. Use 'brew install jq' to install JQ from the command line."
    exit
fi

ECHO "# === Create a temporary org definition file with sample data disabled"
mv orgs/feature.json orgs/feature-save.json
jq '.hasSampleData = false' orgs/feature-save.json > orgs/temp.json
jq '.orgName = "NPSP - Translations"' orgs/temp.json > orgs/feature.json

ECHO "# ==== CREATE THE SCRATCH ORG ===="
cci org remove translations
cci org scratch feature translations --days 1
cci flow run dependencies --org translations 
cci flow run deploy_unmanaged --org translations
cci task run update_admin_profile --org translations

rm orgs/temp.json
mv orgs/feature-save.json orgs/feature.json

ECHO "# ==== RESET the Package.xml and use retrieve_unpackaged to pull down the metadata ===="
git checkout src/package.xml
cci task run retrieve_unpackaged --org translations -o path src -o package_xml src/package.xml

ECHO "# ==== DISCARD other files pulled down by the above task that we do not need ===="
git checkout src/applications/*
git checkout src/aura/*
git checkout src/classes/*
git checkout src/components/*
git checkout src/customMetadata/*
git checkout src/email/*
git checkout src/featureParameters/*
git checkout src/labels/*
git checkout src/layouts/*
git checkout -- src/lwc
git checkout src/objects/*
git checkout src/pages/*
git checkout src/reports/*
git checkout src/tabs/*
git checkout src/triggers/*
git checkout src/workflows/*
git checkout src/package.xml

ECHO "# ==== CLEANUP Empty Unpackaged ObjectTranslation Files ===="

rm src/objectTranslations/DuplicateRecordSet*.objectTranslation

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

ECHO "# ==== CLEANUP task to strip out extraneous elements from the translation files ===="
cci task run cleanup_translation_metadata

ECHO "# ==== Insert special translation overrides for Enhanced Recurring Donations unpackaged metadata ===="

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

cci org remove translations

ECHO "# ==== DONE! - Review the remaining modified translation files before committing back into the branch"
