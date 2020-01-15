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
    'delete_icon':'//span[contains(text() ,"{}")]/following::span[. = "{}"]/following-sibling::a/child::span[@class = "deleteIcon"]',
    'link-contains':'//a[contains(@title,"{}")]',
    })