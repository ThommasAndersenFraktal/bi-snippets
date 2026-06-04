let
    func = (TableToTransform as table) as table =>
        let
            renameColumn = (name as text) as text =>
                let
                    // sentence case: first char upper, remainder lower
                    sentenceCased =
                        Text.Upper(Text.Start(name, 1)) & Text.Lower(Text.Middle(name, 1)),

                    // suffix tokens before the generic underscore->space step
                    suffixFixed =
                        Text.Replace(
                            Text.Replace(sentenceCased, "_id", "ID"),
                            "_sk", "SK"
                        ),

                    // Norwegian digraphs (lowercase covers mid/end, uppercase covers start)
                    norwegian =
                        List.Accumulate(
                            {
                                {"aa", "å"}, {"oe", "ø"}, {"ae", "æ"},
                                {"Aa", "Å"}, {"Oe", "Ø"}, {"Ae", "Æ"}
                            },
                            suffixFixed,
                            (state, pair) => Text.Replace(state, pair{0}, pair{1})
                        ),

                    spaced = Text.Replace(norwegian, "_", " ")
                in
                    spaced
        in
            Table.TransformColumnNames(TableToTransform, renameColumn),

    documentation = [
        Documentation.Name =
            "Adjust columns according to defined naming conventions",
        Documentation.Description =
            "Sentence-cases column names, maps _id/_sk to ID/SK, replaces remaining underscores with spaces, and converts the digraphs aa/oe/ae to å/ø/æ."
    ]
in
    Value.ReplaceType(func, Value.ReplaceMetadata(Value.Type(func), documentation))
