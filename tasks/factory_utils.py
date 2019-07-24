from factory import enums
from collections import namedtuple
import gc

enums.SPLITTER = "____"


class Adder:
    def __init__(self, x=0):
        self.x = x

    def __call__(self, value):
        self.x += value
        return int(self.x)

    def reset(self, x):
        self.x = x


def SessionBase(session):
    class BaseMeta:
        sqlalchemy_session = session
        sqlalchemy_session_persistence = "commit"

    return BaseMeta


class Factories:
    unflushed_record_counter = 0

    def __init__(self, session, namespace):
        self.session = session
        self.factory_classes = {
            key: value for key, value in namespace.items() if hasattr(value, "generate_batch")
        }

    def create_batch(self, classname, batchsize, **kwargs):
        cls = self.factory_classes.get(classname, None)
        assert cls, f"Cannot find a factory class named {classname}. Did you misspell it?"
        for _ in range(batchsize):
            cls.create(**kwargs)
