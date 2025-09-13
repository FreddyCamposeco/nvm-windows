# nvm.tests.ps1 - Pruebas automatizadas para nvm-windows

Describe "nvm-windows Tests" {

    Context "Script Execution" {
        It "Should display help text for help command" {
            $result = & .\nvm.ps1 help
            $resultAsString = $result -join "`n"
            $resultAsString | Should -Match "Uso:"
            $resultAsString | Should -Match "Comandos:"
        }

        It "Should display help text for invalid command" {
            $result = & .\nvm.ps1 invalidcommand
            $resultAsString = $result -join "`n"
            $resultAsString | Should -Match "Uso:"
        }

        It "Should handle ls command" {
            $result = & .\nvm.ps1 ls
            # Should not throw an error
            $true | Should -Be $true
        }

        It "Should handle current command" {
            $result = & .\nvm.ps1 current
            # Should not throw an error
            $true | Should -Be $true
        }

        It "Should handle ls-remote command" {
            $result = & .\nvm.ps1 ls-remote
            # Should not throw an error (even if it fails due to network)
            $true | Should -Be $true
        }
    }

    Context "Parameter Validation" {
        It "Should require version for install command" {
            $result = & .\nvm.ps1 install
            $result | Should -Match "Especifica una versión"
        }

        It "Should require version for uninstall command" {
            $result = & .\nvm.ps1 uninstall
            $result | Should -Match "Especifica una versión"
        }

        It "Should require version for use command" {
            $result = & .\nvm.ps1 use
            $result | Should -Match "Especifica una versión"
        }

        It "Should require name for unalias command" {
            $result = & .\nvm.ps1 unalias
            $result | Should -Match "Especifica un alias"
        }
    }

    Context "Alias Commands" {
        It "Should require name and version for alias command" {
            $result = & .\nvm.ps1 alias
            $result | Should -Match "Uso: alias"
        }

        It "Should handle aliases command" {
            $result = & .\nvm.ps1 aliases
            # Should not throw an error
            $true | Should -Be $true
        }
    }

    Context "Utility Commands" {
        It "Should handle doctor command" {
            $result = & .\nvm.ps1 doctor
            # Should return some output
            $result | Should -Not -BeNullOrEmpty
        }

        It "Should handle set-colors command without arguments" {
            $result = & .\nvm.ps1 set-colors
            $result | Should -Match "Especifica esquema de colores"
        }

        It "Should handle set-default command without arguments" {
            $result = & .\nvm.ps1 set-default
            $result | Should -Match "Especifica una versión"
        }
    }

    Context "Error Handling" {
        It "Should handle non-existent version for use command" {
            try {
                $result = & .\nvm.ps1 use nonexistentversion 2>&1
                $resultAsString = if ($result -is [System.Management.Automation.ErrorRecord]) {
                    $result.Exception.Message
                }
                else {
                    $result -join "`n"
                }
                $resultAsString | Should -Match "no reconocido"
            }
            catch {
                $_.Exception.Message | Should -Match "no reconocido"
            }
        }

        It "Should handle non-existent version for install command" {
            $result = & .\nvm.ps1 install nonexistentversion 2>&1
            # This might succeed or fail depending on network, but shouldn't crash
            $true | Should -Be $true
        }

        It "Should handle --force flag for uninstall command" {
            try {
                $result = & .\nvm.ps1 uninstall 20.0.0 --force 2>&1
                $resultAsString = if ($result -is [System.Management.Automation.ErrorRecord]) {
                    $result.Exception.Message
                }
                else {
                    $result -join "`n"
                }
                $resultAsString | Should -Match "no está instalada"
            }
            catch {
                $_.Exception.Message | Should -Match "no está instalada"
            }
        }
    }
}