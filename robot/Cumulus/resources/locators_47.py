"""Locators for Winter '20"""

from locators_48 import *

npsp_lex_locators = npsp_lex_locators.copy()
npsp_lex_locators.update({
    'checkbox':{
        'model-checkbox':'//div[contains(@class,"uiInputCheckbox")]/label/span[text()="{}"]/../following-sibling::input[@type="checkbox"]',
        'details-checkbox':'//label[@class="slds-checkbox__label"][./span[text()="{}"]]/span[contains(@class,"slds-checkbox_faux")]',
        'table_checkbox':'//tbody/tr[./td[2]/a[text()="{}"]]/td/input[@type="checkbox"]',
        'id':'//input[@type="checkbox" and contains(@id,"{}")]',
    },
#     'confirm': {
#         'check_value':'//div[contains(@class, "forcePageBlockItem") or contains(@class, "slds-form-element_stacked")][.//span[text()="{}"]]//following-sibling::div[.//span[contains(@class, "test-id__field-value")]]/span',
#         'check_status':'//div[contains(@class, "field-label-container")][.//span[text()="{}"]]//following-sibling::div[.//span[contains(@class, "test-id__field-value")]]/span//lightning-formatted-text',
#         'check_numbers':'//div[contains(@class, "field-label-container")][.//span[text()="{}"]]//following-sibling::div[.//span[contains(@class, "test-id__field-value")]]/span//lightning-formatted-number',
#     },
    'data_imports':{
        'status':'//div[contains(@class,"slds-tile__title")][./p[text()="BDI_DataImport_BATCH"]]/div[contains(@class,"slds-col")]/span[text()="{}"]',
        'checkbox':'//tr[./th//a[@title="{}"]]/td//span[@class="slds-checkbox--faux"]',
        'actions_dd':'//a[contains(@title,"more actions")and @aria-expanded="true"]',
        'check_status':'//div[contains(@class, "field-label-container")][.//span[text()="{}"]]//following-sibling::div[.//span[contains(@class, "test-id__field-value")]]/span//lightning-formatted-text',
        },
    'delete_icon_record':'//span[contains(text() ,"{}")]/following::span[. = "{}"]/following-sibling::a/child::span[@class = "deleteIcon"]',
    'link-contains':'//a[contains(@title,"{}")]',
    'related_list_items':'//div[@class = "forceRelatedListContainer"][.//a[contains(@class, "slds-card")]]//span[text() = "{}"]/ancestor::div[contains(@class, "slds-card")]/following-sibling::div[contains(@class, "slds-card")][.//div[contains(@class, "outputLookupContainer")]]//a[text()="{}"]',
    "record": {
        'button':"//div[@class='actionsContainer']/button[@title='{}']",
        'footer':"//div[@class='footer active' or contains(@class,'footer-visible')]",
        'datepicker':"//div[contains(@class,'uiDatePickerGrid')]/table[@class='calGrid']//*[text()='{}']",
        'month_pick':"//div[@class='dateBar']//a[@title='{}']",
        'activity-button':'//button[contains(@class,"{}")]',
        'edit_button':'//*[@title="{}"]',
        'edit_form': 'css: div.forcePageBlockItemEdit',
        'flexipage_edit_form': 'css: force-record-layout-item.slds-is-editing',
        'list':"//div[contains(@class,'forcePageBlockSectionRow')]/div[contains(@class,'forcePageBlockItem')]/div[contains(@class,'slds-hint-parent')]/div[@class='slds-form-element__control']/div[.//span[text()='{}']][//div[contains(@class,'uiMenu')]//a[@class='select']]",
        'flexipage-list':'//lightning-combobox[./label[text()="{}"]]/div//input[contains(@class,"combobox__input")]',
        'dropdown':"//div[@class='select-options']/ul[@class='scrollable']/li[@class='uiMenuItem uiRadioMenuItem']/a[contains(text(),'{}')]",
        'related': {
            'button': "//article[contains(@class, 'forceRelatedListCardDesktop')][.//img][.//span[@title='{}']]//a[@title='{}']",
            'check_occurrence':'//h2/a/span[@title="{}"]/following-sibling::span',
            'drop-down':'//div[contains(@class, "slds-card")]/header[.//span[@title="{}"]]/parent::*/div/div/div/a[contains(@class, "slds-button")]',
            'title':'//div[contains(@class, "slds-grid")]/header//a[./span[text()="{}"]]',
            'viewall':'//a[.//span[text()="View All"]/span[text()="{}"]]',
            'item':"//article[contains(@class, 'forceRelatedListCardDesktop')][.//img][.//span[@title='{}']]//h3//a",
            'field_value': '//a[text()="{}"]/ancestor::li//div[contains(@class, "slds-item--detail")]//*[text()="{}"]',
            'link':"//article[contains(@class, 'forceRelatedListCardDesktop')][.//img][.//span[@title='{}']]//table[contains(@class,'forceRecordLayout')]/tbody/tr[.//th/div/a[contains(@class,'textUnderline')]][.//td//*[text()='{}']]/th//a",
            'dd-link':'//div[contains(@class,"actionMenu")]//a[@title="{}"]',
            'allocations':"//article[contains(@class, 'forceRelatedListCardDesktop')][.//img][.//span[@title='{}']]//tbody/tr[./td//a[text()='{}']]/td/span[text()='{}']",
            "popup_trigger": "//article[contains(@class, 'forceRelatedListCardDesktop')][.//img][.//span[@title='{}']]//tr[.//a[text()='{}']]//div[contains(@class, 'forceVirtualAction')]//a",
         },
    },

    })

