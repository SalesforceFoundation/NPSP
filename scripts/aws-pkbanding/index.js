const https = require('https');
const { Worker, isMainThread, parentPort, workerData } = require('worker_threads');

// consts
const __lock = 'UNABLE_TO_LOCK_ROW';

// app vars
let totalEvents; 
let totalFailed; 
let errorRatio;  
let fixed_totalEvents; 
let fixed_totalFailed; 
let fixed_errorRatio;         
let startTime;
let totalBands;
let bandsCompleted;
let timer;
let reTryTimer;
let totalSeconds = 0;
const partitionBits = 3;
// re-try-row-lock var
let rowLock = [];       

// // init worker
// let documentworker = new Worker('/.parallel_worker.js');

// // worker response handler
// documentworker.onmessage = function(oEvent) {
//     let eData = oEvent.data;
//     if (eData === undefined) {
//         return 'Undefined value!';
//     } else if (typeof eData === 'string') {
//         log(eData);
//     } 
// };

// MainThread 
exports.handler = async (event,context,callback) => {

    let json = JSON.parse(event.body);
    console.info('Request body:\n' + JSON.stringify(json));
    
    // --- POST example request  
    let requestData = {                                                
        band: 0,
        chunkBits: json.chunkBits,
        batchSize: json.batchSize,
        partitionBits: json.partitionBits,
        session: json.session,
        url: json.url,
        offset: null,
        recordIds: null,
        isCursor: true,
        host: json.host,
        path: json.path
    };
    console.info('Salesforce request body:\n' + JSON.stringify(requestData));
    
    // --- POST OPTIONS example
    const options = {
        hostname: json.host,
        port: 443,
        path: json.path,
        method: 'POST',
        headers: {
            'Authorization': `Bearer ${json.session}`,
            'Content-Type': 'application/json'
        }
    }
    
    let r

    try {
        
        const postBody = await httpsRequest(options,requestData)
        // The console.log below will not run until the POST request above finishes
        console.log('POST response body:', postBody)

        requestData.band = 5
        const postBody2 = await httpsRequest(options,requestData)
        // The console.log below will not run until the POST request above finishes
        console.log('POST response body:', postBody2)
        
        r = JSON.stringify(postBody)+JSON.stringify(postBody2);
        console.info(r);
        
    } catch (err) {
        console.error('POST request failed, error:', err);
    }
    
    const response = {
        statusCode: 200,
        body: r,
    }
    
    return response
    
    // // execute a web worker per band
    // for (let i = 0; i < 2**partitionBits; i++){
        
    //     totalBands++;
    //     let requestData = {                                                
    //         band: i,
    //         isCursor: true,
    //         chunkBits: 15,
    //         batchSize: 20,
    //         partitionBits: partitionBits,
    //         offset: null,
    //         recordIds: null,
    //         session: 'event.data.session',
    //         url: 'event.data.url'
    //     };
    //     // post
    //     documentworker.postMessage(requestData);
        
    // }
    
    // // handle web-worker responses
    // // documentworker.onmessage = function(oEvent) {

    // //     let eData = oEvent.data;

    // //     if (eData === undefined) {
    // //         return 'Undefined value!';
    // //     }

    // //     // string data
    // //     if (typeof eData === 'string') {
    // //         log(eData);

    // //     // cursor type of data
    // //     } else if (eData.isCursor && eData.totalEvents!=null && eData.timeInSeconds!=null && eData.totalFailed!=null) {

    // //         // app vars
    // //         totalEvents += eData.totalEvents;
    // //         totalFailed += eData.totalFailed;
    // //         errorRatio = totalFailed === 0 ? 0 : ((totalFailed/totalEvents) * 100).toFixed(3);

    // //         // capture IDs of errors that contain __lock string
    // //         if (eData.totalFailed>0 && eData.failedRecordsIds!=undefined) {
    // //             for (let i of eData.failedRecordsIds){
    // //                 if (!rowLock.includes(i) && eData.failedRecords[i].indexOf(__lock)!=-1) rowLock.push(i);
    // //             }
    // //         }

    // //         // aux metric vars                    
    // //         let totTransactionsPerSecond = Math.round(totalEvents/eData.timeInSeconds);
    // //         let totTransactionsPerDay = Math.round((totalEvents/eData.timeInSeconds)*86400);
    // //         let totTransactionsPerHour = Math.round((totalEvents/eData.timeInSeconds)*3600);

    // //         // update results card
    // //         // document.getElementById('results-total').innerHTML = format_num(totalEvents);                    
    // //         // document.getElementById('results-failed').innerHTML = format_num(totalFailed); 
    // //         // document.getElementById('results-failed-ratio').innerHTML = `( ${errorRatio}% )`;                   
    // //         // document.getElementById('results-perday').innerHTML = format_num(totTransactionsPerDay);
    // //         // document.getElementById('results-perhour').innerHTML = format_num(totTransactionsPerHour);
    // //         // document.getElementById('results-transactions-seconds').innerHTML = format_num(totTransactionsPerSecond);

    // //         // when completed
    // //         if (eData.completed) {

    // //             bandsCompleted++;
    // //             log(' -----------------------------------------------');
    // //             log(` &emsp; #error-ratio: <b>${errorRatio}%</b>`);
    // //             log(` &emsp; #failed events: ${format_num(totalFailed)}`);
    // //             log(` &emsp; #total-events: <b>${format_num(totalEvents)}</b>`);
    // //             log(`<b>&nbsp; ${eData.band}:${eData.offset} = completed</b>`);
    // //             log(' -----------------------------------------------');
                
    // //             // calculate percentage of completion based on bands vs total-bands
    // //             const perc = ((bandsCompleted/totalBands) * 100).toFixed(3);
                
    // //             // 100% of web-workers completed
    // //             if (Math.round(perc)===100) {

    // //                 log(' -----------------------------------------------------');
    // //                 log(` >> ${totalBands} web-workes are finished (${timer})! `);                            
    // //                 log(' -----------------------------------------------------');
                                                
    // //                 // RE-TRY Logic for row_lock errors
    // //                 if (rowLock.length>0) {

    // //                     log(rowLock);                                
    // //                     log(`>> Re-try logic is needed for ${rowLock.length} record(s) caused by ${__lock} exception. Preparing fixed web-worker request...`);                                
                        
    // //                     // call web_worker with rowLock ids --- batch size hardcoded to 200
    // //                     let requestData = {
    // //                         band: null,
    // //                         chunkBits: null,                                    
    // //                         partitionBits: null,
    // //                         offset: null,
    // //                         session: __sfdcSessionId,
    // //                         url: __serviceUrl,
    // //                         isCursor: false,
    // //                         recordIds: rowLock,
    // //                         batchSize: 200
    // //                     };
    // //                     // post and clean rowLock
    // //                     documentworker.postMessage(requestData);
    // //                     rowLock = [];
    // //                 } else {
    // //                     // no rowlock retry needed, stop clock
    // //                     clearInterval(timer);
    // //                 }
    // //             }
    // //             // update progress bar
    // //             // document.getElementById('results-progress').style.width = `${perc}%`;
    // //         }

    // //     // fixed type of data
    // //     } else if (!eData.isCursor && eData.totalEvents!=null && eData.totalFailed!=null) {
            
    // //         fixed_totalEvents += eData.totalEvents;
    // //         fixed_totalFailed += eData.totalFailed;
    // //         fixed_errorRatio = fixed_totalFailed === 0 ? 0 : ((fixed_totalFailed/fixed_totalEvents) * 100).toFixed(3);

    // //         // capture IDs of errors that contain __lock string
    // //         if (eData.totalFailed>0 && eData.failedRecordsIds!=undefined) {
    // //             for (let i of eData.failedRecordsIds){
    // //                 if (!rowLock.includes(i) && eData.failedRecords[i].indexOf(__lock)!=-1) rowLock.push(i);
    // //             }
    // //             log(`ooo >>> Exist ${eData.totalFailed} failed RDs with ${__lock} exception in fixed web-worker: ${eData.failedRecordsIds}`);
    // //         }

    // //         // update results card
    // //         // document.getElementById('fixed-results-total').innerHTML = format_num(fixed_totalEvents);                    
    // //         // document.getElementById('fixed-results-failed').innerHTML = format_num(fixed_totalFailed); 
    // //         // document.getElementById('fixed-results-failed-ratio').innerHTML = `( ${fixed_errorRatio}% )`;

    // //         // when completed
    // //         if (eData.completed) {
    // //             clearInterval(timer);
    // //             log(' =============================================');
    // //             log(` &emsp; #error-ratio: <b>${fixed_errorRatio}%</b>`);
    // //             log(` &emsp; #failed events: ${format_num(fixed_totalFailed)}`);
    // //             log(` &emsp; #total-events: <b>${format_num(fixed_totalEvents)}</b>`);
    // //             log(`<b>&nbsp; Fixed web-workers completed in ${eData.timeInSeconds} seconds.</b>`);
    // //             log(' =============================================');
    // //             log(`${fixed_totalFailed>0?rowLock:''}`);
    // //         }

    // //     } else {
    // //         log(eData);
    // //     }

    // // };    
};

