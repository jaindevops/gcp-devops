# 🛡️ Google Cloud Workload Identity Federation for GitHub Actions
[![Security: OIDC](https://img.shields.io/badge/Security-OIDC%20-blue.svg)](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect)
[![GCP: WIF](https://img.shields.io/badge/GCP-Workload%20Identity%20Federation-orange.svg)](https://cloud.google.com/iam/docs/workload-identity-federation)
[![GitHub Action: auth](https://img.shields.io/badge/GitHub%20Action-auth-blue?logo=github)](https://github.com/google-github-actions/auth)

A production-grade implementation of **Zero-Secret** authentication. This document describes how to set up Workload Identity Federation between Google Cloud Platform (GCP) and GitHub Actions. This allows your GitHub Actions workflows to authenticate to GCP and access resources without needing to store long-lived service account keys.

# 📖 How it Works: The "Indirect" OIDC Flow
Unlike traditional authentication, this flow uses a short-lived "ID Badge" (OIDC Token) that expires in minutes.

* Authentication: GitHub issues a signed JWT to the runner.

* Handshake: Google's Security Token Service (STS) verifies the signature using GitHub's Public Keys.

* Mapping: GCP maps GitHub's attributes (claims) like repository and actor to GCP labels.

* Impersonation: If the repository matches our CEL Condition, Google issues a short-lived Access Token for a specific Service Account.

## 🚀 Authentication Flow Diagram

Here is a visual representation of the authentication flow:

```
   +--------------------------+
   |   GitHub Actions         |
   |   Workflow               |
   +--------------------------+
              |
              | 1. The 'google-github-actions/auth' action requests
              |    an OIDC JWT token from GitHub's token provider.
              v
   +--------------------------+
   |   GitHub OIDC Provider   |
   +--------------------------+
              |
              | 2. Issues a signed JWT containing claims about
              |    the repository, commit hash, etc.
              v
   +--------------------------+
   |   GitHub Actions         |
   |   (receives JWT)         |
   +--------------------------+
              |
              | 3. The 'auth' action sends this JWT to the
              |    Google Cloud Security Token Service (STS).
              v
   +---------------------------------------+
   |   Google Cloud STS                    |
   |   (Workload Identity Federation)      |
   +---------------------------------------+
              |
              | 4. STS validates the JWT signature and claims against
              |    the configured Workload Identity Pool and Provider.
              |
              | 5. If valid, STS exchanges the JWT for a
              |    short-lived Google Cloud federated access token.
              v
   +--------------------------+
   |   GitHub Actions         |
   |   (receives token)       |
   +--------------------------+
              |
              | 6. The 'auth' action uses the federated token to
              |    impersonate the specified GCP Service Account.
              v
   +--------------------------+
   |   GCP IAM                |
   +--------------------------+
              |
              | 7. IAM provides short-lived credentials for
              |    the Service Account.
              v
   +--------------------------+
   |   GitHub Actions         |
   |   (gcloud, gsutil, etc.) |
   +--------------------------+
              |
              | 8. Subsequent steps in the workflow use the
              |    Service Account credentials to access
              |    GCP resources.
              v
   +--------------------------+
   |   GCP Resources          |
   | (e.g., Storage, GKE)     |
   +--------------------------+

```

## Prerequisites

*   A Google Cloud Platform project.
*   A GitHub repository with GitHub Actions enabled.
*   The `gcloud` command-line tool installed and configured.

## Steps

1.  **Enable the required APIs:**

    ```bash
    gcloud services enable iam.googleapis.com \
        iamcredentials.googleapis.com \
        sts.googleapis.com
    ```

2.  **Create a Workload Identity Pool and Provider:**

    Create a Workload Identity Pool:
    ```bash
    gcloud iam workload-identity-pools create "github-pool" \
      --project="<YOUR_GCP_PROJECT_ID>" \
      --location="global" \
      --display-name="GitHub Pool"
    ```

    Create the OIDC Provider:
    ```bash
    gcloud iam workload-identity-pools providers create-oidc "github" \
      --project="<YOUR_GCP_PROJECT_ID>" \
      --location="global" \
      --workload-identity-pool="github-pool" \
      --display-name="GitHub Provider" \
      --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository" \
      --attribute-condition="assertion.repository == 'jaindevops/gcp-devops'" \
      --issuer-uri="https://token.actions.githubusercontent.com"
    ```

3.  **Create a GCP Service Account:**

    Create a service account that your GitHub Actions workflow will impersonate:
    ```bash
    gcloud iam service-accounts create "github-actions" \
      --project="<YOUR_GCP_PROJECT_ID>" \
      --display-name="GitHub Actions Service Account"
    ```

4.  **Grant the Service Account the necessary roles for infrastructure management:**

    Grant the service account the roles it needs to access GCP resources:
    ```bash
    gcloud projects add-iam-policy-binding "<YOUR_GCP_PROJECT_ID>" \
      --member="serviceAccount:github-actions-sa@<YOUR_GCP_PROJECT_ID>.iam.gserviceaccount.com" \
      --role="roles/iam.infrastructureAdmin"
    ```

5.  **Allow the Workload Identity Provider to impersonate the Service Account:**

    This is the crucial step that connects the GitHub Actions identity to the GCP service account.
    ```bash
    gcloud iam service-accounts add-iam-policy-binding "github-actions@<YOUR_GCP_PROJECT_ID>.iam.gserviceaccount.com" \
      --project="<YOUR_GCP_PROJECT_ID>" \
      --role="roles/iam.workloadIdentityUser" \
      --member="principalSet://iam.googleapis.com/projects/<YOUR_GCP_PROJECT_NUMBER>/locations/global/workloadIdentityPools/github-pool/<SUBJECT>"
    ```

    Replace `<SUBJECT>` with actual subject like **"attribute.repository/jaindevops/gcp-devops"**


6.  **Configure your GitHub Actions workflow:**

    Update your GitHub Actions workflow file (e.g., `.github/workflows/main.yml`) to use the `google-github-actions/auth` action.

    ```yaml
    name: GCP Auth Example

    on:
      push:
        branches:
          - main

    jobs:
      build-and-deploy:
        runs-on: ubuntu-latest
        permissions:
          contents: 'read'
          id-token: 'write'

        steps:
        - name: 'Checkout'
          uses: 'actions/checkout@v3'

        - name: 'Authenticate to GCP'
          uses: 'google-github-actions/auth@v1'
          with:
            workload_identity_provider: 'projects/<YOUR_GCP_PROJECT_NUMBER>/locations/global/workloadIdentityPools/github-pool/providers/github-provider'
            service_account: 'github-actions-sa@<YOUR_GCP_PROJECT_ID>.iam.gserviceaccount.com'

        - name: 'Set up Cloud SDK'
          uses: 'google-github-actions/setup-gcloud@v1'

        - name: 'list buckets'
          run: 'gsutil ls'
    ```

    Replace `<YOUR_GCP_PROJECT_ID>` and `<YOUR_GCP_PROJECT_NUMBER>` with your actual GCP project ID and project number.


## 🔍 Troubleshooting & Verification
```yaml
- name: "Print OIDC Claims"
	run: |
		# Request a token and decode the payload (requires jq)
		OIDC_TOKEN=$(curl -s -H "Authorization: Bearer $ACTIONS_ID_TOKEN_REQUEST_TOKEN" \
			"$ACTIONS_ID_TOKEN_REQUEST_URL&aud=google-cloud-verification" | jq -r '.value')
		
		# Extract the middle part (the payload) and decode it
		echo "### START OF CLAIMS ###"
		echo "$TOKEN" | cut -d'.' -f2 | base64 --decode | jq .
		echo "### END OF CLAIMS ###"
```

**Note:** The JWT consist of three separate parts Header, Payload and Signatire and we are printing here only Payload for troubleshooting.
* Header: Specifies the algorithm used (usually RS256).
* Payload: Contains the claims you saw (the JSON with actor, repository, etc.).
* Signature: A mathematical hash created by combining the Header + Payload and "signing" them with GitHub’s Private Key.

# How Google Verifies the Signature
When you run your GitHub Action, the google-github-actions/auth step sends this entire three-part token to Google. Google doesn't just trust the repository claim; it performs a Signature Verification:

Fetch Public Keys: Google Cloud goes to GitHub’s "Discovery URL" (https://token.actions.githubusercontent.com/.well-known/jwks) and downloads GitHub's Public Keys.

The Math Check: Google uses the Public Key to "unlock" the signature. If the mathematical result matches the Payload exactly, Google knows:

Authenticity: This token definitely came from GitHub (because only GitHub has the private key to make that signature).

Integrity: The data (claims) has not been changed (if a hacker changed the repo name, the signature would break).

## Nomenclature

This guide uses the term "Workload Identity Federation," which is the official Google Cloud name for the service that allows you to grant external identities roles in your GCP project. GitHub's documentation often refers to this same concept as "OpenID Connect (OIDC) integration." Both terms describe the same underlying mechanism for secure, keyless authentication.

## Conclusion

By following these steps, you have successfully configured Workload Identity Federation between GCP and GitHub Actions. Your workflows can now securely authenticate to GCP without the need for long-lived credentials.

## References

For more detailed information, please refer to the official GitHub documentation:

*   [Configuring OpenID Connect in Google Cloud Platform](https://docs.github.com/en/actions/how-tos/secure-your-work/security-harden-deployments/oidc-in-google-cloud-platform)
* [Workload Identity Federation through a Service Account](https://github.com/google-github-actions/auth?tab=readme-ov-file#indirect-wif)
* https://docs.github.com/en/actions/concepts/security/openid-connect





