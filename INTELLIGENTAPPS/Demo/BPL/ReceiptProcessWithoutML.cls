/// This process integrates the computer vision AI service provided by Microsoft Azure to analyse the images of the receipts and extract the text from it. This text is then parsed into a structured format and the prescriptions are sent to the national institute of health web service to query for drug interactions, as a value added service. Any drug interactions are then included in the email response to the client alongwith a status report of their claim.
Class Demo.BPL.ReceiptProcessWithoutML Extends Ens.BusinessProcessBPL [ DependsOn = Demo.BPL.ProcessContext ]
{

/// BPL Definition
XData BPL [ XMLNamespace = "http://www.intersystems.com/bpl" ]
{
<process language='objectscript' request='Demo.Messages.ReceiptRequest' response='Ens.StringResponse' contextsuperclass='Demo.BPL.ProcessContext' height='2000' width='2000' >
<context>
<property name='ExtractedText' type='%String' instantiate='0' >
<parameters>
<parameter name='MAXLEN'  value='' />
</parameters>
</property>
<property name='ScannedRxCodes' type='%String' collection='array' instantiate='0' >
<parameters>
<parameter name='MAXLEN'  value='50' />
</parameters>
</property>
<property name='RequestStatus' type='%String' initialexpression='"Incomplete"' instantiate='0' >
<parameters>
<parameter name='MAXLEN'  value='50' />
</parameters>
</property>
<property name='ResponseMessage' type='%String' instantiate='0' >
<parameters>
<parameter name='MAXLEN'  value='2500' />
</parameters>
</property>
<property name='AnomalyModelDistance' type='%Numeric' initialexpression='2000' instantiate='0' />
<property name='InteractionInfo' type='Demo.Messages.DrugInteractionResponse' instantiate='0' />
<property name='ScannedRxCodesList' type='%String' collection='list' instantiate='0' >
<parameters>
<parameter name='MAXLEN'  value='50' />
</parameters>
</property>
</context>
<sequence xend='200' yend='1200' >
<call name='Extract text from image' target='Text Extraction' async='0' xpos='200' ypos='250' >
<annotation><![CDATA[Calls an Azure Vision API service to extract text from the scanned receipt]]></annotation>
<request type='Demo.Messages.OCRRequest' >
<assign property="callrequest.ImageData" value="request.ImageData" action="set" />
</request>
<response type='Demo.Messages.OCRResponse' >
<assign property="context.ExtractedText" value="callresponse.ExtractedText" action="set" />
</response>
</call>
<call name='Extract prescriber &amp; meds' target='Recognizer' async='0' xpos='200' ypos='350' >
<annotation><![CDATA[Checks RxTerm database for matches in the supplied text extract and identify prescriber ID.]]></annotation>
<request type='Demo.Messages.RecognizerRequest' >
<assign property="callrequest.RawText" value="context.ExtractedText" action="set" />
</request>
<response type='Demo.Messages.RecognizerResponse' >
<assign property="context.ScannedRxCodes" value="##class(Demo.Util.Functions).ExtractRxCodesAndInventDosage(callresponse.Medications)" action="set" >
<annotation><![CDATA[Save an array of prescriptions for the machine learning query]]></annotation>
</assign>
<assign property="context.PrescriberInfo.PrescriberID" value="callresponse.PrescriberID" action="set" />
<assign property="context.ScannedRxCodesList" value="##class(Demo.Util.Functions).ExtractRxCodes(callresponse.Medications)" action="set" >
<annotation><![CDATA[Save a list to send as a query for drug interactions]]></annotation>
</assign>
</response>
</call>
<call name='Lookup registry data' target='Registry Lookup' async='0' xpos='200' ypos='450' >
<annotation><![CDATA[Look up patient and prescriber data in registry]]></annotation>
<request type='Demo.Messages.RegistryLookupRequest' >
<assign property="callrequest.PatientID" value="request.SenderEMail" action="set" />
<assign property="callrequest.PatientEMail" value="request.SenderEMail" action="set" />
<assign property="callrequest.PrescriberID" value="context.PrescriberInfo.PrescriberID" action="set" />
</request>
<response type='Demo.Messages.RegistryLookupResponse' >
<assign property="context.PrescriberInfo" value="callresponse.PrescriberInfo" action="set" />
<assign property="context.PatientInfo" value="callresponse.PatientInfo" action="set" />
</response>
</call>
<rule name='Check completeness' rule='Demo.Rule.CheckInput'  resultLocation='context.RequestStatus' ruleContext='context' xpos='200' ypos='550' >
<annotation><![CDATA[Use a Business Rule to check if all information relevant for a reimbursement claim is supplied appropriately.]]></annotation>
</rule>
<if name='Complete?' condition='context.RequestStatus="Complete"' xpos='200' ypos='650' xend='200' yend='1000' >
<true>
<call name='Call interaction database' target='Drug Interactions' async='1' xpos='335' ypos='800' >
<annotation><![CDATA[Checks for potential adverse effects of the medications in the list through an asynchronous call]]></annotation>
<request type='Demo.Messages.DrugInteractionRequest' >
<assign property="callrequest.RxCodes" value="context.ScannedRxCodesList" action="set" />
</request>
<response type='Demo.Messages.DrugInteractionResponse' >
<assign property="context.InteractionInfo" value="callresponse" action="set" />
</response>
</call>
<sync name='Sync responses' calls='Call interaction database' type='all' xpos='335' ypos='900' >
<annotation><![CDATA[Wait for interaction database response]]></annotation>
</sync>
</true>
</if>
<call name='Send response email' target='Response Email' async='1' xpos='200' ypos='1100' >
<request type='Demo.Messages.ResponseEmailRequest' >
<assign property="callrequest.ToEMail" value="request.SenderEMail" action="set" />
<assign property="callrequest.Subject" value="&quot;Re: &quot;_request.OriginalSubject" action="set" />
<assign property="callrequest.OriginalDate" value="request.OriginalDate" action="set" />
<assign property="callrequest.OriginalText" value="request.OriginalText" action="set" />
<assign property="callrequest.Message" value="context.ResponseMessage" action="set" />
<assign property="callrequest.RequestStatus" value="context.RequestStatus" action="set" />
<assign property="callrequest.InteractionInfo" value="context.InteractionInfo" action="set" />
</request>
<response type='Ens.Response' />
</call>
</sequence>
</process>
}

Storage Default
{
<Type>%Storage.Persistent</Type>
}

}

