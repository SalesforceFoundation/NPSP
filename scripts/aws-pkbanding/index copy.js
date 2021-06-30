const https = require('https')
const jsforce = require('jsforce')

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

    // get request data
    let json = JSON.parse(event.body)
    console.info('HTTP Request body:\n' + JSON.stringify(json))

    // --- POST example request  
    let requestData = {                                                
        band: 0,
        chunkBits: json.chunkBits,
        batchSize: json.batchSize,
        partitionBits: json.partitionBits,        
        offset: null,
        recordIds: null,
        isCursor: true,        
        host: json.host,
        path: json.path,
        // url: json.host+json.path,
        session: json.session
    }
    console.info('Outbound Salesforce request body:\n' + JSON.stringify(requestData))
    
    // response aux variable
    let r = ''

    // connect to sf
    var conn = new jsforce.Connection({    	
      	sessionId : json.session,
      	serverUrl : json.host
    })

    // call apex rest methods	
	conn.apex.post(json.path, requestData, (err, res) => {
	    if (err) { 
            return console.error(err)
        }
	    console.log("response from jsforce: ", res)
	    // the response object structure depends on the definition of apex class
        r += `JSForce-Rest:${JSON.stringify(res)}`;
	})

    // create record
    conn.sobject("Account").create({ Name : 'My AWS Account #2' }, (err, ret) => {
        if (err || !ret.success) { 
            console.info('Error creating Account')
            return console.error(err, ret)
        }
        console.log("Created record id : " + ret.id)
        r += `Account created: ${ret.id}`;
    })   
                
    // --- POST OPTIONS example
    const agent = new https.Agent({
        // maxSockets: 1,
        keepAlive: true      
    })
    const options = {
        agent: agent,
        hostname: json.host.replace('https://', ''),
        port: 443,
        path: json.path,
        method: 'POST',
        headers: {
            'Authorization': `Bearer ${json.session}`,
            'Content-Type': 'application/json'
        }
    }        

    try {
        
        requestData.band = 2
        const postBody = await httpsRequest(options,requestData)
        // The console.log below will not run until the POST request above finishes
        console.log('POST response body:', postBody)

        requestData.band = 5
        const postBody2 = await httpsRequest(options,requestData)
        // The console.log below will not run until the POST request above finishes
        console.log('POST response body:', postBody2)
        
        r += JSON.stringify(postBody)+JSON.stringify(postBody2);
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