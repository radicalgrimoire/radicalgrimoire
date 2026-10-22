pipeline {
    agent {
        label 'windows'
    }

    parameters {
        string(
            name: 'LORE_CLI_PATH',
            defaultValue: 'C:\\Tools\\Lore\\lore.exe',
            description: 'Path to lore.exe accessible by the Jenkins service account.'
        )
        string(
            name: 'LORE_REPOSITORY',
            defaultValue: 'hoge',
            description: 'Lore repository to clone. The service account must have a grant for this repository.'
        )
    }

    environment {
        LORE_CLIENT_ID = 'jenkins-user'
        LORE_AUTH_URL = 'https://172.20.12.215:8081'
        LORE_REMOTE_URL = 'lore://172.20.12.215:41337'
    }

    stages {
        stage('Login and clone Lore repository') {
            steps {
                withCredentials([
                    string(
                        credentialsId: 'lore-jenkins-user-client-secret',
                        variable: 'LORE_CLIENT_SECRET'
                    )
                ]) {
                    withEnv([
                        "LORE_CLI=${params.LORE_CLI_PATH}",
                        "LORE_REPOSITORY=${params.LORE_REPOSITORY}"
                    ]) {
                        powershell '''
                            $ErrorActionPreference = 'Stop'

                            if ([string]::IsNullOrWhiteSpace($env:LORE_CLIENT_SECRET)) {
                                throw "The Jenkins credential lore-jenkins-user-client-secret is not configured."
                            }
                            if (-not (Test-Path -LiteralPath $env:LORE_CLI)) {
                                throw "Lore CLI was not found at $env:LORE_CLI."
                            }
                            if (-not (Get-ChildItem Cert:\\LocalMachine\\Root |
                                    Where-Object Subject -eq 'CN=172.20.12.215')) {
                                throw "The 172.20.12.215 certificate is not trusted in LocalMachine Root."
                            }

                            $clonePath = Join-Path $env:WORKSPACE $env:LORE_REPOSITORY
                            if (Test-Path -LiteralPath $clonePath) {
                                throw "Clone destination already exists: $clonePath"
                            }

                            $tokenStoreRoot = Join-Path `
                                ([System.IO.Path]::GetTempPath()) `
                                "lore-jenkins-$env:BUILD_TAG"

                            $env:LORE_AUTH_PATH = Join-Path $tokenStoreRoot 'auth'
                            $env:LORE_GLOBAL_PATH = Join-Path $tokenStoreRoot 'global'

                            try {
                                & $env:LORE_CLI auth login `
                                    --token-type service-account `
                                    --token "$env:LORE_CLIENT_ID`:$env:LORE_CLIENT_SECRET" `
                                    --auth-url $env:LORE_AUTH_URL `
                                    $env:LORE_REMOTE_URL

                                if ($LASTEXITCODE -ne 0) {
                                    throw "Lore service-account login failed with exit code $LASTEXITCODE."
                                }

                                & $env:LORE_CLI clone `
                                    "$env:LORE_REMOTE_URL/$env:LORE_REPOSITORY" `
                                    $clonePath `
                                    --no-pager

                                if ($LASTEXITCODE -ne 0) {
                                    throw "Lore clone failed with exit code $LASTEXITCODE."
                                }

                                if (-not (Test-Path -LiteralPath (Join-Path $clonePath '.lore'))) {
                                    throw "Lore clone did not create repository metadata."
                                }

                                Write-Host "Lore clone completed successfully: $clonePath"
                            }
                            finally {
                                Remove-Item -LiteralPath $tokenStoreRoot -Recurse -Force `
                                    -ErrorAction SilentlyContinue
                            }
                        '''
                    }
                }
            }
        }
    }
}
