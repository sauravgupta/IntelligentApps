Class Demo.Messages.DrugInteractionRequest Extends Ens.Request
{

Property RxCodes As array Of %String;

Storage Default
{
<Data name="RxCodes">
<Attribute>RxCodes</Attribute>
<Structure>subnode</Structure>
<Subscript>"Demo.Messages.DrugInteractionRequest.RxCodes"</Subscript>
</Data>
<Type>%Storage.Persistent</Type>
}

}

