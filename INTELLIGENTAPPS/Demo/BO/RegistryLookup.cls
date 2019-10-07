Class Demo.BO.RegistryLookup Extends Ens.BusinessOperation
{

Method Lookup(pRequest As Demo.Messages.RegistryLookupRequest, pResponse As Demo.Messages.RegistryLookupResponse) As %Status
{
	set tSC = $$$OK
	try {
		
		set pResponse = ##class(Demo.Messages.RegistryLookupResponse).%New()
		
		if pRequest.PatientID'="" {
			set tSerial = ##class(Demo.Messages.PatientInfo).PopulateSerial()
			set pResponse.PatientInfo = ##class(Demo.Messages.PatientInfo).%Open(tSerial)
			//the above is being populated randomly
			//set the patient ID and name to be the same as the one in the email for demonstrating the message content
			set pResponse.PatientInfo.PatientID = pRequest.PatientID
			set pResponse.PatientInfo.Name = $zstrip($piece(pRequest.PatientEMail,"<",1),"<>WC")
		}
		//special case to catch an OCR Error
		if pRequest.PrescriberID = "Z0000000000O" {
			set tSerial = ##class(Demo.Messages.PrescriberInfo).PopulateSerial()
			set pResponse.PrescriberInfo = ##class(Demo.Messages.PrescriberInfo).%Open(tSerial)
			set pResponse.PrescriberInfo.Name = "UNKNOWN"
            set pResponse.PrescriberInfo.PrescriberID = pRequest.PrescriberID
		}
		elseif pRequest.PrescriberID'="" {
			set tSerial = ##class(Demo.Messages.PrescriberInfo).PopulateSerial()
			set pResponse.PrescriberInfo = ##class(Demo.Messages.PrescriberInfo).%Open(tSerial)
			//the above is being populated randomly
			//set the prescriber ID to be the same as the one in the receipt for demonstrating the message content
			set pResponse.PrescriberInfo.PrescriberID = pRequest.PrescriberID
		}
	} catch (ex) {
		set tSC = ex.AsStatus()
		$$$LOGSTATUS(tSC)
	}
	quit tSC
}

XData MessageMap
{
<MapItems>
  <MapItem MessageType="Demo.Messages.RegistryLookupRequest">
    <Method>Lookup</Method>
  </MapItem>
</MapItems>
}

}

