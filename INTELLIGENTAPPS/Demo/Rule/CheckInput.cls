/// Checks if supplied information is valid and eligible for reimbursement.
Class Demo.Rule.CheckInput Extends Ens.Rule.Definition
{

Parameter RuleAssistClass = "Ens.Rule.GeneralBusinessRuleAssist";

XData RuleDefinition [ XMLNamespace = "http://www.intersystems.com/rule" ]
{
<ruleDefinition alias="" context="" production="">
<ruleSet name="Check completeness" effectiveBegin="" effectiveEnd="">
<rule name="check prescriber" disabled="false">
<when condition="PrescriberInfo.Name=&quot;&quot;">
<assign property="ResponseMessage" value="&quot;Unable to identify prescriber&quot;"></assign>
<return>"Incomplete"</return>
</when>
<when condition="PrescriberInfo.Name=&quot;UNKNOWN&quot;">
<assign property="ResponseMessage" value="&quot;Error analysing receipt. Please check  that the image size is less than 4 MB and it is clearly legible&quot;"></assign>
<return>"Incomplete"</return>
</when>
</rule>
<rule name="check patient" disabled="false">
<when condition="PatientInfo.Name=&quot;&quot;">
<assign property="ResponseMessage" value="&quot;Unable to identify patient&quot;"></assign>
<return>"incomplete"</return>
</when>
</rule>
<rule name="check medications" disabled="false">
<when condition="ScannedRxCodes.Count() &lt; 1">
<assign property="message" value="&quot;Request does not contain any medications&quot;"></assign>
<return>"incomplete"</return>
</when>
</rule>
<return>"Complete"</return>
</ruleSet>
</ruleDefinition>
}

}

