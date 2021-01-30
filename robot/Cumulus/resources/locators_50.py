from locators_51 import *
import copy

npsp_lex_locators = copy.deepcopy(npsp_lex_locators)
npsp_lex_locators['delete_icon']='//span[contains(text() ,"{}")]/following::span[. = "{}"]/following-sibling::a/child::span[@class = "deleteIcon"]'
npsp_lex_locators['object']['field']= "//div[contains(@class, 'uiInput')][.//label[contains(@class, 'uiLabel')][.//span[text()='{}']]]//*[self::input or self::textarea]"
npsp_lex_locators["record"]["related"]["dd-link"]='//div[contains(@class,"actionMenu")]//a[@title="{}"]'
npsp_lex_locators["record"]["related"]["button"]="//article[contains(@class, 'slds-card slds-card_boundary')][.//img][.//span[@title='{}']]//a[@title='{}']"
npsp_lex_locators['schedule_payments']="//a[@title ='{}']"
npsp_lex_locators['payments']['no_payments']="//tbody/tr[./th//a[contains(@title,'PMT')]]/td[3]"
npsp_lex_locators['related_list_items']='//article[contains(@class,"slds-card_boundary")][.//a[contains(@class, "slds-card")]]//span[text() = "{}"]/ancestor::div[contains(@class, "slds-grid")]/following-sibling::div[.//div[contains(@class, "outputLookupContainer")]]//a[text()="{}"]'

