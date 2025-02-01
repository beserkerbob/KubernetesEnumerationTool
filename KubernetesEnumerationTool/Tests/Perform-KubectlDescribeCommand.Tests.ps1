# Pester Tests for Perform-KubectlDescribeCommand Function

Describe 'Perform-KubectlDescribeCommand' {

    BeforeAll {
        # Mock kubectl to return a simulated response for describe commands
        Mock -CommandName kubectl -MockWith {
            return "Name: test-role"
        }
    }

    Context 'When describing roles without token and namespace' {
        It 'should call kubectl describe with type and name only' {
            Perform-KubectlDescribeCommand -Type 'role' -Name 'test-role'
            Assert-MockCalled kubectl -Exactly 1 -Scope It

            # Validate last command passed to Mock
            $mockCommand = (Get-MockCall -CommandName kubectl -First 1).Parameters.Raw
            $mockCommand | Should -Be @('describe', 'role', 'test-role')
        }

        It 'should output role description' {
            $description = Perform-KubectlDescribeCommand -Type 'role' -Name 'test-role'
            $description | Should -Contain "Name: test-role"
        }
    }

    Context 'When describing roles with token and namespace' {
        It 'should call kubectl describe with all parameters' {
            Perform-KubectlDescribeCommand -Type 'role' -Name 'test-role' -namespace 'default' -token 'dummyToken'
            Assert-MockCalled kubectl -Exactly 1 -Scope It

            # Validate last command passed to Mock
            $mockCommand = (Get-MockCall -CommandName kubectl -First 1).Parameters.Raw
            $mockCommand | Should -Be @('describe', 'role', 'test-role', '-n', 'default', '--token', 'dummyToken')
        }

        It 'should output role description with token' {
            $description = Perform-KubectlDescribeCommand -Type 'role' -Name 'test-role' -namespace 'default' -token 'dummyToken'
            $description | Should -Contain "Name: test-role"
        }
    }
}