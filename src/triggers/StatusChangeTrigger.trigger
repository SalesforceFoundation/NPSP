trigger StatusChangeTrigger on StatusChange__e (after insert) {

    StatusChangeEventHandler handler = new StatusChangeEventHandler();
    handler.handle(Trigger.new);

}