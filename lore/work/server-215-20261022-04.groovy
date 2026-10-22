pipeline {
    agent {
        label 'windows'
    }

    environment {
        LORE_CLIENT_ID = 'jenkins-user'
        LORE_AUTH_URL = 'https://172.20.12.215:8081'
        LORE_REMOTE_URL = 'lore://172.20.12.215:41337'
        LORE_REPOSITORY = 'hoge'
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
                    powershell '''
                        $ErrorActionPreference = 'Stop'

                        $loreCommand = Get-Command lore.exe -ErrorAction Stop
                        $lore = $loreCommand.Source

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
                            & $lore auth login `
                                --token-type service-account `
                                --token "$env:LORE_CLIENT_ID`:$env:LORE_CLIENT_SECRET" `
                                --auth-url $env:LORE_AUTH_URL `
                                $env:LORE_REMOTE_URL

                            if ($LASTEXITCODE -ne 0) {
                                throw "Lore service-account login failed with exit code $LASTEXITCODE."
                            }

                            & $lore clone `
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
