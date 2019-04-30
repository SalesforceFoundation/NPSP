"""Locators for Winter '19"""

from locators_46 import *

npsp_lex_locators = npsp_lex_locators.copy()
npsp_lex_locators.update({
    "frame_by_name": "//iframe[contains(@id, '${}')]",
    "header": "//h1[contains(@title, '{}')]",
    "header_text": "//h1/span",
})
