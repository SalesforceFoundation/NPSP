#!/bin/bash

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

cci org remove translations

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
git checkout src/objectTranslations/DuplicateRecordSet*
git checkout src/package.xml

ECHO "# ==== CLEANUP Empty Unpackaged ObjectTranslation Files ===="

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

ECHO "# ==== CLEANUP task to strip out extraneous elements from the translation files ===="
cci task run cleanup_translation_metadata

ECHO "# ==== Insert special translation overrides for Enhanced Recurring Donations unpackaged metadata ===="

if ! grep -q 'DEPRECATED' unpackaged/config/rd2_post_config/objectTranslations/npe03__Recurring_Donation__c-de.objectTranslation 
then 
    sed -i -e '/<CustomObjectTranslation xmlns="http:\/\/soap.sforce.com\/2006\/04\/metadata">/r localization/rd2_post_config/npe03__Recurring_Donation__c/german.txt' \
        unpackaged/config/rd2_post_config/objectTranslations/npe03__Recurring_Donation__c-de.objectTranslation
fi

if ! grep -q 'DEPRECATED' unpackaged/config/rd2_post_config/objectTranslations/npe03__Recurring_Donation__c-fr.objectTranslation 
then 
    sed -i -e '/<CustomObjectTranslation xmlns="http:\/\/soap.sforce.com\/2006\/04\/metadata">/r localization/rd2_post_config/npe03__Recurring_Donation__c/french.txt' \
        unpackaged/config/rd2_post_config/objectTranslations/npe03__Recurring_Donation__c-fr.objectTranslation
fi

if ! grep -q 'DEPRECATED' unpackaged/config/rd2_post_config/objectTranslations/npe03__Recurring_Donation__c-nl_NL.objectTranslation 
then 
    sed -i -e '/<CustomObjectTranslation xmlns="http:\/\/soap.sforce.com\/2006\/04\/metadata">/r localization/rd2_post_config/npe03__Recurring_Donation__c/dutch.txt' \
        unpackaged/config/rd2_post_config/objectTranslations/npe03__Recurring_Donation__c-nl_NL.objectTranslation
fi

if ! grep -q 'DEPRECATED' unpackaged/config/rd2_post_config/objectTranslations/npe03__Recurring_Donation__c-es.objectTranslation 
then 
    sed -i -e '/<CustomObjectTranslation xmlns="http:\/\/soap.sforce.com\/2006\/04\/metadata">/r localization/rd2_post_config/npe03__Recurring_Donation__c/spanish.txt' \
        unpackaged/config/rd2_post_config/objectTranslations/npe03__Recurring_Donation__c-es.objectTranslation
fi

if ! grep -q 'DEPRECATED' unpackaged/config/rd2_post_config/objectTranslations/npe03__Recurring_Donation__c-ja.objectTranslation 
then 
    sed -i -e '/<CustomObjectTranslation xmlns="http:\/\/soap.sforce.com\/2006\/04\/metadata">/r localization/rd2_post_config/npe03__Recurring_Donation__c/japanese.txt' \
        unpackaged/config/rd2_post_config/objectTranslations/npe03__Recurring_Donation__c-ja.objectTranslation
fi

## Cleanup the backup files sed creates
rm unpackaged/config/rd2_post_config/objectTranslations/npe03__Recurring_Donation__c-de.objectTranslation-e
rm unpackaged/config/rd2_post_config/objectTranslations/npe03__Recurring_Donation__c-fr.objectTranslation-e
rm unpackaged/config/rd2_post_config/objectTranslations/npe03__Recurring_Donation__c-es.objectTranslation-e
rm unpackaged/config/rd2_post_config/objectTranslations/npe03__Recurring_Donation__c-nl_NL.objectTranslation-e
rm unpackaged/config/rd2_post_config/objectTranslations/npe03__Recurring_Donation__c-ja.objectTranslation-e

ECHO "# ==== DONE! - Review the remaining modified translation files before committing back into the branch"
