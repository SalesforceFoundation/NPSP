/**
 * File Name: fflib_IUnitOfWork
 * Description: Interface class with method signatures for the Unit Of Work
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
public interface fflib_IUnitOfWork
{
	/**
	 * Adds a single work item is executed in a dedicated Queued context after the UnitOfWork is finished
	 *
	 * @param nextWork work item to be executed after the UnitOfWork is finished
	 *
	 * @return Instance of itself to allow for method chaining
	 */
	fflib_IUnitOfWork addNext(fflib_IDoWork nextWork);

	/**
	 * Adds a UnitOfWork to be executed in a Queued context after the UnitOfWork is finished
	 *
	 * @param nextWork UnitOfWork to be executed after the UnitOfWork is finished
	 *
	 * @return Instance of itself to allow for method chaining
	 */
	fflib_IUnitOfWork addNext(fflib_IUnitOfWork nextWork);

	/**
	 * Adds an ordered list of UnitOfWork to be executed each in a separate Queued context after the UnitOfWork is finished
	 *
	 * @param nextWork UnitOfWork to be executed after the UnitOfWork is finished
	 *
	 * @return Instance of itself to allow for method chaining
	 */
	fflib_IUnitOfWork addNext(List<fflib_IUnitOfWork> nextWork);

	/**
	 * Add a single work item to the queue
	 *
	 * @param work work item to be added
	 *
	 * @return Instance of itself to allow for method chaining
	 */
	fflib_IUnitOfWork addWork(fflib_IDoWork work);

	/**
	 * Adds a list of work items to the queue
	 *
	 * @param work work items to be added
	 *
	 * @return Instance of itself to allow for method chaining
	 */
	fflib_IUnitOfWork addWork(List<fflib_IDoWork> work);

	/**
	 * Do the work contained in the UnitOfWork
	 */
	void doWork();
}