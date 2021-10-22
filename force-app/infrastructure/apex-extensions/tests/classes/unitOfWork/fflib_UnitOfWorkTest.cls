/**
 * File Name: fflib_UnitOfWorkTest
 * Description: Unit Test class for fflib_UnitOfWork implementation
 *
 * @author architect ir. Wilhelmus G.J. Velzeboer
 *
 * Copyright (c), W.G.J. Velzeboer,
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification,
 *   are permitted provided that the following conditions are met:
 *
 * - Redistributions of source code must retain the above author notice,
 *      this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright notice,
 *      this list of conditions and the following disclaimer in the documentation
 *      and/or other materials provided with the distribution.
 * - Neither the name of the author nor the names of its contributors
 *      may be used to endorse or promote products derived from this software without
 *      specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
@IsTest(IsParallel=true)
private class fflib_UnitOfWorkTest
{
    public static List<String> orderOfExecution = new List<String>();

	@IsTest
	static void itShouldDoAllTheWork()
	{
        // GIVEN - Three different work items added to the fflib_DoWork
        Work workA = new Work();
        Work workB = new Work();
        Work workC = new Work();
        fflib_UnitOfWork myWork = new fflib_UnitOfWork().addWork(
                new List<fflib_IDoWork> {workA, workB, workC}
        );

        // WHEN - The work is being executed
        System.Test.startTest();
        myWork.doWork();
        System.Test.stopTest();

        // THEN - Then all three work items should be executed
        System.assert(workA.didWork, 'Work item A did not execute');
        System.assert(workB.didWork, 'Work item B did not execute');
        System.assert(workC.didWork, 'Work item C did not execute');
        System.assertEquals(3, [SELECT COUNT() FROM fflib_LogEntry__c]);
	}

    @IsTest
    static void itShouldOnlyDoTheRealTimeWorkAndQueueTheOther()
    {
        // GIVEN - Three different work items added to the fflib_DoWork
        Work workA = new Work();
        Work workB = new Work();
        Work workC = (Work) new Work().enableQueueable();
        fflib_UnitOfWork myWork = new fflib_UnitOfWork().addWork(
                new List<fflib_IDoWork> {workA, workB, workC}
        );
        final Integer numberOfQueueableJobs = Limits.getQueueableJobs();

        // WHEN - The work is being executed
        myWork.doWork();  // Execute without start-stop test due to Salesforce limitation

        // THEN - Then all three work items should be executed
        System.assert(workA.didWork, 'Work item A did not execute');
        System.assert(workB.didWork, 'Work item B did not execute');
        System.assert(workC.didWork, 'Work item C was executed in realtime while is should be queued');
        System.assertEquals(3, [SELECT COUNT() FROM fflib_LogEntry__c]);
    }

    @IsTest
    static void itShouldExecuteAllTheChainedQueuedWork()
    {
        // GIVEN - Three different work items added to the fflib_DoWork to be executed in a chained queueable
        Work workA = new Work();
        Work workB = new Work();
        Work workC = new Work();
        fflib_IUnitOfWork myWork =
                new fflib_UnitOfWork()
                        .addNext(workA)
                        .addNext(workB)
                        .addNext(workC);

        final Integer numberOfQueueableJobs = Limits.getQueueableJobs();

        // WHEN - The work is being executed
        myWork.doWork();    // Execute without start-stop test due to Salesforce limitation

        // THEN - Then all three work items should be executed
        System.assertEquals(3, [SELECT COUNT() FROM fflib_LogEntry__c]);
    }

    @IsTest
    static void itShouldExecuteAllItemsInTheCorrectOrder()
    {
        // GIVEN - Three different work items added to the fflib_DoWork
        Work workA = (Work) new WorkA().setPriority(1);
        Work workB = (Work) new WorkB().setPriority(2);
        Work workC = (Work) new WorkC().setPriority(3);
        fflib_UnitOfWork myWork = new fflib_UnitOfWork().addWork(
                new List<fflib_IDoWork> {workA, workB, workC}
        );

        // WHEN - The work is being executed
        System.Test.startTest();
        myWork.doWork();
        System.Test.stopTest();

        // THEN - Then all three work items should be executed
        System.assert(orderOfExecution.get(0).contains('WorkC'), 'Expected Work C with priority 3 to be executed first');
        System.assert(orderOfExecution.get(1).contains('WorkB'), 'Expected Work B with priority 2 to be executed second');
        System.assert(orderOfExecution.get(2).contains('WorkA'), 'Expected Work B with priority 1 to be executed last');
    }

    private virtual class Work extends fflib_DoWork
    {
        public Boolean didWork = false;

        public virtual void doWork()
        {
            this.didWork = true;
            insert new fflib_LogEntry__c(LogLevel__c = 'INFO', Message__c = 'Work got executed');
        }
    }

    private class WorkA extends Work
    {
        public override void doWork()
        {
            orderOfExecution.add('WorkA');
        }
    }

    private class WorkB extends Work
    {
        public override void doWork()
        {
            orderOfExecution.add('WorkB');
        }
    }

    private class WorkC extends Work
    {
        public override void doWork()
        {
            orderOfExecution.add('WorkC');
        }
    }

}