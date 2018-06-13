npsp_lex_locators={
    'mailing_address': "//*[contains(@placeholder,'{}')]",
    'iframe': "//iframe[@title='{}']",
    "record": {
        'button': "//div[@class='actionsContainer']/button[@title='{}']",    
    },
    'tab': "//div[@class='uiTabBar']/ul[@class='tabs__nav']/li[contains(@class,'uiTabItem')]/a[@class='tabHeader']/span[contains(text(), '{}')]",
    'desktop_rendered': 'css: div.desktop.container.oneOne.oneAppLayoutHost[data-aura-rendered-by]',
    'loading_box': 'css: div.auraLoadingBox.oneLoadingBox',
    'spinner': 'css: div.slds-spinner',
    }