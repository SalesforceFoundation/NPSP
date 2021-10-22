/**
 * File Name: sflib_LogEventTrigger 
 * Description: Tigger to store Log events into a custom object
 * Copyright (c) 2019 Johnson & Johnson
 * @author: architect ir. Wilhelmus G.J. Velzeboer | wvelzebo@its.jnj.com
 */
trigger fflib_LogEventTrigger on fflib_LogEvent__e (after insert)
{
    new fflib_LogEventStoreListener(Trigger.new).run();
}