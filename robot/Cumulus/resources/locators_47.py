"""Locators for Winter '20"""

from locators_48 import *

npsp_lex_locators = npsp_lex_locators.copy()
npsp_lex_locators['record']['button']="//div[@class='actionsContainer']/button[@title='{}']"
npsp_lex_locators.update({
    'confirm': {
        'check_value':'//div[contains(@class, "forcePageBlockItem") or contains(@class, "slds-form-element_stacked")][.//span[text()="{}"]]//following-sibling::div[.//span[contains(@class, "test-id__field-value")]]/span',
        'check_status':'//div[contains(@class, "field-label-container")][.//span[text()="{}"]]//following-sibling::div[.//span[contains(@class, "test-id__field-value")]]/span//lightning-formatted-text',
        'check_numbers':'//div[contains(@class, "field-label-container")][.//span[text()="{}"]]//following-sibling::div[.//span[contains(@class, "test-id__field-value")]]/span//lightning-formatted-number',
    },
    'data_imports':{
        'status':'//div[contains(@class,"slds-tile__title")][./p[text()="BDI_DataImport_BATCH"]]/div[contains(@class,"slds-col")]/span[text()="{}"]',
        'checkbox':'//tr[./th//a[@title="{}"]]/td//span[@class="slds-checkbox--faux"]',
        'actions_dd':'//a[contains(@title,"more actions")and @aria-expanded="true"]',
        },
    'delete_icon_record':'//span[contains(text() ,"{}")]/following::span[. = "{}"]/following-sibling::a/child::span[@class = "deleteIcon"]',
    'link-contains':'//a[contains(@title,"{}")]',
    'related_list_items':'//div[@class = "forceRelatedListContainer"][.//a[contains(@class, "slds-card")]]//span[text() = "{}"]/ancestor::div[contains(@class, "slds-card")]/following-sibling::div[contains(@class, "slds-card")][.//div[contains(@class, "outputLookupContainer")]]//a[text()="{}"]',
    
    })