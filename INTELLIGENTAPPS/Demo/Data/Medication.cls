/// 
Class Demo.Data.Medication Extends %Persistent [ Final ]
{

Property RxCode As %Library.Integer;

Property Description As %Library.String(MAXLEN = 500);

Property Product As %Library.String(MAXLEN = 300);

Property RxCUI As %Library.Integer;

Index DDLBEIndex [ Extent, Type = bitmap ];

Index RxCode On (RxCode);

Index iFind On (Product) As %iFind.Index.Basic;

Parameter USEEXTENTSET = 1;

Storage Default
{
<Data name="MedicationDefaultData">
<Value name="1">
<Value>RxCode</Value>
</Value>
<Value name="2">
<Value>Description</Value>
</Value>
<Value name="3">
<Value>Product</Value>
</Value>
<Value name="5">
<Value>RxCUI</Value>
</Value>
</Data>
<DataLocation>^DSMH.Odca.1</DataLocation>
<DefaultData>MedicationDefaultData</DefaultData>
<ExtentLocation>^DSMH.Odca</ExtentLocation>
<IdFunction>sequence</IdFunction>
<IdLocation>^DSMH.Odca.1</IdLocation>
<Index name="DDLBEIndex">
<Location>^DSMH.Odca.2</Location>
</Index>
<Index name="IDKEY">
<Location>^DSMH.Odca.1</Location>
</Index>
<Index name="RxCode">
<Location>^DSMH.Odca.4</Location>
</Index>
<Index name="iFind">
<Location>^DSMH.Odca.3</Location>
</Index>
<IndexLocation>^DSMH.Odca.I</IndexLocation>
<StreamLocation>^DSMH.Odca.S</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}

