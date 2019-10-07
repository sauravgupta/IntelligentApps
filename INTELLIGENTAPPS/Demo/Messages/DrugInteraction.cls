/// Simplified model for drug-drug interaction
Class Demo.Messages.DrugInteraction Extends (%SerialObject, %XML.Adaptor)
{

Property SourceName As %String(MAXLEN = 300);

Property SourceDisclaimer As %String(MAXLEN = "");

Property Comment As %String(MAXLEN = "");

Property Description As %String(MAXLEN = "");

Storage Default
{
<Data name="DrugInteractionState">
<Value name="1">
<Value>SourceName</Value>
</Value>
<Value name="2">
<Value>SourceDisclaimer</Value>
</Value>
<Value name="3">
<Value>Comment</Value>
</Value>
<Value name="4">
<Value>Description</Value>
</Value>
</Data>
<State>DrugInteractionState</State>
<StreamLocation>^Demo.Messages.DrugInteractionS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}

