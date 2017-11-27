using Base.Test
using CorpusLoaders


eg1 = """
<?xml version="1.0" encoding="iso-8859-1" ?>
<!DOCTYPE corpus SYSTEM "coarse-all-words.dtd">
<corpus lang="en">
<text id="d001">
<sentence id="d001.s001">
A
B
<instance id="d001.s001.t001" lemma="editorial" pos="n">editorial</instance>
``
C
<instance id="d001.s001.t002" lemma="Ill" pos="a">Ill</instance>
<instance id="d001.s001.t003" lemma="Homeless" pos="n">Homeless</instance>
.
D
</sentence>
</text>
</corpus>
""";

eg2 = """
<?xml version="1.0" encoding="iso-8859-1" ?>
<!DOCTYPE corpus SYSTEM "coarse-all-words.dtd">
<corpus lang="en">
<text id="d001">
<sentence id="d001.s001">
A
B
<instance id="d001.s001.t001" lemma="editorial" pos="n">1</instance>
C
D
</sentence>
</text>
<text>
<sentence id="d001.s001">
<instance id="d001.s001.t001" lemma="editorial" pos="n">2</instance>
A1
B2
C2
D3
</sentence>
</text>
</corpus>
""";

@testset "sentence" begin
    r1 = load_challenges_semeval2007t7(IOBuffer(eg1))
    @test length(r1) == 3

    r2 = load_challenges_semeval2007t7(IOBuffer(eg2))
    @test length(r2) == 2
    @test length(first(r2).context) == 5
    @test length(last(r2).context) == 5
    @test first(r2) != last(r2)
end

@testset "windowing" begin
    r1 = lazyload_challenges_semeval2007t7(IOBuffer(eg1), 10, x->!all(isalnum, x)) |> collect


    @test length(r1) == 3
    @test r1[1].context ==["A","B","C", "Ill","Homeless","D"]
    @test r1[1].word == "editorial"


   r2 = lazyload_challenges_semeval2007t7(IOBuffer(eg2), 10) |> collect


    @test r2[1].context ==["A","B","C","D"]
    @test r2[2].context ==["A1","B2","C2","D3"]

end