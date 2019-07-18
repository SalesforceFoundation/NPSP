/*
    Copyright (c) 2019, Salesforce.org
    All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Salesforce.org nor the names of
      its contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
    FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
    COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
    INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
    BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
    CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
    LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
    ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
    POSSIBILITY OF SUCH DAMAGE.
*/
/**
 * @author Roger Mitchell
 * @date 4/12/2019
 * @group TDTM
 * @group-content ../../ApexDocContent/TDTM.htm
 * @description Abstract class that classes to be run from a trigger, according to the TDTM design,
 * need to extend. This differs from TDTM_Runnable in that it allows a developer to mutate the global
 * DmlWrapper collection to which TDTM_TriggerHandler adds records returned from other classes that
 * implement the TDTM_Runnable interface.
 */
global abstract class TDTM_RunnableMutable {

    /*******************************************************************************************************
     * @description Method to be implemented by the classes the extend this abstract class. This is the method
     * that will be called by the trigger handler.
     * @param newlist The records that were passed to the trigger as trigger.new.
     * @param oldlist The records that were passed to the trigger as trigger.old.
     * @param action The event (before insert, after insert,...) that caused the class to run.
     * @param objectResult The type of SObject the class runs for.
     * @param dmlWrapper the global TDTM_Runnable.DmlWrapper collection that is passed from TDTM_TriggerHandler.
     * Because this is passed by reference it can be modified by the run() method that implements this interface
     * and any values are returned back to the TriggerHandler class for dml.
     * @return void
    */
    global abstract void run(List<SObject> newlist, List<SObject> oldlist, TDTM_Runnable.Action triggerAction,
        Schema.DescribeSObjectResult objResult, TDTM_Runnable.DmlWrapper dmlWrapper);
}