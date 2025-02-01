Describe 'Decode-Jwt' {

    Mock -CommandName ConvertFrom-Base64Url -MockWith {
        switch ($args[0]) {
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9' { return '{"alg":"HS256","typ":"JWT"}' }
            'eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ' { return '{"sub":"1234567890","name":"John Doe","iat":1516239022}' }
            default { throw "Unexpected Base64Url input: $args[0]" }
        }
    }

    It 'should decode a valid JWT into its parts' {
        $jwt = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c'
        $result = Decode-Jwt -JwtToken $jwt

        $result.Header | Should -Be '{"alg":"HS256","typ":"JWT"}'
        $result.Payload | Should -Be '{"sub":"1234567890","name":"John Doe","iat":1516239022}'
        $result.Signature | Should -Be 'SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c'
    }

    It 'should throw an error for a JWT with wrong parts' {
        { Decode-Jwt -JwtToken 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.WrongPart' } | Should -Throw "Invalid JWT: expected 3 parts separated by dots."
    }
}