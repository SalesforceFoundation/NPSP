from faker import providers
from random import choice
from snowfakery import SnowfakeryPlugin
from collections import OrderedDict


class AccelerateFaker(SnowfakeryPlugin):
    class Functions:
        pass


key_cache = {}


def random_element(self, choices):
    if isinstance(choices, OrderedDict):
        if not hasattr(choices, "_cached_choice_list"):
            setattr(choices, "_cached_choice_list", tuple(choices.keys()))
        choices = choices._cached_choice_list

    return choice(choices)


providers.BaseProvider.random_element = random_element
