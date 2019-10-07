Class Demo.BS.EmailReader Extends Ens.BusinessService
{

// Parameter ADAPTER = "EnsLib.EMail.InboundAdapter";
Parameter ADAPTER = "EMail.InboundAdapterIMAP";

Parameter SETTINGS = "TargetConfigName::selector?context={Ens.ContextSearch/ProductionItems?targets=1&productionName=@productionId}";

Property TargetConfigName As %String(MAXLEN = 1000);

Method OnProcessInput(pInput As %Net.MailMessage, Output pOutput As %RegisteredObject) As %Status
{
   set tSC = $$$OK
   try {
	   
	   if (..TargetConfigName="") {
		   $$$LOGERROR("No target config name set")
		   quit
	   }
	   
	   if 'pInput.IsMultiPart {
		   $$$LOGWARNING("Message is not MultiPart, skipping")
		   quit
	   }
	   
	   set tRequest = ##class(Demo.Messages.ReceiptRequest).%New()
	   set tRequest.SenderEMail = $s(pInput.From="":pInput.Sender, 1:pInput.From)
	   set tRequest.OriginalSubject = pInput.Subject
	   set tRequest.OriginalDate = pInput.Date
	   set tRequest.OriginalText = pInput.TextData.Read()
	   
	   #dim tPart as %Net.MailMessagePart
	   set tKey = ""
	   for {
		   set tPart = pInput.Parts.GetNext(.tKey)
		   quit:tKey=""
		   
		   // only interested in binary image data
		   continue:'tPart.IsBinary
		   
		   if (tPart.ContentType="image/jpeg") || (tPart.ContentType="image/png") || (tPart.ContentType="image/jpg") {
			   set tRequest.FileName = tPart.FileName
			   do tRequest.ImageData.CopyFromAndSave(tPart.BinaryData)
			   
			   set tSC = ..SendRequestAsync(..TargetConfigName, tRequest)
			   quit:$$$ISERR(tSC)
		   } else {
			   $$$LOGWARNING("Unsupported attachment type: "_tPart.ContentType)
			   continue
		   }
		   quit:$$$ISERR(tSC)
	   }
	   
   } catch (ex) {
	   set tSC = ex.AsStatus()
   }
   quit tSC
}

ClassMethod OnGetConnections(Output pArray As %String, pItem As Ens.Config.Item)
{
	if pItem.GetSetting("TargetConfigName", .tTarget) {
		set pArray(tTarget)=""
	}
	Quit
}

}

