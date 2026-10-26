pipeline {
    agent any
    parameters {
        string(
            name: 'LORE_CLI_PATH',
            defaultValue: 'C:\\Tools\\Lore\\lore.exe',
            description: 'Path to lore.exe accessible by the Jenkins service account.'
        )
        string(
            name: 'LORE_SYNC_PATH',
            defaultValue: 'D:\\SAMPLE\\hoge',
            description: 'Absolute path to the existing Lore working tree to synchronize.'
        )
    }

    // Replace placeholders through Jenkins credentials or runtime environment injection before production use.
    environment {
        LORE_CLIENT_ID = 'replace-with-service-account-client-id'
        LORE_CLIENT_SECRET = 'replace-with-service-account-client-secret'
        LORE_AUTH_URL = 'https://auth.example.com:8081'
        LORE_REMOTE_URL = 'lore://lore.example.com:41337'
    }

    stages {
        stage('Login and synchronize Lore working tree') {
            steps {
                withEnv([
                        "LORE_CLI=${params.LORE_CLI_PATH}",
                        "LORE_SYNC_PATH=${params.LORE_SYNC_PATH}"
                ]) {
                        powershell '''
                            $ErrorActionPreference = 'Stop'

                            foreach ($requiredVariable in @(
                                'LORE_CLIENT_ID',
                                'LORE_AUTH_URL',
                                'LORE_REMOTE_URL',
                                'LORE_CLIENT_SECRET'
                            )) {
                                if ([string]::IsNullOrWhiteSpace([Environment]::GetEnvironmentVariable($requiredVariable))) {
                                    throw "The Jenkins environment variable $requiredVariable is not configured."
                                }
                            }

                            if (-not (Test-Path -LiteralPath $env:LORE_CLI)) {
                                throw "Lore CLI was not found at $env:LORE_CLI."
                            }
                            if (-not [System.IO.Path]::IsPathRooted($env:LORE_SYNC_PATH)) {
                                throw "LORE_SYNC_PATH must be an absolute path: $env:LORE_SYNC_PATH"
                            }
                            if (-not (Test-Path -LiteralPath $env:LORE_SYNC_PATH -PathType Container)) {
                                throw "Lore working tree was not found: $env:LORE_SYNC_PATH"
                            }
                            if (-not (Test-Path -LiteralPath (Join-Path $env:LORE_SYNC_PATH '.lore') -PathType Container)) {
                                throw "Lore working tree metadata was not found: $env:LORE_SYNC_PATH"
                            }

                            $tokenStoreRoot = Join-Path `
                                ([System.IO.Path]::GetTempPath()) `
                                "lore-jenkins-$env:BUILD_TAG"

                            $env:LORE_AUTH_PATH = Join-Path $tokenStoreRoot 'auth'
                            $env:LORE_GLOBAL_PATH = Join-Path $tokenStoreRoot 'global'

                            try {
                                & $env:LORE_CLI auth login `
                                    --token-type service-account `
                                    --token "${env:LORE_CLIENT_ID}:$env:LORE_CLIENT_SECRET" `
                                    --auth-url $env:LORE_AUTH_URL `
                                    $env:LORE_REMOTE_URL

                                if ($LASTEXITCODE -ne 0) {
                                    throw "Lore service-account login failed with exit code $LASTEXITCODE."
                                }

                                Push-Location -LiteralPath $env:LORE_SYNC_PATH
                                try {
                                    # ここの処理を変更すればいい。
                                    & $env:LORE_CLI sync --no-pager
                                    if ($LASTEXITCODE -ne 0) {
                                        throw "Lore sync failed with exit code $LASTEXITCODE."
                                    }
                                }
                                finally {
                                    Pop-Location
                                }


                                Write-Host "Lore synchronization completed successfully: $env:LORE_SYNC_PATH"
                            }
                            finally {
                                if (Test-Path -LiteralPath $tokenStoreRoot) {
                                    Remove-Item -LiteralPath $tokenStoreRoot -Recurse -Force
                                }
                            }
                        '''
                }
            }
        }
    }
}
