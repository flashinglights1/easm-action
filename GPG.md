# GPG Key Setup Guide for GitHub Workflows

This guide will help you generate GPG keys and configure them as GitHub secrets for the Nuclei scanning workflows.

## Step 1: Generate GPG Key Pair

Open a terminal and run:

```bash
gpg --full-generate-key
```

Follow the prompts:
1. **Key type**: Press `1` (RSA and RSA) or just Enter for default
2. **Key size**: Enter `4096` (recommended for security)
3. **Expiration**: Enter `0` (no expiration) or specify a date
4. **Real name**: Enter your name (e.g., "Security Scanner")
5. **Email**: Enter an email (e.g., "scanner@yourdomain.com")
6. **Comment**: Optional, press Enter to skip
7. **Confirm**: Type `O` (Okay) to confirm
8. **Passphrase**: Enter a strong passphrase (you'll need this)

## Step 2: Get Your GPG Key ID

After generating the key, get your Key ID:

```bash
gpg --list-secret-keys --keyid-format LONG
```

You'll see output like:
```
sec   rsa4096/ABC123DEF4567890 2024-01-01 [SC]
      ABC123DEF4567890ABCDEF1234567890ABCDEF12
uid                 [ultimate] Security Scanner <scanner@yourdomain.com>
```

The **Key ID** is the part after `rsa4096/` (e.g., `ABC123DEF4567890`). This is your `GPG_KEY_ID`.

## Step 3: Export GPG Private Key

Export your private key in ASCII format:

```bash
gpg --armor --export-secret-keys YOUR_KEY_ID > private_key.asc
```

Replace `YOUR_KEY_ID` with the actual key ID from Step 2.

**Example:**
```bash
gpg --armor --export-secret-keys ABC123DEF4567890 > private_key.asc
```

## Step 4: Export GPG Public Key

Export your public key in ASCII format:

```bash
gpg --armor --export YOUR_KEY_ID > public_key.asc
```

**Example:**
```bash
gpg --armor --export ABC123DEF4567890 > public_key.asc
```

## Step 5: Get Key Contents

View the contents of the keys:

```bash
# View private key
cat private_key.asc

# View public key
cat public_key.asc
```

Copy the entire contents including the `-----BEGIN PGP...` and `-----END PGP...` lines.

## Step 6: Add to GitHub Secrets

1. Go to your GitHub repository
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret** for each:

### Add `GPG_KEY_ID`:
- **Name**: `GPG_KEY_ID`
- **Value**: Your key ID (e.g., `ABC123DEF4567890`) - **without spaces or special characters**

### Add `GPG_PRIVATE_KEY`:
- **Name**: `GPG_PRIVATE_KEY`
- **Value**: Paste the **entire contents** of `private_key.asc` (including BEGIN/END lines)

### Add `GPG_PUBLIC_KEY`:
- **Name**: `GPG_PUBLIC_KEY`
- **Value**: Paste the **entire contents** of `public_key.asc` (including BEGIN/END lines)

## Step 7: Encrypt Your Subdomain File

Before using the workflows, encrypt your subdomain file:

```bash
gpg --encrypt --armor --recipient YOUR_KEY_ID subdomains/all-subdomains.txt
```

This will create `subdomains/all-subdomains.txt.gpg` which the workflows expect.

**Example:**
```bash
# Make sure the subdomains directory exists
mkdir -p subdomains

# Encrypt your subdomain file
gpg --encrypt --armor --recipient ABC123DEF4567890 subdomains/all-subdomains.txt
```

## Verification

Test that everything works:

```bash
# Test decryption (should work without passphrase in CI, but may prompt locally)
gpg --batch --yes --quiet --trust-model always --decrypt subdomains/all-subdomains.txt.gpg > test_decrypt.txt

# Verify it matches original
diff subdomains/all-subdomains.txt test_decrypt.txt

# Clean up test file
rm test_decrypt.txt
```

## Security Notes

⚠️ **Important Security Considerations:**

1. **Never commit** `private_key.asc` or `public_key.asc` to your repository
2. **Never commit** unencrypted subdomain files
3. Store the private key securely - if compromised, regenerate keys
4. Consider using a dedicated GPG key for CI/CD (not your personal key)
5. The private key in GitHub secrets is encrypted at rest by GitHub

## Troubleshooting

### If workflows fail with GPG errors:

1. **Verify key ID matches**: Make sure `GPG_KEY_ID` secret matches the actual key ID
2. **Check key format**: Ensure private/public keys include BEGIN/END lines
3. **Test locally**: Try decrypting the file locally with the same key
4. **Trust model**: The workflows use `--trust-model always` to avoid trust issues in CI

### Common Issues:

- **"No secret key"**: Private key not imported correctly in workflow
- **"No public key"**: Public key not imported correctly
- **"Decryption failed"**: Key ID mismatch or wrong key used for encryption

## Quick Reference Commands

```bash
# Generate key
gpg --full-generate-key

# List keys
gpg --list-secret-keys --keyid-format LONG

# Export private key
gpg --armor --export-secret-keys KEY_ID > private_key.asc

# Export public key
gpg --armor --export KEY_ID > public_key.asc

# Encrypt file
gpg --encrypt --armor --recipient KEY_ID filename.txt

# Decrypt file (test)
gpg --batch --yes --quiet --trust-model always --decrypt filename.txt.gpg
```

