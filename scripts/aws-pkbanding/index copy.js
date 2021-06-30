const https = require('https')
//var jsforce = require('jsforce')

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

exports.handler = async (event, context, callback) => {
    
    let json = JSON.parse(event.body)
    console.info('Request body:\n' + JSON.stringify(json))
    
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
    }
    console.info('Salesforce request body:\n' + JSON.stringify(requestData))
    
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
    
};