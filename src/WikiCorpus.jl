struct WikiCorpus end

MultiResolutionIterators.levelname_map(::WikiCorpus) = [
    :doc=>1,
    :section=>2,
    :para=>3, :line=>3,
    :sent=>4,
    :word=>5, :token=>5,
    :char=>6]

"""
    push_nonempty!(xss, xs)

Helper method for pushing iterables to iterables of iterables.
Does a push! only if the second has some content.
"""
function push_nonempty!(xss, xs)
    if length(xs)>0
        push!(xss,xs)
    end
nothing
end

function load(::WikiCorpus, path=datadep"English WikiCorpus v1.0")

    UltimateType = Document{@NestedVector(InternedString, 4), InternedString}

    Channel(ctype=UltimateType, csize=4) do docs
        for file in readdir(glob"*Text*", path)
            open(file, enc"latin1") do fh
                local cur_doc_title
                cur_doc_content=@NestedVector(InternedString, 4)() # content is for a given section
                no_cur_doc = true
                while(!eof(fh))
                    cur_section_content=@NestedVector(InternedString, 3)()
                    section_text = strip(readuntil(fh, "\n\n"))
                    for line in split(section_text, "\n")
                        #@show line
                        # Line is sometimes paragraph, sometimes list entry. For now we are not capturing that detail
                        if length(line)==0 || line=="ENDOFARTICLE." || line=="</doc>"
                        #    println("*")
                            continue
                        end

                        # deal with maybe this starts a new doc
                        doc_title_match = match(r"<doc id=.* title=\"(.*)\" nonfiltered.*>", line,1)
                        if doc_title_match != nothing
                            # Output current doc
                            if !no_cur_doc
                                push_nonempty!(cur_doc_content, cur_section_content)
                                put!(docs, Document(cur_doc_title, cur_doc_content))
                            end

                            # Start a new Doc
                            # this means splitting a section's content
                            cur_doc_title = InternedString(first(doc_title_match.captures))
                            cur_content = @NestedVector(InternedString, 4)()
                            cur_section_content=@NestedVector(InternedString, 3)()
                            no_cur_doc=false
                            continue # Nothing more to do with this line
                        end

                        # an actual paragraph (or whatever)
                        paragraph_of_sents = split.(split(line, Sentences), Words)
                        push_nonempty!(cur_section_content, paragraph_of_sents)
                    end # foreach line in section
                    push_nonempty!(cur_doc_content, cur_section_content)
                end # while(!eof)
                put!(docs, Document(cur_doc_title, cur_content))
            end # open
        end # for each file
    end # Channel
end
