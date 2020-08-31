from locators_50 import *
import copy

npsp_lex_locators = copy.deepcopy(npsp_lex_locators)
npsp_lex_locators['related_list_items']='//div[@class = "forceRelatedListContainer"][.//a[contains(@class, "slds-card")]]//span[text() = "{}"]/ancestor::div[contains(@class, "slds-grid")]/following-sibling::div[.//div[contains(@class, "outputLookupContainer")]]//a[text()="{}"]'
npsp_lex_locators["lightning-button"]='//a[@title="{}"]'
npsp_lex_locators["record"]["rdlist"]="//div[contains(@class,'forcePageBlockSectionRow')]/div[contains(@class,'forcePageBlockItem')]/div[contains(@class,'slds-hint-parent')]/div[@class='slds-form-element__control']/div[.//span[text()='{}']][//div[contains(@class,'uiMenu')]//a[@class='select']]",
