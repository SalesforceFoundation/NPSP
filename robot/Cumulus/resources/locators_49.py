from locators_50 import *
import copy

npsp_lex_locators = copy.deepcopy(npsp_lex_locators)
npsp_lex_locators['related_list_items']='//div[@class = "forceRelatedListContainer"][.//a[contains(@class, "slds-card")]]//span[text() = "{}"]/ancestor::div[contains(@class, "slds-grid")]/following-sibling::div[.//div[contains(@class, "outputLookupContainer")]]//a[text()="{}"]'