// Helper that turns https.request into a promise
function httpsRequest(options, requestData) {
    return new Promise((resolve, reject) => {
        const req = https.request(options, (res) => {
            if (res.statusCode < 200 || res.statusCode >= 300) {
                return reject(new Error('statusCode=' + res.statusCode));
            }
            var body = [];
            res.on('data', function(chunk) {
                body.push(chunk);
            });
            res.on('end', function() {
                try {
                    body = JSON.parse(Buffer.concat(body).toString());
                } catch(e) {
                    reject(e);
                }
                resolve(body);
            });
        });
        
        req.on('error', (e) => {
            reject(e.message);
        });
        
        req.write(JSON.stringify(requestData))
        
        req.end();
    });
}

// clean log panel and re-init app variables
function clean_log() {
    
    // app vars
    totalEvents = 0;       
    totalFailed = 0;     
    errorRatio = 0;    
    totalBands = 0;
    bandsCompleted = 0;
    startTime = Date.now();
    totalSeconds = 0;
    rowLock = [];
    fixed_totalEvents = 0;
    fixed_totalFailed = 0;
    fixed_errorRatio = 0;
    
}

// log into console 
function log (content) {
    let str = typeof content === 'string' ? content : JSON.stringify(content);
    str = str.length>10000 ? `${str.substring(0,10000)}...` : str;
    console.log(str);
}

// used to display percentages
function pad (val) {
    let valString = val + '';
    if (valString.length < 2) {
        return '0' + valString;
    } else {
        return valString;
    }
}

// format numbers for prety output
function format_num (num) {
    // Nine Zeroes for Billions
    return Math.abs(Number(num)) >= 1.0e+9

        ? Math.abs(Number(num)) / 1.0e+9 + 'B'
        // Six Zeroes for Millions
        : Math.abs(Number(num)) >= 1.0e+6

            ? Math.abs(Number(num)) / 1.0e+6 + 'M'
            // Three Zeroes for Thousands
            : Math.abs(Number(num)) >= 1.0e+3

                ? Math.abs(Number(num)) / 1.0e+3 + 'K'

                : Math.abs(Number(num));
}