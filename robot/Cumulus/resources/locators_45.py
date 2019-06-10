"""Locators for Spring '19"""

from locators_46 import *

npsp_lex_locators = npsp_lex_locators.copy()
npsp_lex_locators.update({
    'checkbox':'//div[contains(@class,"uiInputCheckbox")]/label/span[text()="{}"]/../following-sibling::input[@type="checkbox"]',
    'confirm':{
        'check_status':'//div[contains(@class, "forcePageBlockItem")][.//span[text()="{}"]]//following-sibling::div[.//span[contains(@class, "test-id__field-value")]]/span',
    },

})