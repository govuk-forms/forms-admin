# Troubleshooting Guide: GitHub Authentication & Port Configuration in Ona Cloud Workspaces

## Running & Accessing the Application via Ona Terminal
If you are running the application directly in the Ona browser terminal (and not through a local IDE setup), you cannot access it via `localhost:3000` or `127.0.0.1:3000`. You must configure Rails to bind globally and expose the workspace port securely.

### Step 1: Update the Rails Server Binding
You need to force Puma to listen to traffic coming through Ona's cloud network rather than restricting it internally.
* Open the **`Procfile.dev`** file in your workspace editor.
* Locate the `web:` command line and append `-b 0.0.0.0` to it.
  * **Change from:**  
    `web: bin/rails server -p 3000`
  * **Change to:**  
    `web: bin/rails server -b 0.0.0.0 -p 3000`
* Save the file (`Ctrl + S` or `Cmd + S`).
  
### Step 2: Start the App with the Host Whitelist
Because Ona uses a remote proxy URL, Rails Host Authorization will block the preview request by default.

**Important:** Instead of running the standard `./bin/dev` command in your terminal, run the following boot command to pass the custom environment variable:
  ```bash
  ALLOWED_HOST_PATTERNS=".*\.gitpod\.dev" ./bin/dev
```
  
### Step 3: Expose and Open the Port
To preview the app in your browser, expose the port using the cloud environment panel:
* In the bottom-right panel under Ports & Services, click + Add port.
* Fill in the configuration fields exactly like this:
  - `Name`: Forms Admin (or whatever you prefer)
  - `Port`: 3000
  - `Protocol`: HTTP
  - `Access`: Creator only
* Click Open port.
Once registered, Port 3000 will pop up in that panel list. Simply click the preview link/globe icon next to it to launch your live app!

## Authenticating with a Personal Access Token (PAT)

### Step 1: Generate Your Token on GitHub

Before authenticating in the terminal, you must ensure your Personal Access Token has the correct permissions required by the repository and the CLI.

1. Go to your GitHub account: **Settings ➡️ Developer Settings ➡️ Personal Access Tokens ➡️ Tokens (classic)**.
2. Click **Generate new token (classic)** or update your existing token.
3. **CRITICAL**: You must explicitly check the following scope checkboxes:
    - `repo` (Full control of private repositories)
    - `workflow` (Required if updating actions or configuration files)
    - `read:org` (Mandatory scope for organizational CLI access validation)
4. Set an expiration date, scroll to the bottom, click Generate token, and copy the token string (ghp_...). Keep this secure.

### Step 2: Run the Login Command

In your workspace terminal, execute the interactive authentication process:
```bash
gh auth login
```
### Step 3: Follow the Interactive Prompts
Configure your answers exactly as follows:

- **What account do you want to log into?** Choose GitHub.com
- **What is your preferred protocol for Git operations on this host?** Choose HTTPS
- **Authenticate Git with your GitHub credentials?** Choose Yes (This sets up the Git credential helper so standard git push commands work seamlessly)
- **How would you like to authenticate GitHub CLI?** Choose Paste an authentication token
- **Paste your authentication token:** Right-click or press Ctrl+Shift+V to paste the token you generated in Step 1.

❌ **Common Error:** If you see error validating token: missing required scope 'read:org', go back to Step 1, modify your token settings to enable the read:org scope, click save, and re-run `gh auth login`.

### Step 4: Pushing Your Changes
Once successfully authenticated, Git configuration is updated globally inside the workspace. You can now use standard Git commands to commit and push changes directly from your branch.

### Step 5: Session Security: Logging Out
Because Ona workspaces reside in a shared cloud infrastructure, it is an essential security practice to log out and invalidate your containerized session tokens when you finish working for the day.

Before stopping your workspace or shutting down your browser tab, run:
```bash
gh auth logout
```
