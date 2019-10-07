/// Reviews the output from the Anomaly Detection model and decides whether the claim is eligible for approval or needs manual review.
Class Demo.Rule.ResolveAnomaly Extends Ens.Rule.Definition
{

Parameter RuleAssistClass = "Ens.Rule.GeneralBusinessRuleAssist";

XData RuleDefinition [ XMLNamespace = "http://www.intersystems.com/rule" ]
{
<ruleDefinition alias="" context="Demo.BPL.ReceiptProcess.Context" production="">
<ruleSet name="Validate anomaly output" effectiveBegin="" effectiveEnd="">
<rule name="check cluster distance" disabled="false">
<when condition="AnomalyModelDistance&lt;1000">
<return>"Approved"</return>
<comment text="The current threshold value is somewhat arbitrary, but as a refinement could be based on average cluster &quot;size&quot;. Cf notes on ML refinement."></comment>
</when>
</rule>
<return>"NeedsReview"</return>
</ruleSet>
</ruleDefinition>
}

}

