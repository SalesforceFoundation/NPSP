"""Locators for Spring '19"""

from locators_46 import *

npsp_lex_locators = npsp_lex_locators.copy()
npsp_lex_locators.update({
    'header':{
        "header_text": "//h1/div/span",
    },
    'checkbox':{
        'model-checkbox':'//div[contains(@class,"uiInputCheckbox")]/label/span[text()="{}"]/../following-sibling::input[@type="checkbox"]',
        'table_checkbox':'//tbody/tr[./td[2]/a[text()="{}"]]/td/input[@type="checkbox"]',
    },
    'confirm':{
        'check_status':'//div[contains(@class, "forcePageBlockItem")][.//span[text()="{}"]]//following-sibling::div[.//span[contains(@class, "test-id__field-value")]]/span',
    },
    'tabs':{   
        'tab': "//div[@class='uiTabBar']/ul[@class='tabs__nav']/li[contains(@class,'uiTabItem')]/a[@class='tabHeader']/span[contains(text(), '{}')]",
    },
    'detail_page': {
        'field-value':{
                'verify_field_value1':'//div[contains(@class, "forcePageBlockItem")]/div/div//span[text()="{}"]/../../div[2]/span/span[text() = "{}"]',
                
            },
    },
})