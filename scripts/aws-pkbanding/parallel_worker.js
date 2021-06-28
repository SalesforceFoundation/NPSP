const fetch = require('https');
const { Worker, isMainThread, parentPort, workerData } = require('worker_threads');

onmessage = (oEvent) => {

    // env vars                
    let startTime = Date.now();
    
    // init web worker
    // web_worker(oEvent.data);
    postMessage(`>> Web_Worker with data: ${JSON.stringify(oEvent.data)}`);
    postMessage(`>> Web_Worker function: ${getRandomInt(10,4000)}`)

    // web service
    async function web_worker(requestData) {

        postMessage(requestData);
        if (requestData.isCursor) {                        
            postMessage(`>> Starting web_worker(${requestData.band}:${requestData.offset}) for:`);
        } else {                        
            postMessage(`ooo >> Starting re-try logic, processing <b>${requestData.batchSize}</b> record(s) of <b>${requestData.recordIds.length}</b> in total.`);
        }
        
        // create async request
        fetch (requestData.url, {
            
            method: 'POST',
            body: JSON.stringify(requestData),
            mode: 'cors',
            headers: {
                'Authorization': `Bearer ${requestData.session}`,
                'Content-Type': 'application/json',
                'Allow-Cross-Origin': '*'
            }
            
        }).then(
            response => {
                // response exists && status == 200
                if (typeof response !== 'undefined' && response.ok) {
                    // handle somewhere else
                    return response.json();
                }

                // re-Try logic when we hit governor limits on salesforce and service returns != 200 status
                const t = getRandomInt(1000, 3000);
                const b = (requestData.batchSize*0.75) | 0 ;

                // re-try logic while batch size is greater than 0
                if (b>0) {
                    requestData.batchSize = b;
                    if (requestData.isCursor) {                                    
                        postMessage(`<** Error on request for web_worker(${requestData.band}:${requestData.offset}): Re-Try logic using batchSize=${b} (fetching in ${t/1000}s)...`);
                    } else {                                    
                        postMessage(`ooo <** Error on request for fixed web_worker [${requestData.batchSize} of ${requestData.recordIds.length} in total]: Re-Try logic using batchSize=${b} (fetching in ${t/1000}s)...`);
                    }
                    
                    // set random timeout | usually Apex CPU Time Exceeded
                    setTimeout(()=>{web_worker(requestData)}, t);
                } else {
                    if (requestData.isCursor) {                                                                            
                        postMessage(`<<[[[[[ Re-Try logic ended because batchSize reached minimum amount (0) | web_worker(${requestData.band}:${requestData.offset}) ]]]]]`);
                    } else {                                    
                        postMessage(`ooo <<[[[[[ Re-Try logic ended because batchSize reached minimum amount (0) | fixed web_worker [${requestData.batchSize} of ${requestData.recordIds.length} in total] ]]]]]`);
                    }           
                }                           

            }
        ).then(
            jsonResponse => {

                if (typeof jsonResponse !== 'undefined') {
                    // get cursor
                    let reqData = jsonResponse.cursor;
                    postMessage(jsonResponse);
                    // log data to JS
                    if (requestData.isCursor) {                                    
                        postMessage(`<< web_worker(${reqData.band+':'+reqData.offset}) response:`);
                    } else {
                        // clone function is not working correctly for set of Ids, need to replace it with the one in response 
                        // reqData.recordIds = jsonResponse.cursor.recordIds                                    
                        postMessage(`ooo << fixed web_worker response (${requestData.batchSize} of ${requestData.recordIds.length} in total):`);
                    }
                    
                    // evaluate response
                    if (jsonResponse.result && !jsonResponse.completed) {
                        
                        // log info                                     
                        if (requestData.isCursor) {                                        
                            postMessage(`&nbsp; >> Creating next web_worker(${reqData.band+':'+reqData.offset})...`);
                        } else {                                        
                            postMessage(`&nbsp; ooo >> Creating next fixed web_worker[${reqData.batchSize}:${reqData.recordIds.length}]...`);                                    
                        }
                                                            
                        // send partial results to JS
                        let jsResponse = {
                            totalEvents: jsonResponse.numberProcessed,                                              
                            totalFailed: jsonResponse.numberErrors,
                            failedRecords: jsonResponse.failedRecords,
                            failedRecordsIds: jsonResponse.failedRecordsIds,
                            band: jsonResponse.cursor.band,                                                                          
                            completed: false,
                            timeInSeconds: (Date.now() - startTime)/1000,
                            isCursor: reqData.isCursor
                        };
                        postMessage(jsResponse);

                        // recursive call to get remaining data
                        web_worker(reqData);

                    } else if (!jsonResponse.result) {

                        const t = getRandomInt(1000, 3000); // number
                        const b = (jsonResponse.cursor.batchSize*0.75) | 0 ;
                        reqData.batchSize = b;

                        // if processed data, send partial results to JS
                        if (jsonResponse.numberProcessed > 0 || jsonResponse.numberErrors>0) {
                            let jsResponse = {
                                totalEvents: jsonResponse.numberProcessed,  
                                totalFailed: jsonResponse.numberErrors,
                                failedRecords: jsonResponse.failedRecords,
                                failedRecordsIds: jsonResponse.failedRecordsIds,
                                band: jsonResponse.cursor.band,                                            
                                completed: false,
                                timeInSeconds: (Date.now() - startTime)/1000,
                                isCursor: reqData.isCursor
                            };
                            postMessage(jsResponse);
                        }
                        
                        if (b>0) {
                            if (requestData.isCursor) {                                        
                                postMessage(`&nbsp; ><* Error in web_worker(${reqData.band+':'+reqData.offset}) response: Re-Try logic with batchSize=${b} (fetching in ${t/1000}s)...`);
                            } else {                                        
                                postMessage(`&nbsp; ooo ><* Error in web_worker[${reqData.batchSize}:${reqData.recordIds.length}] response: Re-Try logic with batchSize=${b} (fetching in ${t/1000}s)...`);                                    
                            }                                        
                            // set random timeout | usually DataLakeServiceApi - InteralServerError message
                            setTimeout(()=>{web_worker(reqData)}, t);
                        } else {
                            if (requestData.isCursor) {                                                                            
                                postMessage(`<<[[[[[ Re-Try logic ended because batchSize reached minimum amount (0) | web_worker(${requestData.band}:${requestData.offset}) ]]]]]`);
                            } else {                                    
                                postMessage(`ooo <<[[[[[ Re-Try logic ended because batchSize reached minimum amount (0) | fixed web_worker [${requestData.batchSize} of ${requestData.recordIds.length} in total] ]]]]]`);
                            }                                    
                        }                                   

                    } else if (jsonResponse.completed) {

                        // return results to JS
                        let jsResponse = {
                            totalEvents: jsonResponse.numberProcessed, 
                            totalFailed: jsonResponse.numberErrors,
                            failedRecords: jsonResponse.failedRecords,
                            failedRecordsIds: jsonResponse.failedRecordsIds,
                            band: jsonResponse.cursor.band,                                        
                            completed: true,
                            timeInSeconds: (Date.now() - startTime)/1000,
                            isCursor: jsonResponse.cursor.isCursor
                        };
                        // return results
                        postMessage(jsResponse);
                        
                    }
                }else{                                
                    // re-Try logic when we hit governor limits on salesforce and service returns != 200 status
                    const t = getRandomInt(1000, 3000);
                    const b = (requestData.batchSize*0.75) | 0 ;

                    // re-try logic while batch size is greater than 0
                    if (b>0) {
                        requestData.batchSize = b;                                    
                        if (requestData.isCursor) {                                    
                            postMessage(`<** jsonResponse is undefined for web_worker(${requestData.band}:${requestData.offset}): Re-Try logic using batchSize=${b} (fetching in ${t/1000}s)...`);
                        } else {                                    
                            postMessage(`ooo <** jsonResponse is undefined for fixed web_worker [${requestData.batchSize} of ${requestData.recordIds.length} in total]: Re-Try logic using batchSize=${b} (fetching in ${t/1000}s)...`);
                        }                                    
                        // set random timeout | usually Apex CPU Time Exceeded
                        setTimeout(()=>{web_worker(requestData)}, t);
                    } else {
                        if (requestData.isCursor) {                                                                            
                            postMessage(`<<[[[[[ Re-Try logic ended because batchSize reached minimum amount (0) | web_worker(${requestData.band}:${requestData.offset}) ]]]]]`);
                        } else {                                    
                            postMessage(`ooo <<[[[[[ Re-Try logic ended because batchSize reached minimum amount (0) | fixed web_worker [${requestData.batchSize} of ${requestData.recordIds.length} in total] ]]]]]`);
                        }                                    
                    }  
                }

            } // end jsonResponse => {
        );

    }

};


// random integer between min and max
function getRandomInt(min, max) {
    return Math.floor(Math.random() * (max - min) + min);
}