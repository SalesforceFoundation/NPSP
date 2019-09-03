import collections
from abc import ABC, abstractmethod
from importlib import import_module

from factory import enums, Factory, base

from .data_generation_base import BatchDataTask


#  Factoryboy uses "__" and Salesforce uses "__". Luckily Factoryboy makes
#  theirs easy to override!
enums.SPLITTER = "____"


# More flexible than FactoryBoy's sequences because you can create and
# destroy them where-ever you want.
class Adder:
    def __init__(self, x=0):
        self.x = x

    def __call__(self, value):
        self.x += value
        return int(self.x)

    def reset(self, x):
        self.x = x


# Thin collector for the factories and a place to try to achieve better
# scalability than the create_batch function from FactoryBoy.
class Factories:
    unflushed_record_counter = 0

    def __init__(self, session, orm_classes, collection):
        """Add a session to factories and then store them."""

        self.factory_classes = {
            key: self.add_session(value, session)
            for key, value in collection.items()
        }

    @staticmethod
    def add_session(fact, session):
        "Attach the session to the factory"
        fact._meta.sqlalchemy_session = session
        fact._meta.sqlalchemy_session_persistence = "commit"
        return fact

    def create_batch(self, classname, batchsize, **kwargs):
        cls = self.factory_classes.get(classname, None)
        assert cls, f"Cannot find a factory class named {classname}. Did you misspell it?"
        for _ in range(batchsize):
            print("Creating", cls, cls._meta.sqlalchemy_session, _)
            cls.create(**kwargs)

    def __getitem__(self, name):
        return self.factory_classes[name]


class BaseDataFactory(BatchDataTask, ABC):
    """Abstract base class for any FactoryBoy based generator"""
    def generate_data(self, session, engine, base, num_records):
        raw_factories = self.make_factories(base.classes)
        factories = Factories(session, base.classes, raw_factories)
        self.make_records(num_records, factories)
        session.flush()
        session.close()

    @abstractmethod
    def make_factories(self, classes):
        pass

    @abstractmethod
    def make_records(self, num_records, factories):
        pass


class ModuleDataFactory(BaseDataFactory):
    datafactory_classes_module = None

    def make_factories(self, classes):
        if not self.datafactory_classes_module:
            self.datafactory_classes_module = self.__module__
        module = import_module(self.datafactory_classes_module)
        module_contents = vars(module)

        def replace_model(f):
            f._meta.model = classes[f._meta.model]
            return f
        factories = {name: replace_model(f)
                     for name, f in module_contents.items()
                     if isinstance(f, base.FactoryMetaClass)}
        assert factories['GAU'], factories

        return factories


##  Note: this is used as a mutable global variable to emulate how models
##        in e.g. Django work. This should only be a problem in a
##        multithreaded environment and I believe that CCI is far from being
##        multi-thread compatible.
class _Models:
    def __getattr__(self, name):
        return name


Models = _Models()


def _reset_Models():
    global Models

    class Models:
        pass
