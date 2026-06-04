let
func = (TableToTransform as table) as table =>
    let 
        transformation = 
            Table.TransformColumnNames(TableToTransform, each 
                Text.Replace(
                    Text.Replace(
                        Text.Replace(
                            Text.Replace(
                                Text.Replace(
                                    Text.Upper(
                                        Text.Start(
                                            Text.Lower(_),
                                            1
                                        )
                                    )&
                                    Text.Replace(
                                        Text.Replace(
                                            Text.Replace(
                                                Text.Lower(
                                                    Text.End(
                                                        _,
                                                        Text.Length(_)-1
                                                    )
                                                ),
                                                "aa","å"
                                            ),
                                            "oe","ø"
                                        ),
                                        "_sk","SK"
                                    ),
                                    "_id","ID"
                                ),
                                "_"," "
                            ),
                            "Aa","Å"
                            ),
                            "Oe","Ø"
                        ),
                        "Ae","Æ"
                )
            )
    in
  transformation ,
documentation = [
	Documentation.Name = 
    	"Adjust columns according to defined naming conventions",
	Documentation.Description = 
    	"Changes from Upper to Proper, replaces id with ID and replaces _ with spaces. Also replaces ae, oe and aa with æ, ø and å. Creates a reference table"
]
in 
Value.ReplaceType(func,Value.ReplaceMetadata(Value.Type(func),documentation))