Class Demo.Messages.DrugInteractionResponse Extends Ens.Response
{

Property Disclaimer As %String(MAXLEN = "");

/// Simplified parsing
Property Interactions As list Of DrugInteraction;

/// Full JSON
Property FullResponse As %String(MAXLEN = "");

Storage Default
{
<Data name="DrugInteractionResponseDefaultData">
<Subscript>"DrugInteractionResponse"</Subscript>
<Value name="1">
<Value>Interactions</Value>
</Value>
<Value name="2">
<Value>FullResponse</Value>
</Value>
<Value name="3">
<Value>Disclaimer</Value>
</Value>
</Data>
<DefaultData>DrugInteractionResponseDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}

