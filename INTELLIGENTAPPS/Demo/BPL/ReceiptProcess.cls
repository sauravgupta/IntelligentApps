/// 
Class Demo.BPL.ReceiptProcess Extends Ens.BusinessProcessBPL [ DependsOn = Demo.BPL.ProcessContext ]
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
<property name='ScannedRxCodes' type='%String' collection='list' instantiate='0' >
<parameters>
<parameter name='MAXLEN'  value='50' />
</parameters>
</property>
<property name='RequestStatus' type='%String' initialexpression='"incomplete"' instantiate='0' >
<parameters>
<parameter name='MAXLEN'  value='50' />
</parameters>
</property>
<property name='ResponseMessage' type='%String' instantiate='0' >
<parameters>
<parameter name='MAXLEN'  value='2500' />
</parameters>
</property>
<property name='AnomalyModelDistance' type='%Numeric' instantiate='0' />
<property name='InteractionInfo' type='Demo.Messages.DrugInteractionResponse' instantiate='0' />
</context>
<sequence xend='200' yend='1400' >
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
<assign property="context.ScannedRxCodes" value="##class(Demo.Util.Functions).ExtractRxCodes(callresponse.Medications)" action="set" />
<assign property="context.PrescriberInfo.PrescriberID" value="callresponse.PrescriberID" action="set" />
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
<if name='Complete?' condition='context.RequestStatus="Complete"' xpos='200' ypos='650' xend='200' yend='1200' >
<true>
<call name='Call interaction database' target='Drug Interactions' async='1' xpos='335' ypos='800' >
<annotation><![CDATA[Checks for potential adverse effects of the medications in the list through an asynchronous call]]></annotation>
<request type='Demo.Messages.DrugInteractionRequest' >
<assign property="callrequest.RxCodes" value="context.ScannedRxCodes" action="set" />
</request>
<response type='Demo.Messages.DrugInteractionResponse' >
<assign property="context.InteractionInfo" value="callresponse" action="set" />
</response>
</call>
<call name='Anomaly Detection' target='invoke PMML generic' async='0' xpos='335' ypos='900' >
<annotation><![CDATA[Invoke a predictive model that expresses how "anomalous" the supplied reimbursement request is.]]></annotation>
<request type='PMML.Interop.GenericRequest' >
<assign property="callrequest.ModelData" value="context.PatientInfo.MedicationHistory" action="set" />
</request>
<response type='PMML.Interop.GenericResponse' >
<assign property="context.AnomalyModelDistance" value="callresponse.ModelOutput.GetAt(&quot;score&quot;)" action="set" />
</response>
</call>
<rule name='Check anomaly output' rule='Demo.Rule.ResolveAnomaly'  resultLocation='context.RequestStatus' ruleContext='context' xpos='335' ypos='1000' >
<annotation><![CDATA[Reviews the output from the Anomaly Detection model and decides whether the claim is eligible for approval or needs manual review.]]></annotation>
</rule>
<sync name='Sync responses' calls='Call interaction database' type='all' xpos='335' ypos='1100' >
<annotation><![CDATA[Wait for interaction database response]]></annotation>
</sync>
</true>
</if>
<call name='Send response email' target='Response Email' async='1' xpos='200' ypos='1300' >
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

