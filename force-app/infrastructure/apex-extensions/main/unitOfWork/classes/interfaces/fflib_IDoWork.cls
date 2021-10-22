/**
 * File Name: fflib_IDoWork
 * Description: Interface defining the method signatures for a work item used by the UnitOfWork
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
public interface fflib_IDoWork extends Comparable
{
	/**
	 * Do the work of this work item
	 */
	void doWork();

	/**
	 * Enable the work item to be executed in separate UnitOfWork executed in a Queueable context
	 *
	 * @return Instance of itself to allow for chaining
	 */
	fflib_IDoWork enableQueueable();

	/**
	 * Enable the work item to be executed as Queueable, not combined with other work items
	 *
	 * @param dedicated When true, execute in a dedicated Queueable context.
	 *
	 * @return Instance of itself to allow for chaining
	 */
	fflib_IDoWork enableQueueable(Boolean dedicated);

	/**
	 * Gets the priority of this work item. The higher the number the higher the priority
	 *
	 * @return Returns the priority
	 */
	Integer getPriority();

	/**
	 * @return Returns true when the work item is intended to be executed in separate UnitOfWork executed in a Queueable context
	 */
	Boolean isQueueable();

	/**
	 * @return Returns true when the work item is intended to run in real-time
	 */
	Boolean isNotQueueable();

	/**
     * @return Returns true when the work item is intended to be executed as Queueable, not combined with other work items
     */
	Boolean isDedicatedQueueable();

	/**
	 * Sets the priority value of the work item, this is used to sort the work items
	 *
	 * @param priority The priority value, the working with the highest priority value will be executed first
	 *
	 * @return Instance of itself to allow for chaining
	 */
	fflib_IDoWork setPriority(Integer priority);
}