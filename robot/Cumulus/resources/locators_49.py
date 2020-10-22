from locators_50 import *
import copy

npsp_lex_locators = copy.deepcopy(npsp_lex_locators)
npsp_lex_locators["check_related_list_item"]='//article[.//span[text() = "{}"]]/descendant::tbody//th//a[text()="{}"]',
npsp_lex_locators['related_list_items']='//div[@class = "forceRelatedListContainer"][.//a[contains(@class, "slds-card")]]//span[text() = "{}"]/ancestor::div[contains(@class, "slds-grid")]/following-sibling::div[.//div[contains(@class, "outputLookupContainer")]]//a[text()="{}"]'
npsp_lex_locators["lightning-button"]='//a[@title="{}"]'
npsp_lex_locators["record"]["rdlist"]="//div[contains(@class,'forcePageBlockSectionRow')]/div[contains(@class,'forcePageBlockItem')]/div[contains(@class,'slds-hint-parent')]/div[@class='slds-form-element__control']/div[.//span[text()='{}']][//div[contains(@class,'uiMenu')]//a[@class='select']]"
npsp_lex_locators["record"]["related"]["title"]='//div[contains(@class, "slds-grid")]/header//a[./span[text()="{}"]]'
npsp_lex_locators["record"]["related"]["link"]="//article[contains(@class, 'forceRelatedListCardDesktop')][.//img][.//span[@title='{}']]//table[contains(@class,'forceRecordLayout')]/tbody/tr[.//th/div/a[contains(@class,'textUnderline')]][.//td//*[text()='{}']]/th//a"
npsp_lex_locators["record"]["related"]["allocations"]="//article[contains(@class, 'forceRelatedListCardDesktop')][.//img][.//span[@title='{}']]//tbody/tr[./td//a[text()='{}']]/td/span[text()='{}']"
npsp_lex_locators["record"]["rdlist"]="//div[contains(@class,'forcePageBlockSectionRow')]/div[contains(@class,'forcePageBlockItem')]/div[contains(@class,'slds-hint-parent')]/div[@class='slds-form-element__control']/div[.//span[text()='{}']][//div[contains(@class,'uiMenu')]//a[@class='select']]"
npsp_lex_locators["payments"]["allocations"]="//article[contains(@class, 'forceRelatedListCardDesktop')][.//img][.//span[@title='{}']]//tbody/tr[./td/a[text()='{}']]/th"
npsp_lex_locators["record"]["related"]["popup_trigger"]= "//article[contains(@class, 'forceRelatedListCardDesktop')][.//img][.//span[@title='{}']]//tr[.//a[text()='{}']]//div[contains(@class, 'forceVirtualAction')]//a"
npsp_lex_locators["record"]["related"]["button"]= "//article[contains(@class, 'forceRelatedListCardDesktop')][.//img][.//span[@title='{}']]//a[@title='{}']"
npsp_lex_locators["aff_status"]='//table[contains(@class,"forceRecordLayout")]/tbody/tr[.//th/div/a[contains(@class,"textUnderline")]][.//td/a[@title="{}"]]/td[3]'
npsp_lex_locators["aff_id"]='//table[contains(@class,"forceRecordLayout")]/tbody/tr[.//th/div/a[contains(@class,"textUnderline")]][.//td/a[@title="{}"]]/th//a'
npsp_lex_locators["record"]["related"]["viewall"]='//a[.//span[text()="View All"]/span[text()="{}"]]',
npsp_lex_locators['npsp_settings']['main_menu_link']='//div/a[contains(text(),"{}")]'
npsp_lex_locators['manage_hh_page']['more_actions_btn'] = "//lightning-button-menu/button",
