npsp_lex_locators={
    'mailing_address': "//*[contains(@placeholder,'{}')]",
    "record": {
        'button': "//div[@class='actionsContainer']/button[@title='{}']",
        'datepicker':"//div[contains(@class,'uiDatePickerGrid')]/table[@class='calGrid']//span[text()='{}']",
        'list':"//div[contains(@class,'forcePageBlockSectionRow')]/div[contains(@class,'forcePageBlockItem')]/div[contains(@class,'slds-p-vertical_xx-small')]/div[@class='slds-form-element__control']/div[.//span[text()='{}']][//div[contains(@class,'uiMenu uiInput')]//a[@class='select']]",
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

    }