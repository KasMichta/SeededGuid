BeforeAll {
    $here = Split-Path -Parent $PSCommandPath
    $sut = (Split-Path -Leaf $PSCommandPath) -replace '\.Tests\.', '.'
    . "$here\$sut"
}

Describe "'Get-SeededGuid' Tests" {
    Context "Same Guid from same seed" {
        It "should be the same" {
            $seed = 'seed'
            $guid1 = Get-SeededGuid -Seed $seed
            $guid2 = Get-SeededGuid -Seed $seed
            $guid1 | Should -Be $guid2
        }
    }
}
