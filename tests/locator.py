npsp_lex_locators={
    'mailing_address': "//*[contains(@placeholder,'{}')]",
    "record": {
        'button': "//div[@class='actionsContainer']/button[@title='{}']",
        'datepicker':"//div[contains(@class,'uiDatePickerGrid')]/table[@class='calGrid']//span[text()='{}']",
        'edit_button':'//*[@title="{}"]',
        'list':"//div[contains(@class,'forcePageBlockSectionRow')]/div[contains(@class,'forcePageBlockItem')]/div[contains(@class,'slds-p-vertical_xx-small')]/div[@class='slds-form-element__control']/div[.//span[text()='{}']][//div[contains(@class,'uiMenu')]//a[@class='select']]",
        'dropdown':"//div[@class='select-options']/ul[@class='scrollable']/li[@class='uiMenuItem uiRadioMenuItem']/a[contains(text(),'{}')]",
        'related': {
            'button': "//article[contains(@class, 'forceRelatedListCardDesktop')][.//img][.//span[@title='{}']]//a[@title='{}']",
             },    
    },
    'tab': "//div[@class='uiTabBar']/ul[@class='tabs__nav']/li[contains(@class,'uiTabItem')]/a[@class='tabHeader']/span[contains(text(), '{}')]",
    'desktop_rendered': 'css: div.desktop.container.oneOne.oneAppLayoutHost[data-aura-rendered-by]',
    'loading_box': 'css: div.auraLoadingBox.oneLoadingBox',
    'spinner': 'css: div.slds-spinner',
    'name':'//tbody/tr/th/span/a',
    'locate_dropdown':'//tbody/tr[{}]/td/span//div/a/lightning-icon',
    'related_name':'//tbody/tr/td/a[contains(@class,"forceOutputLookup")]',
    'rel_loc_dd':'//tbody/tr[{}]/td[4]//lightning-primitive-icon',
    'delete_icon':'//span[contains(text() ,"{}")]/following::span[. = "{}"]/following-sibling::a/child::span[@class = "deleteIcon"]',
    'aff_list':'//div[@role="tablist"]/following::div[@class = "container forceRelatedListSingleContainer"][7]/article/div[@class="slds-card__body"]/div/div/div/div/div/div/div/table/tbody/tr/td[1]',
    'aff_status':'//table[contains(@class,"forceRecordLayout")]/tbody/tr[.//th/div/a[contains(@class,"textUnderline")]][.//td/a[@title="{}"]]/td[3]',
    'aff_id':'//table[contains(@class,"forceRecordLayout")]/tbody/tr[.//th/div/a[contains(@class,"textUnderline")]][.//td/a[@title="{}"]]/th//a',
    'click_aff_id':'//table[contains(@class,"forceRecordLayout")]/tbody/tr/th/div/a[text()="{}"]',
    'check_former':'//div[contains(@class, "forcePageBlockItem")][.//span[text()="{}"]]//following-sibling::div[.//span[contains(@class, "test-id__field-value")]]/span[.//span[text()="{}"]]',
    }

extra_locators={
    'related_list_items':'//div[@class = "forceRelatedListContainer"][.//a[contains(@class, "slds-card")]]//span[text() = "Relationships"]/ancestor::div[contains(@class, "slds-card")]/following-sibling::div[contains(@class, "slds-card")]//tbody//td/span[text()="{}"]',
    }