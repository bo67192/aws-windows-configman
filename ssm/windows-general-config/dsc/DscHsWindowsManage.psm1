
configuration DscHsWindowsManager {
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Node localhost {
        # # Force domai nusers to be a member of local guests
        Script InstallChoco {
            GetScript = {
                $result = Test-Path C:\ProgramData\chocolatey\choco.exe;
                return @{Result = $result}
            }
            SetScript= {
                Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
            }
            TestScript = {
                Test-Path C:\ProgramData\chocolatey\choco.exe
            }
        }
    }
}