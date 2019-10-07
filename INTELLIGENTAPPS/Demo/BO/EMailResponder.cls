Class Demo.BO.EMailResponder Extends Ens.BusinessOperation
{

Parameter ADAPTER = "EnsLib.EMail.OutboundAdapter";

Method SendEmail(pRequest As Demo.Messages.ResponseEmailRequest, Output pResponse As Ens.Response) As %Status
{
	set tSC = $$$OK
	try {
		set tEMail = ##class(%Net.MailMessage).%New()
		do tEMail.To.Insert(pRequest.ToEMail)
		set tEMail.Subject = pRequest.Subject
		set tEMail.From = "InterSystems Global Summit Demo <gs19user01@intersystemslabs.com>" //This is not the email id for everyone, but it will do for now
		set tEMail.IsHTML = 1
		if $f(pRequest.ToEMail,"<") {
			set tHI = " "_$zstrip($piece(pRequest.ToEMail,"<",1),"<>WC")
		} else {
			set tHI = ""
		}
		do tEMail.TextData.WriteLine("<html><body>")
		do tEMail.TextData.WriteLine("<h2>Request status: "_pRequest.RequestStatus_"</h2>")
		do tEMail.TextData.WriteLine("<p>Hi"_tHI_",<br/>Your claim was submitted on "_pRequest.OriginalDate_"</p>")		
		if pRequest.RequestStatus="Incomplete" {
			do tEMail.TextData.WriteLine("<p>Your claim could not be processed at this time. Please check whether you submitted all required inputs and resend.</p>")
			do:pRequest.Message'="" tEMail.TextData.WriteLine("<p><blockquote><tt>"_pRequest.Message_"</tt></blockquote></p>")
		}
		else {
			if pRequest.RequestStatus="NeedsReview" {
				do tEMail.TextData.WriteLine("<p>Your claim could not be approved by the automated workflow and is now queued for manual review. <br/>Please allow up to two business days for further processing.</p>")
			}
			elseif pRequest.RequestStatus="Complete" {
				do tEMail.TextData.WriteLine("<p>Your prescription will now undergo further manual processing. We will advise you within two business days about the status of your claim.</p>")
			}
			elseif pRequest.RequestStatus="Approved" {
				do tEMail.TextData.WriteLine("<p>Your claim was processed successfully by the automated workflow and is now queued for reimbursement according to your plan. <br/>Please allow up to 5 business days for the money to be wired to your account.</p>")
			}
			else {
				do tEMail.TextData.WriteLine("<p>Your claim could not be processed for an unknown reason. Please speak to your Smart Health Inc. representative.</p>")
			}
			do tEMail.TextData.WriteLine("<h4>Be Smart about your Health</h4>")
			do tEMail.TextData.WriteLine("<p>Your submitted receipt listed a number of medications or pharmaceutical products. At Smart Health, we care about you and anonymously checked the National Library of Medicine for possible interactions between your current medications. Based on your medication history, please take note of the following:</p><ul>")
			if pRequest.InteractionInfo.Interactions.Count() {
				#dim tInteraction as Demo.Messages.DrugInteraction
				for i=1:1:pRequest.InteractionInfo.Interactions.Count() {
					set tInteraction = pRequest.InteractionInfo.Interactions.GetAt(i)
					if (tInteraction.Description="") {
						do tEMail.TextData.WriteLine("<li>"_tInteraction.Comment_"</li>")
					} else {
						do tEMail.TextData.WriteLine("<li>"_tInteraction.Description_"</li>")
					}
				}
			} else {
				do tEMail.TextData.WriteLine("<li>No known interactions</li>")
			}
			do tEMail.TextData.WriteLine("</ul><p><blockquote><b>Disclaimer</b>: <small>"_pRequest.InteractionInfo.Disclaimer_"</small></blockquote></p>")
		}
		
		do tEMail.TextData.WriteLine("<p>Thank you for your confidence in Smart Health Inc.</p>")
		do tEMail.TextData.WriteLine("<p>Have a nice day!</p>")
		do tEMail.TextData.WriteLine("</body></html>")
		
		set tSC = ..Adapter.SendMail(tEMail)
		set pResponse = ##class(Ens.StringResponse).%New()
		if $$$ISERR(tSC) {
			set pResponse.StringValue = $system.Status.GetErrorText(tSC)
		} else {
			do tEMail.TextData.Rewind()
			set pResponse.StringValue = tEMail.TextData.Read()
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

XData MessageMap
{
<MapItems>
  <MapItem MessageType="Demo.Messages.ResponseEmailRequest">
    <Method>SendEmail</Method>
  </MapItem>
</MapItems>
}

}

