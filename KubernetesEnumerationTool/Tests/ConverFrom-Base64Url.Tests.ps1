# Pester Tests for ConvertFrom-Base64Url Function

Describe 'ConvertFrom-Base64Url' {

    # Test: Decode a standard Base64Url-encoded string
    It 'should decode a standard Base64Url-encoded string correctly' {
        $base64UrlString = 'SGVsbG8gd29ybGQ'  # "Hello world"
        $expectedOutput = 'Hello world'
        $result = ConvertFrom-Base64Url -Base64Url $base64UrlString
        $result | Should -Be $expectedOutput
    }

    # Test: Decode a Base64Url-encoded string with URL-safe characters
    It 'should decode a Base64Url-encoded string with URL-safe characters correctly' {
        $base64UrlString = 'U29mdHdhcmUtZGV2ZWxvcG1lbnQ='  # "Software-development"
        $expectedOutput = 'Software-development'
        $result = ConvertFrom-Base64Url -Base64Url $base64UrlString
        $result | Should -Be $expectedOutput
    }
        # Test: Decode a Base64Url-encoded string with URL-safe characters
        It 'should decode a Base64Url-encoded string with space characters correctly' {
            $base64UrlString = 'UG93ZXJzaGVsbCBtb2R1bGVzIGFyZSBncmVhdA=='  # "Software-development"
            $expectedOutput = 'Powershell modules are great'
            $result = ConvertFrom-Base64Url -Base64Url $base64UrlString
            $result | Should -Be $expectedOutput
        }
}