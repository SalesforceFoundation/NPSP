
npsp_lex_locators={
    'mailing_address': "//*[contains(@placeholder,'{}')]",
    'app_launcher':{
        'select-option':'//span/mark[text()="{}"]',
    },
    'object_dd':"//h1[contains(@class,'slds-page-header__title')]/a/div[contains(@class,'triggerLinkTextAndIconWrapper')][.//lightning-primitive-icon]",
    "record": {
        'button': "//div[@class='actionsContainer']/button[@title='{}']",
        'datepicker':"//div[contains(@class,'uiDatePickerGrid')]/table[@class='calGrid']//span[text()='{}']",
        'month_pick':"//div[@class='dateBar']//a[@title='{}']",
        'edit_button':'//*[@title="{}"]',
        #'list':"//div[contains(@class,'forcePageBlockSectionRow')]/div[contains(@class,'forcePageBlockItem')]/div[contains(@class,'slds-hint-parent')]/div[@class='slds-form-element__control']/div[.//span[text()='{}']][//div[contains(@class,'uiMenu')]//a[@class='select']]",
        
        'list':"//div[contains(@class,'forcePageBlockSectionRow')]/div[contains(@class,'forcePageBlockItem')]/div[contains(@class,'slds-p-vertical_xx-small')]/div[@class='slds-form-element__control']/div[.//span[text()='{}']][//div[contains(@class,'uiMenu')]//a[@class='select']]",
        'dropdown':"//div[@class='select-options']/ul[@class='scrollable']/li[@class='uiMenuItem uiRadioMenuItem']/a[contains(text(),'{}')]",
        'related': {
            'button': "//article[contains(@class, 'forceRelatedListCardDesktop')][.//img][.//span[@title='{}']]//a[@title='{}']",
            'check_occurrence':'//h2/a/span[@title="{}"]/following-sibling::span[text()=" ({})"]',
            'drop-down':'//div[contains(@class, "slds-card")]/header[.//span[@title="{}"]]/parent::*/div/div/div/a[contains(@class, "slds-button")]',
            'title':'//div[contains(@class, "slds-card")]/header[.//span[@title="{}"]]',
            'viewall':'//a[.//span[text()="View All"]/span[text()="{}"]]',
         },    
    },
    'object':{
        'radio_button':"//div[contains(@class,'changeRecordTypeRightColumn')]/div/label[@class='slds-radio']/div[.//span[text()='{}']]/preceding::div[1]/span[@class='slds-radio--faux']",
        
    },
    'frame':'//iframe[@title= "{}"]',
    'id':'//*[@id="{}"]',
    'button':'//input[@value="{}"]',
    'tab': "//div[@class='uiTabBar']/ul[@class='tabs__nav']/li[contains(@class,'uiTabItem')]/a[@class='tabHeader']/span[contains(text(), '{}')]",
    'desktop_rendered': 'css: div.desktop.container.oneOne.oneAppLayoutHost[data-aura-rendered-by]',
    'loading_box': 'css: div.auraLoadingBox.oneLoadingBox',
    'spinner': 'css: div.slds-spinner',
    'name':'//tbody/tr/th/span/a',
    'select_name':'//tbody//a[text()= "{}"]',
    'locate_dropdown':'//tbody/tr[{}]/td/span//div/a/lightning-icon',
    'locating_delete_dropdown':'//tbody//a[text()= "{}"]/../../following-sibling::td/span//div/a/lightning-icon',
    'related_name':'//tbody/tr/td/a[contains(@class,"forceOutputLookup")]',
    'rel_loc_dd':'//tbody/tr[{}]/td[4]//lightning-primitive-icon',
    'delete_icon':'//span[contains(text() ,"{}")]/following::span[. = "{}"]/following-sibling::a/child::span[@class = "deleteIcon"]',
    'aff_list':'//div[@role="tablist"]/following::div[@class = "container forceRelatedListSingleContainer"][7]/article/div[@class="slds-card__body"]/div/div/div/div/div/div/div/table/tbody/tr/td[1]',
    'aff_status':'//table[contains(@class,"forceRecordLayout")]/tbody/tr[.//th/div/a[contains(@class,"textUnderline")]][.//td/a[@title="{}"]]/td[3]',
    'aff_id':'//table[contains(@class,"forceRecordLayout")]/tbody/tr[.//th/div/a[contains(@class,"textUnderline")]][.//td/a[@title="{}"]]/th//a',
    'click_aff_id':'//table[contains(@class,"forceRecordLayout")]/tbody/tr/th/div/a[text()="{}"]',
    'check_status':'//div[contains(@class, "forcePageBlockItem")][.//span[text()="{}"]]//following-sibling::div[.//span[contains(@class, "test-id__field-value")]]/span[.//span[text()="{}"]]',
    'check_field':'//div[contains(@class, "forcePageBlockItem")][.//span[text()="{}"]]//following-sibling::div[.//span[contains(@class, "test-id__field-value")]]/span/div//a[text()="{}"]',
    'account_list':'//tbody/tr/th[.//span[contains(@class, "slds-grid")]]/descendant::a[text()="{}"]',
    'dd_options':'//*[@id="p3"]/option[text()="{}"]',
    'related_list_items':'//div[@class = "forceRelatedListContainer"][.//a[contains(@class, "slds-card")]]//span[text() = "{}"]/ancestor::div[contains(@class, "slds-card")]/following-sibling::div[contains(@class, "slds-card")][.//div[contains(@class, "outputLookupContainer")]]//a[text()="{}"]',
    'span_button':'//span[text()="{}"]',
    #'header_field_value':'//li[contains(@class, "slds-page-header__detail")][.//span[contains(@class, "slds-form-element__label")][@title="{}"]]//*[text()="{}"]',
    
    'header_field_value':'//li[contains(@class, "slds-page-header__detail")][.//p[contains(@class, "slds-text-heading--label")][@title="{}"]]//*[text()="{}"]',
    'header_datepicker':'//li[contains(@class, "slds-page-header__detail")][.//p[contains(@class, "slds-text-heading--label")][@title="{}"]]//*[@class="uiOutputDate"]',
    'affiliated_contacts':'//div[@class = "forceRelatedListContainer"][.//a[contains(@class, "slds-card")]]//span[text() = "{}"]/ancestor::div[contains(@class, "slds-card")]/following-sibling::div[contains(@class, "slds-card")]//tbody//td/span[text()="{}"]/../following-sibling::td/span[text()="{}"]',
    'select_one_record':"//tbody/tr[1]/th/span/a",
    'click_search':'//*[@id="j_id0:theForm:j_id49:{}:j_id51:util_inputfield:inputX"]',
    'field': "//div[contains(@class, 'uiInput')][.//label[contains(@class, 'uiLabel')][.//span[text()='{}']]]//input",
    'field_lookup_value': "//a[@role='option'][.//div[@title='{}']]",
    'header':'//h1[contains(@title,"{}")]',
    'detail_page': {
        'address':'//h3[contains(@class, "slds-section__title")][.//span[contains(text(),"Address")]]/../..//div[contains(@class, "test-id")]/span[text()= "{}"]/../following-sibling::div//a[@title = "{}"]/div[contains(@class, "slds")]',
        'field':'//h3[contains(@class, "slds-section__title")][.//span[text()="{}"]]/../..//div[contains(@class, "test-id")]/span[text()= "{}"]/../following-sibling::div//span[text()="{}"]',
        'verify_field_value':'//div[contains(@class, "forcePageBlockItem")]/div/div//span[text()="{}"]/../../div[2]/span/span[text() = "{}"]',
    },
    
    'manage_hh_page':{
        'address':'//div[contains(@class, "uiInput")][.//label[contains(@class, "uiLabel")]/span[text()="{}"]]/',
        'mhh_checkbox':'//*[@id="SortCanvas"]/li//a[text()="{}"]/ancestor::div[contains(@class, "slds-card__header")]/following-sibling::div[contains(@class,"slds-card__body")]//form//div//label/span[@id = "{}"]',
        'button':'//*[contains(@title, "{}")]',
        
    },
    'modal':{
        'checkbox':'//div[contains(@class,"uiInputCheckbox")]/label/span[text()="{}"]/../following-sibling::input[@type="checkbox"]',
    },
    'opportunity':{
        'contact_role':'//div[contains(@class,"listItemBody")][./h3//a[text()="{}"]]//parent::h3/following-sibling::ul/li/div[contains(@class,"forceListRecordItem")]/div[@title="Role:"]/following-sibling::div/span[text()="{}"]',
    },
    'object':{
        'contact_role':'//tbody//a[text()= "{}"]/../../following-sibling::td/span/span[text() = "{}"]',
        'record':'//tbody//a[text()= "{}"]',
        'button': "css: div.windowViewMode-normal ul.forceActionsContainer.oneActionsRibbon a[title='{}']",
    },
    'engagement_plan':{
        'id':'//*[@id="j_id0:theForm:{}"]',
        #'task_id':'//*[@id="{}"]',
        'input_box':'//*[contains(@id ,"j_id0:theForm:j_id102_{}") and @class= "slds-input"]',
        'dropdown':'//div[contains(@class,"slds-p-top_small")]/label[text()="{}"]/following-sibling::div/select',
        'checkbox':'//div[contains(@class,"slds-p-top_small")]/label[@class="slds-checkbox"][./span/following-sibling::{}[text()="{}"]/]',
        'check_related_list_item':'//div[@class = "forceRelatedListContainer"][.//a[contains(@class, "slds-card")]]//span[text() = "{}"]/ancestor::div[contains(@class, "slds-card")]/following-sibling::div[contains(@class, "slds-card")]//tbody//th//a[text()="{}"]',
        'check_eng_plan':'//h2/a/span[@title="{}"]//ancestor::div[@class = "slds-card__header slds-grid"]/following-sibling::div//tbody/tr/th/div/a',
        'dd':'//h2/a/span[@title="{}"]//ancestor::div[@class = "slds-card__header slds-grid"]/following-sibling::div//tbody/tr/th/div/a/ancestor::th/following-sibling::td//lightning-primitive-icon',
        'tasks':'//div[@class="slds-section__content"]/ul/li//a[text()="{}"]',
    },
    'levels':{
        'id':'//input[@id="j_id0:j_id4:{}"]',
        'select':'//select[@id="j_id0:j_id4:{}"]',
        'button':'//input[@id="j_id0:j_id4:j_id6:j_id7:{}"]',
        
    },
    'payments':{
        'date_loc':"//*[@id='pmtTable']/tbody/tr/td[3]/div//input",        
        'no_payments':'//tbody/tr/td[3]',
        'pay_amount':'//tbody/tr[{}]/td[3]/span/span[text()="{}"]',
        'check_occurrence':'//h2/a/span[@title="{}"]/following-sibling::span',
        'text':'//*[@id="j_id0:vfForm:j_id76:util_formfield:inputx:util_inputfield:inputX"]',
        },
    'npsp_settings':{
        'panal_link':'//div[@id="idPanelRecDonationsNav"]//a[text()="{}"]',
        'panal_sub_link':'//ul/li/a[text()="{}"]',
        'field_value':"//div[@class='slds-form-element'][./label[contains(text(),'{}')]]/div/span",
        'side_panal':"//ul/div[contains(@id,'RecDonations')]/button[1]",
        'list':"//div[contains(@class,'slds-form--horizontal')]/div[@class='slds-form-element'][./label[text()='{}']]/div/select",
        'list_val':'//div[@class="slds-form-element"][./label[text()="{}"]]/div/span[text()="{}"]',
        },
}


extra_locators={
    'related_list_items1':'//div[@class = "forceRelatedListContainer"][.//a[contains(@class, "slds-card")]]//span[text() = "Relationships"]/ancestor::div[contains(@class, "slds-card")]/following-sibling::div[contains(@class, "slds-card")]//tbody//td/span[text()="{}"]',
}
dnd={ ""
}
