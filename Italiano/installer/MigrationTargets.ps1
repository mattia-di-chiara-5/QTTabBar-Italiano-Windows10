#requires -version 5.1
# Exact, released product/MSI/DLL triples. Never infer a rollback from a version label.
function Get-PreviousQtRelease([string]$ProductCode) {
    switch ($ProductCode) {
        '{540B7E57-F7A0-4AA5-A362-736892574234}' { return [pscustomobject]@{
            Version='0.6.0'; ProductCode=$ProductCode
            MsiHash='7773086005FF2675E4994C895C7A828EC20966D83A0268C9AD61EE11DC837767'
            DllHash='C71BA7B8AD5679B5E035820E8E995409760EB6B0DCD34C50A11699BD20F4C553'
        } }
        '{F70E079A-2E71-4B23-B8F2-854D700B7DAF}' { return [pscustomobject]@{
            Version='0.6.1'; ProductCode=$ProductCode
            MsiHash='CF38FDD2A5C9D9C302FB04796E475848455C9EECC3EBA5FE93A6BF7CE6B7CA70'
            DllHash='DE04994CF471EBFD2577FFB3D29FE845EFE5F8EE87F55B5457C053BDA1D163D8'
        } }
        '{3EB8D8B3-A96E-49B0-824A-707E6CF60273}' { return [pscustomobject]@{
            Version='0.7.0'; ProductCode=$ProductCode
            MsiHash='10FD805CBA6E1EBD1946D598640022922AA1F8417BD31DCA6B246F44CCBE7ADC'
            DllHash='DEC5BEC92E13DA050C8B088F11E58FC567B984CC3F67472D0310C3E41ACC5D3E'
        } }
        default { throw 'Edizione precedente non riconosciuta: nessuna modifica eseguita.' }
    }
}
