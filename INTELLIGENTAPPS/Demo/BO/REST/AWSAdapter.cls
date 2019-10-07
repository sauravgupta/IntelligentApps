Class Demo.BO.REST.AWSAdapter Extends Adapter
{

Parameter SETTINGS = "AWSAccessKeyId,AWSSecretAccessKey,Region,Service";

Property AWSAccessKeyId As %String [ InitialExpression = "AKIDEXAMPLE" ];

Property AWSSecretAccessKey As %String [ InitialExpression = "wJalrXUtnFEMI/K7MDENG+bPxRfiCYEXAMPLEKEY" ];

Property Region As %String [ InitialExpression = "us-east-1" ];

Property Service As %String [ InitialExpression = "iam" ];

Method AddAuthorization(ByRef pHttpRequest As %Net.HttpRequest, pMethod As %String = "POST") As %Status
{
	set tSC = $$$OK
	try {
		// TODO: merge / separate functions (only set headers in this method!)
		set tSC = ..BuildAuthorizationHeader(.pHttpRequest, pMethod,, .tAuthorization)
		quit:$$$ISERR(tSC)
		
		set pHttpRequest.Authorization = tAuthorization
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method BuildAuthorizationHeader(pHttpRequest As %Net.HttpRequest, pOperation As %String = "", pURL As %String = "", Output pAuthorizationHeader As %String, pVerbose As %Boolean = 0) As %Status
{
	set tSC = $$$OK
	try {
		if ..AWSAccessKeyId="" {
			set tSC = $$$ERROR($$$GeneralError, "No AWS Access Key ID provided")
			quit
		}
		if ..AWSSecretAccessKey="" {
			set tSC = $$$ERROR($$$GeneralError, "No AWS Secret Access Key provided")
			quit
		}
		
		set tAMZDateTime = $tr($zdatetime($h,8,7),":")  // 20190319T151009Z
		//set tAMZDateTime = "20150830T123600Z" // for test
		set tAMZDate = $e(tAMZDateTime,1,8) 			// 20190319
		set tLineBreak = $c(10)
		
		set pOperation = $$$UPPER(pOperation)
		
		// ensure the right date is set
		do pHttpRequest.SetHeader("X-Amz-Date", tAMZDateTime)
		
		
		// ************* TASK 1: CREATE A CANONICAL REQUEST *************
		// http://docs.aws.amazon.com/general/latest/gr/sigv4-create-canonical-request.html

		// Step 1 is to define the verb (GET, POST, etc.) -- inferred from pOperation

		// Step 2: Create canonical URI--the part of the URI from domain to query 
		// string (use '/' if no path)
		set tCanonicalURL = $s($e(pURL,1)="/":pURL, $e(pURL,1)'="":"/"_pURL, 1:"/"_pHttpRequest.Location)
		
		
		// Step 3: Create the canonical query string. In this example (a GET request),
		// request parameters are in the query string. Query string values must
		// be URL-encoded (space=%20). The parameters must be sorted by name.
		// For this example, the query string is pre-formatted in the request_parameters variable.
		set tQueryString = $piece(tCanonicalURL,"?",2,*)
		set tCanonicalURL = $piece(tCanonicalURL,"?",1)
		
		// TODO: append pHttpRequest.Params content?
		// TODO: sort params!
		
		// Step 4: Create the canonical headers and signed headers. Header names
		// must be trimmed and lowercase, and sorted in code point order from
		// low to high. Note that there is a trailing \n.
		set tCanonicalHeaders = "content-type:" _ pHttpRequest.ContentType _ tLineBreak
								_ "host:" _ pHttpRequest.Server _ tLineBreak
								_ "x-amz-date:" _ tAMZDateTime _ tLineBreak

		// Step 5: Create the list of signed headers. This lists the headers
		// in the canonical_headers list, delimited with ";" and in alpha order.
		// Note: The request can include any headers; canonical_headers and
		// signed_headers lists those that you want to be included in the 
		// hash of the request. "Host" and "x-amz-date" are always required.
		set tSignedHeaders = "content-type;host;x-amz-date"
		
		// Step 6: Create payload hash (hash of the request body content). For GET
		// requests, the payload is an empty string ("").
		if (pOperation = "GET") {
			set tPayload = ""
		} else {
			// TODO
			set tPayload = ""
		}
		set tPayloadHash = ..Hex($SYSTEM.Encryption.SHAHash(256,$zconvert("","O","UTF8")))
		
		
		// Step 7: Combine elements to create canonical request
		set tCanonicalRequest = pOperation _ tLineBreak
									_ tCanonicalURL _ tLineBreak
									_ tQueryString _ tLineBreak
									_ tCanonicalHeaders _ tLineBreak 
									_ tSignedHeaders _ tLineBreak
									_ tPayloadHash
		set tCanonicalRequestHash = ..Hex($SYSTEM.Encryption.SHAHash(256, tCanonicalRequest))
		
		w:pVerbose !!,"Canonical request:",!,$replace(tCanonicalRequest,tLineBreak,"<"_$c(13,10)),!!,"Hash: ",tCanonicalRequestHash,!

		// ************* TASK 2: CREATE THE STRING TO SIGN*************
		// Match the algorithm to the hashing algorithm you use, either SHA-1 or
		// SHA-256 (recommended)
		set tAlgorithm = "AWS4-HMAC-SHA256"
		set tCredentialScope = tAMZDate _ "/" _ ..Region _ "/" _ ..Service _ "/" _ "aws4_request"
		set tStringToSign = tAlgorithm _ tLineBreak 
							_ tAMZDateTime _ tLineBreak 
							_ tCredentialScope _ tLineBreak
							_ tCanonicalRequestHash
		w:pVerbose !!,"String to sign:",!,$replace(tStringToSign,tLineBreak,$c(13,10)),!
							
		// ************* TASK 3: CALCULATE THE SIGNATURE *************
		// Create the signing key using the function defined above.
		// def getSignatureKey(key, dateStamp, regionName, serviceName):
    	set tSigningKey = ..GenerateSigningKey(tAMZDate)
    	w:pVerbose !!,"Signing key:",!,..Hex(tSigningKey),!

		// Sign the string_to_sign using the signing_key
		set tSignature = ..Hex($SYSTEM.Encryption.HMACSHA(256, tStringToSign, tSigningKey))
		
		
		// ************* TASK 4: ADD SIGNING INFORMATION TO THE REQUEST *************
		// The signing information can be either in a query string value or in 
		// a header named Authorization. This code shows how to use a header.
		// Create authorization header and add to request headers
		set pAuthorizationHeader = tAlgorithm _ " Credential=" _ ..AWSAccessKeyId _ "/" _ tCredentialScope _ ", SignedHeaders=" _ tSignedHeaders _ ", Signature=" _ tSignature
		w:pVerbose !!,"Authorization header:",!,pAuthorizationHeader,!!
		b
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method GenerateSigningKey(pDate As %String) As %String
{
	set kDate = $SYSTEM.Encryption.HMACSHA(256, pDate, $zconvert("AWS4" _ ..AWSSecretAccessKey,"O","UTF8"))
    //w !,"kDate: ",..Hex(kDate)
    set kRegion = $SYSTEM.Encryption.HMACSHA(256, ..Region, kDate)
    //w !,"kRegion: ",..Hex(kRegion)
    set kService = $SYSTEM.Encryption.HMACSHA(256, ..Service, kRegion)
    //w !,"kService: ",..Hex(kService)
    set tSigningKey = $SYSTEM.Encryption.HMACSHA(256, "aws4_request", kService)
    //w !,"kSigning: ",..Hex(tSigningKey),!	
	quit tSigningKey
}

ClassMethod Hex(pRaw As %String) As %String [ Internal ]
{
	set out="", l=$l(pRaw)
	for i = 1:1:l {
		set out=out_$zhex($ascii(pRaw,i))
	}
	quit $$$LOWER(out)
}

}

