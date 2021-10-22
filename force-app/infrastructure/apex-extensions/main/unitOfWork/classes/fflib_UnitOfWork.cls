/**
 * File Name: fflib_UnitOfWork
 * Description: Unit Of Work executing a batch of work items at a single instance
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
public virtual class fflib_UnitOfWork
		extends fflib_DoWork
		implements fflib_IUnitOfWork, fflib_IDoWork, Queueable
{
	protected List<fflib_IDoWork> work;
	protected List<fflib_IUnitOfWork> doNext;

	public fflib_UnitOfWork()
	{
		this(new List<fflib_IDoWork>());
	}

	public fflib_UnitOfWork(fflib_IDoWork workItem)
	{
		this(new List<fflib_IDoWork>{ workItem });
	}

	public fflib_UnitOfWork(List<fflib_IDoWork> workItems)
	{
		this(workItems, new List<fflib_IUnitOfWork>());
	}

	public fflib_UnitOfWork(List<fflib_IDoWork> workItems, fflib_UnitOfWork nextWork)
	{
		this(workItems, new List<fflib_IUnitOfWork>{ nextWork });
	}

	public fflib_UnitOfWork(List<fflib_IDoWork> workItems, List<fflib_IUnitOfWork> nextWork)
	{
		this.work = workItems;
		this.doNext = nextWork;
	}

	/**
	 * Adds a single work item is executed in a dedicated Queued context after the UnitOfWork is finished
	 *
	 * @param nextWork work item to be executed after the UnitOfWork is finished
	 *
	 * @return Instance of itself to allow for method chaining
	 */
	public virtual fflib_IUnitOfWork addNext(fflib_IDoWork nextWork)
	{
		return addNext((fflib_IUnitOfWork) new fflib_UnitOfWork(nextWork));
	}

	/**
	 * Adds a UnitOfWork to be executed in a Queued context after the UnitOfWork is finished
	 *
	 * @param nextWork UnitOfWork to be executed after the UnitOfWork is finished
	 *
	 * @return Instance of itself to allow for method chaining
	 */
	public virtual fflib_IUnitOfWork addNext(fflib_IUnitOfWork nextWork)
	{
		return addNext(new List<fflib_IUnitOfWork>{ nextWork });
	}

	/**
	 * Adds an ordered list of UnitOfWork to be executed each in a separate Queued context after the UnitOfWork is finished
	 *
	 * @param nextWork UnitOfWork to be executed after the UnitOfWork is finished
	 *
	 * @return Instance of itself to allow for method chaining
	 */
	public virtual fflib_IUnitOfWork addNext(List<fflib_IUnitOfWork> nextWork)
	{
		doNext.addAll(nextWork);
		return this;
	}

	/**
	 * Add a single work item to the queue
	 *
	 * @param work work item to be added
	 *
	 * @return Instance of itself to allow for method chaining
	 */
	public virtual fflib_UnitOfWork addWork(fflib_IDoWork work)
	{
		this.work.add(work);
		return this;
	}

	/**
	 * Adds a list of work items to the queue
	 *
	 * @param work work items to be added
	 *
	 * @return Instance of itself to allow for method chaining
	 */
	public virtual fflib_UnitOfWork addWork(List<fflib_IDoWork> work)
	{
		this.work.addAll(work);
		return this;
	}

	/**
	 * Do the work contained in the UnitOfWork
	 */
	public virtual void doWork()
	{
		this.work.sort();
		doRealTimeWork();
		doQueuedWork();
		doNextWork();
	}

	/**
	 * Execute the work when being invoked from a queued context
	 *
	 * @param ctx QueueableContext
	 */
	public virtual void execute(QueueableContext ctx)
	{
		doWork();
	}

	/**
	 * Do start with the execution of the next work item to be executed in a Queued context
	 */
	protected virtual void doNextWork()
	{
		if (this.doNext.isEmpty()) return;

		fflib_IUnitOfWork nextWork = this.doNext.remove(0);
		nextWork.addNext(this.doNext);
		enqueueJob(nextWork);
	}

	/**
	 * Put the given UnitOfWork in the Queue for execution
	 *
	 * @param nextWork The UnitOfWork to be executed in a Queued context
	 */
	protected virtual void enqueueJob(fflib_IUnitOfWork nextWork)
	{
		if (Test.isRunningTest())
		{
			nextWork.doWork();
		}
		else
		{
			System.enqueueJob(nextWork);
		}
	}

	/**
	 * Put the given work item in the Queue for execution
	 *
	 * @param work The work item to be executed in a Queued context
	 */
	protected virtual void enqueueJob(fflib_IDoWork work)
	{
		if (Test.isRunningTest())
		{
			work.doWork();
		}
		else
		{
			System.enqueueJob(work);
		}
	}

	/**
	 * Do start executing the work items marked for execution in a Queued context.
	 * Either in a dedicated Queued context or batched together in another UnitOfWork
	 */
	protected virtual void doQueuedWork()
	{
		if (this.work.isEmpty()) return;

		List<fflib_IDoWork> workToQueue = new List<fflib_IDoWork>();
		for (fflib_IDoWork workItem : work)
		{
			if (workItem.isNotQueueable()) continue;

			if (workItem.isDedicatedQueueable())
			{
				enqueueJob(workItem);
			}
			else
			{
				workToQueue.add(workItem.enableQueueable(null));
			}
		}

		if (workToQueue.isEmpty()) return;

		enqueueJob((fflib_IUnitOfWork) new fflib_UnitOfWork(workToQueue));
	}

	/**
	 * Do start executing the work items which are not marked for Queued context.
	 */
	protected virtual void doRealTimeWork()
	{
		if (this.work.isEmpty()) return;

		for (fflib_IDoWork workItem : work)
		{
			if (workItem.isQueueable()) continue;

			doWork(workItem);
		}
	}

	/**
	 * @param workItem
	 */
	protected virtual void doWork(fflib_IDoWork workItem)
	{
		try
		{
			workItem.doWork();
		}
		catch (Exception e)
		{
			throw new WorkItemException('WorkItem failed to execute with error: ' + e.getMessage() + ' ' + e.getStackTraceString());
		}
	}

	public class WorkItemException extends Exception {}
}