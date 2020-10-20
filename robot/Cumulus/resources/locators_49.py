from locators_50 import *
import copy

    },
    'custom_objects':{
        'actions-link':'//a[@title="{}" or @name="{}"]',
        },
    'payments':{
        'date_loc':"//*[@id='pmtTable']/tbody/tr/td[3]/div//input",
        'no_payments':'//tbody/tr[./th//a[contains(@title,"PMT")]]/td[3]',
        'pays':'//tbody/tr[./th//a[contains(@title,"PMT")]]/td[.//span[text()="{}"]]',
        'pay_amount':'//tbody/tr[{}]/td[3]/span/span[text()="{}"]',
        'check_occurrence':'//h2/a/span[@title="{}"]/following-sibling::span',
        'text':'//*[@id="j_id0:vfForm:j_id76:util_formfield:inputx:util_inputfield:inputX"]',
        'field-value':"//div[contains(@class,'slds-form-element')][./span[text()='{}']]/following-sibling::div",
        'allocations':"//article[contains(@class, 'forceRelatedListCardDesktop')][.//img][.//span[@title='{}']]//tbody/tr[./td/a[text()='{}']]/th",
        'loc1':"//tbody/tr/td[2]/span/span",
        'loc2':"//tbody/tr/td[3]/span/span",
        },
    'gaus':{
        'input_field':'//div[@class="slds-form-element"][./label[text()="{}"]]/div/input',
        },
    'npsp_settings':{
        'main_menu':'//div[@class="slds-tree__branch slds-tree__item"][.//a[text()="{}"]]',
        'donations_link':'//div/a[contains(text(),"{}") and not(contains(text(),"Recurring Donations"))]',
        'panel_sub_link':'//ul/li[contains(@class,"slds-is-selected")]/a[text()="{}"]',
        'field_value':"//div[@class='slds-form-element'][./label[contains(text(),'{}')]]/div/span",
        'side_panel':'//div[@id="{}"]//child::button[contains(@class,"chevronright")]',
        'list':"//div[@class='slds-form-element']/label[text()='{}']/following-sibling::div/select",
        'multi_list':'//div[contains(@class,"slds-form_horizontal")]/div[@class="slds-form-element"][./label[text()="{}"]]/div//select',
        'list_val':'//div[@class="slds-form-element"]/label[text()="{}"]/following-sibling::div/span[text()="{}"]',
        'status':'//div[contains(@class,"slds-tile__title")][.//span[text()="{}"]]/div[contains(@class,"slds-col")]//span[text()="{}"]',
        'button':'//form[.//h1[contains(text(),"{}")]]//input[contains(@value,"{}")]',
        'completed':'//span[contains(@class, \'slds-theme_success\')]',
        'batch-button':'//div[@id="{}"]//child::input[@value="{}"]',
        'checkbox':'//label[./span[text()="{}"]]/descendant::span[@class="slds-checkbox_faux"]'
        },
    'data_imports':{
        'status':'//div[contains(@class,"slds-tile__title")][./p[text()="BDI_DataImport_BATCH"]]/div[contains(@class,"slds-col")]/span[text()="{}"]',
        'checkbox':'//tr[./th//a[@title="{}"]]/td//span[@class="slds-checkbox--faux"]',
        'actions_dd':'//button[@aria-expanded="true"][.//span[contains(text(),"more actions")]]',
        'check_status':'//div[contains(@class, "field-label-container")][.//span[text()="{}"]]//following-sibling::div[.//span[contains(@class, "test-id__field-value")]]/span//lightning-formatted-text',
        },
    'bge':{
        'checkbox':'//label/span[text()="{}"]//parent::label/span[@class="slds-checkbox_faux"]',
        'field-duellist':'//label[text()="{}"]/following-sibling::lightning-dual-listbox//div[contains(@class,"slds-dueling-list__column")][./span[text()="{}"]]//div[contains(@class,"slds-dueling-list__options")]/ul/li//span[text()="{}"]',
        'duellist':'//h3[./span[text()="{}"]]/following-sibling::div//div[contains(@class,"slds-dueling-list__column")][./span[text()="{}"]]//div[contains(@class,"slds-dueling-list__options")]/ul/li//span[text()="{}"]',
        'duellist2':'//div/div[text()="{}"]/following-sibling::div//div[contains(@class,"slds-dueling-list__column")][./span[text()="{}"]]//div[contains(@class,"slds-dueling-list__options")]/ul/li//span[text()="{}"]',
        'field-select-button':'//label[text()="{}"]/following-sibling::lightning-dual-listbox//div[contains(@class,"slds-dueling-list__column")]//button[@title="{}"]',
        'select-button':'//h3[./span[text()="{}"]]/following-sibling::div//div[contains(@class,"slds-dueling-list__column")]//button[@title="{}"]',
        'select-button2':'//div/div[text()="{}"]/following-sibling::div//div[contains(@class,"slds-dueling-list__column")]//button[@title="{}"]',
        'title':'//p[text()="{}"]/following-sibling::h1',
        'field-input':'//label[text()="{}"]/following-sibling::div/input',
        'field-text':'//label[text()="{}"]/following-sibling::div/textarea',
        'button':'//div[contains(@class,"active")]/descendant::button[text()="{}"]',
        'month':"//div[@class='slds-align-middle']//button[@title='{}']",
        'date':"//div[contains(@class,'slds-datepicker')]//table[@class='slds-datepicker__month']//span[text()='{}']",
        'card-header':'//article[./div[@class="slds-card__body"]//lightning-formatted-text[text()="{}"]]/header',
        'edit_button':'//td[@data-label="{}"]//button',
        'edit_field':'//lightning-primitive-datatable-iedit-panel//input',
        'count':'//div[contains(@class,"BGE_DataImportBatchEntry")]//tbody/tr',
        'value':'//td[@data-label="{}"]//a',
        'name':'//div[contains(@class,"BGE_DataImportBatchEntry")]//tbody/tr/th//a',
        'locate_dropdown':'//div[contains(@class,"BGE_DataImportBatchEntry")]//tbody/tr[{}]/td[6]//div//button[./span[text()="Show actions"]]/lightning-primitive-icon',
        'gift-amount':'//div[./label[text()="{}"]]',
        'modal-link':'//tbody/tr/td/a[text()="{}"]',
        'datepicker_open':"//div[contains(@class,'slds-is-open')][./label[contains(text(),'{}')]]",

    },
    'bge-lists':{
        'list1':"//div[./label[text()='{}']]/div//select",
        'list2':"//div[contains(@class,'slds-grid')]/div[contains(@class,'slds-text-align_left')]/span[text()='{}']/../following-sibling::div//select",
        'list3':"//div[./label/span[text()='{}']]/div//select",

        },
    'bge-duellist-btn':{
        'select-button':'//h3[./span[text()="{}"]]/following-sibling::div//div[contains(@class,"slds-dueling-list__column")]//button[@title="{}"]',
        'select-button2':'//div/div[text()="{}"]/following-sibling::div//div[contains(@class,"slds-dueling-list__column")]//button[@title="{}"]',
        'field-select-button':'//label[text()="{}"]/following-sibling::lightning-dual-listbox//div[contains(@class,"slds-dueling-list__column")]//button[@title="{}"]',
        },

    'object_manager':{
        'button':'//input[@title="{}"]',
        'input':'//input[@id="{}"]',
        'select_related':'//select[@id = "{}"]',
        'select_related_option':'//select[@id = "DomainEnumOrId"]/option[@value="{}"]',
        'search_result': '//tbody/tr/td/a/span[contains(text(),"{}")]',
        'formula_txtarea': '//textarea[@id = "{}"]',
        'object_result': '//th/a[text()="{}"]',
        },
    'custom_settings':{
        'subtree':'//a/mark[text()="{}"]',
        'link':"//table[@class='list']/tbody/tr[./th/a[text()='{}']]/td/a[text()='{}']",
        'cbx_status':'//table[@class="detailList"]/tbody/tr/th[./span[text()="{}"]]/following-sibling::td//img[@title="{}"]',
        },
    'adv_mappings':{
        'dropdown':"//tr[./th//*[text()='{}']]/td[.//span[text()='Show actions']]//button",
        'modal_open':'//div[contains(@class,"slds-backdrop_open")]',
        'field_mapping':'//input[@name="{}"]',
        'combobox':'//div[contains(@class,"slds-is-open") and @role="combobox"]',
        'footer-btn':"//footer[@class='slds-modal__footer']/button[text()='{}']",
        'field-label':'//lightning-primitive-cell-factory//*[text()="{}"]',
        'field_dd_option':'//div[contains(@class,"slds-input-has-icon")][./input[@name="{}"]]/following-sibling::div//span[@title="{}"]'
        },
    'modal-form':{
        'label':'//div[./*/*[text()="{}"]]',
        },
	# Customizable rollups related element locators
    'crlps':{
        'select_locator': "//select[@name ='{}']",
        'success_toast': "//div[@class='{}']",
        'active_setting_record': "//td[@data-label='Active']/following::tr/th//span/div//lightning-button/button[text()='{}']",
        'rollup_progress_notification': "//div/h2[contains(text(),'{}')]",
        'rollup_options':"//tr[./th//button[text()='{}']]/td//button",
        'modal-button': '//footer/button[text()="Save"]',
       },
    'gift_entry':{
        'id':'//*[contains(@data-qa-locator,"{}")]',
        'button':'//*[contains(@data-qa-locator,"{}")]/button',
        'field_input':'//*[contains(@data-qa-locator,"{}")]//child::{}',
        'field_span':'//*[contains(@data-qa-locator,"{}")]//child::span[text()="{}"]',
        'actions_dropdown':'//tbody/tr[./th//a[text()="{}"]]/td//button',
        'form_object_dropdown':'//*[@data-qa-locator="{}"]//button',
        # 'object_field_checkbox':'//*[@data-qa-locator="{}"]//span[@class="slds-checkbox_faux"]',
        'object_field_checkbox':'//*[@data-object-mapping-label="{}" and contains(@data-qa-locator,"{}")]//child::input',
        'field_alert':"//*[contains(@data-qa-locator,'{}')]/div[@role='alert' and text()='{}']",
        'count':'//lightning-layout[.//span[text()="{}"]]//child::lightning-layout-item//strong[text()="{}"]',
        'duellist':'//div[contains(@class,"slds-dueling-list__column")][./span[text()="{}"]]//div[contains(@class,"slds-dueling-list__options")]/ul/li//span[text()="{}"]',
        'table':'//*[@data-qa-locator="datatable {}"]//tbody//lightning-primitive-cell-factory[@data-label="{}"][.//*[text()="{}"]]',
        'lookup-option':'//li/lightning-base-combobox-item[.//*[@title="{}"]]',
        'datatable_options_icon':"//th/lightning-primitive-cell-factory/span/div//a[contains(text(),'{}')]/following::lightning-primitive-cell-actions//button[@aria-expanded='false']/lightning-primitive-icon",
        'datatable_field_by_name':"//lightning-primitive-cell-factory/span/div//a[contains(text(),'{}')]/following::lightning-primitive-cell-factory[@data-label='{}'][.//*[text()='{}']]",
        'datatable-menu-item':"//lightning-menu-item/a/span[text()='{}']"
    },
    # Enhanced Recurring Donation (erd) related element locators
    'erd':{
        'active_schedules_card': "//div[contains(@class, 'slds-media__body')]/h3[contains(@title,'{}')]",
        'modal_dropdown_selector': "//label[text()='{}']/following-sibling::div//div[contains(@class,'slds-dropdown-trigger') and @role='combobox']",
        'modal_input_field': "//label[text()='{}']/following-sibling::div/input",
        'modal_selection_value': "//lightning-base-combobox-item[@data-value='{}']",
        'installment_row' : "//table[contains(@class, 'slds-table_edit')]/tbody/tr",
        'text_message':'//span[contains(@class,"slds-text-color_error")]',
        'rd2_installed': "//c-progress-ring/following-sibling::lightning-formatted-text[text() = 'Enable Enhanced Recurring Donations']",
        'installment_date' : "//table[contains(@class, 'slds-table_edit')]/tbody/tr[{}]/th//span/div/lightning-formatted-date-time",
        'formatted_number':"//lightning-formatted-text[text() = '{}']/following::lightning-layout-item[contains(@class,'slds-dl_horizontal__detail')]/slot/lightning-formatted-number",
        'formatted_date':"//lightning-formatted-text[contains(text(),'{}')]/following::lightning-layout-item[contains(@class,'slds-dl_horizontal__detail')]/slot/lightning-formatted-date-time",
        'formatted_text':"//lightning-formatted-text[contains(text(),'{}')]/following::lightning-layout-item[contains(@class,'slds-dl_horizontal__detail')]/slot/lightning-formatted-text",
        'pause_date_checkbox':"//h2[contains(text(),'Pause')]/following::th//span/div/lightning-formatted-date-time[text()='{}']/ancestor::tr/td/descendant::label/span[contains(@class,'checkbox')]",
        'date_with_paused_txt':"//td//lightning-base-formatted-text[text()='Paused']/preceding::th//lightning-formatted-date-time[text()='{}']",
        'warning_message':'//lightning-formatted-rich-text/span[contains(text() ,"{}")]'
        },

}

extra_locators={
    'related_list_items1':'//div[@class = "forceRelatedListContainer"][.//a[contains(@class, "slds-card")]]//span[text() = "Relationships"]/ancestor::div[contains(@class, "slds-card")]/following-sibling::div[contains(@class, "slds-card")]//tbody//td/span[text()="{}"]',
}