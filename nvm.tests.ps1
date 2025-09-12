# nvm.tests.ps1 - Pruebas automatizadas para nvm-windows

# Importar el módulo nvm.ps1 (asumiendo que es un script, no módulo)
. .\nvm.ps1

Describe "nvm-windows Tests" {

    Context "Show-Help Function" {
        It "Should display help text" {
            $output = Show-Help
            $output -match "Uso:" | Should Be $true
            $output -match "Comandos:" | Should Be $true
        }
    }

    Context "Get-Version Function" {
        It "Should return no versions when directory does not exist" {
            # Mock Test-Path to return false
            Mock Test-Path { $false } -ParameterFilter { $Path -eq "$env:USERPROFILE\.nvm" }

            $output = Get-Version
            $output | Should Be "No hay versiones instaladas."
        }

        It "Should list versions when directory exists" {
            # Mock Test-Path and Get-ChildItem
            Mock Test-Path { $true } -ParameterFilter { $Path -eq "$env:USERPROFILE\.nvm" }
            Mock Get-ChildItem {
                [PSCustomObject]@{ Name = "v18.17.0" }
                [PSCustomObject]@{ Name = "v20.0.0" }
            }

            $output = Get-Version
            $output -match "v18.17.0" | Should Be $true
            $output -match "v20.0.0" | Should Be $true
        }
    }

    Context "New-NvmAlias Function" {
        It "Should create an alias successfully" {
            # Mock Test-Path and Out-File
            Mock Test-Path { $false } -ParameterFilter { $Path -eq "$env:USERPROFILE\.nvm\alias" }
            Mock New-Item { } -ParameterFilter { $ItemType -eq "Directory" }
            Mock Out-File { } -ParameterFilter { $FilePath -eq "$env:USERPROFILE\.nvm\alias\test" }

            $output = New-NvmAlias "test" "v18.17.0"
            $output | Should Be "Alias 'test' creado para v18.17.0"

            Assert-MockCalled Out-File -Exactly 1 -ParameterFilter { $FilePath -eq "$env:USERPROFILE\.nvm\alias\test" -and $InputObject -eq "v18.17.0" }
        }

        It "Should handle existing alias directory" {
            Mock Test-Path { $true } -ParameterFilter { $Path -eq "$env:USERPROFILE\.nvm\alias" }
            Mock Out-File { }

            $output = New-NvmAlias "existing" "v20.0.0"
            $output | Should Be "Alias 'existing' creado para v20.0.0"
        }
    }

    Context "Remove-NvmAlias Function" {
        It "Should remove an existing alias" {
            Mock Test-Path { $true } -ParameterFilter { $Path -eq "$env:USERPROFILE\.nvm\alias\test" }
            Mock Remove-Item { }

            $output = Remove-NvmAlias "test"
            $output | Should Be "Alias 'test' eliminado"

            Assert-MockCalled Remove-Item -Exactly 1 -ParameterFilter { $Path -eq "$env:USERPROFILE\.nvm\alias\test" }
        }

        It "Should handle non-existing alias" {
            Mock Test-Path { $false } -ParameterFilter { $Path -eq "$env:USERPROFILE\.nvm\alias\nonexistent" }

            $output = Remove-NvmAlias "nonexistent"
            $output | Should Be "Alias 'nonexistent' no existe"
        }
    }

    Context "Script Parameter Handling" {
        It "Should call Show-Help for invalid command" {
            $result = & .\nvm.ps1 invalidcommand
            $result -match "Uso:" | Should Be $true
        }

        It "Should handle help command" {
            $result = & .\nvm.ps1 help
            $result -match "Uso:" | Should Be $true
        }
    }
}