pipeline {
    agent any

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
        string(
            name: 'LORE_CLONE_PATH',
            defaultValue: 'D:\\SAMPLE',
            description: 'Optional absolute destination path. Leave empty to clone into the Jenkins workspace.'
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
        stage('Login and clone Lore repository') {
            steps {
                withEnv([
                        "LORE_CLI=${params.LORE_CLI_PATH}",
                        "LORE_REPOSITORY=${params.LORE_REPOSITORY}",
                        "LORE_CLONE_PATH=${params.LORE_CLONE_PATH}"
                ]) {
                        powershell '''
                            $ErrorActionPreference = 'Stop'

                            foreach ($requiredVariable in @(
                                'LORE_CLIENT_ID',
                                'LORE_CLIENT_SECRET',
                                'LORE_AUTH_URL',
                                'LORE_REMOTE_URL'
                            )) {
                                if ([string]::IsNullOrWhiteSpace([Environment]::GetEnvironmentVariable($requiredVariable))) {
                                    throw "The Jenkins environment variable $requiredVariable is not configured."
                                }
                            }
                            if (-not (Test-Path -LiteralPath $env:LORE_CLI)) {
                                throw "Lore CLI was not found at $env:LORE_CLI."
                            }
                            $clonePath = if ([string]::IsNullOrWhiteSpace($env:LORE_CLONE_PATH)) {
                                Join-Path $env:WORKSPACE $env:LORE_REPOSITORY
                            }
                            else {
                                $env:LORE_CLONE_PATH
                            }

                            if (-not [System.IO.Path]::IsPathRooted($clonePath)) {
                                throw "LORE_CLONE_PATH must be an absolute path: $clonePath"
                            }

                            if (Test-Path -LiteralPath $clonePath) {
                                throw "Clone destination already exists: $clonePath"
                            }

                            $cloneParent = Split-Path -Parent $clonePath
                            New-Item -ItemType Directory -Force -Path $cloneParent | Out-Null

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
