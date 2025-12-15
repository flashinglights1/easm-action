# Custom Nuclei Templates

This directory contains custom Nuclei templates for your organization-specific vulnerability scanning.

## 📁 Folder Structure

```
nuclei-templates/
├── README.md                    # This file
├── custom/                      # Your custom templates
│   ├── info-disclosure/         # Information disclosure checks
│   ├── vulnerabilities/         # Custom vulnerability checks
│   ├── exposed-panels/          # Custom panel detection
│   └── misconfigurations/       # Custom misconfig checks
└── examples/                    # Example templates
```

## 🎯 Usage

### Enable Custom Scan Profile

When running workflows, select the **`custom`** scan profile:

```yaml
# Via workflow dispatch
scan_profile: custom

# Via command line
gh workflow run nuclei-mass-scan.yml -f scan_profile=custom
```

### Scan Parameters (Custom Profile)

```yaml
Templates: ./nuclei-templates (repository)
Severity: critical,high,medium,low
Rate Limit: 550 requests/second
Timeout: 10 seconds
```

## 📝 Creating Custom Templates

### Basic Template Structure

```yaml
id: custom-vulnerability-name

info:
  name: Custom Vulnerability Check
  author: Your Name
  severity: high
  description: Description of what this template checks
  tags: custom,your-tag

requests:
  - method: GET
    path:
      - "{{BaseURL}}/path/to/check"
    
    matchers:
      - type: word
        words:
          - "vulnerable string"
        part: body
```

### Example: Custom Admin Panel Detection

Create `custom/exposed-panels/custom-admin-panel.yaml`:

```yaml
id: custom-admin-panel

info:
  name: Custom Admin Panel Detection
  author: Security Team
  severity: info
  description: Detects custom admin panel for your application
  tags: custom,panel,admin

requests:
  - method: GET
    path:
      - "{{BaseURL}}/custom-admin"
      - "{{BaseURL}}/admin-custom"
      - "{{BaseURL}}/myapp-admin"
    
    matchers-condition: or
    matchers:
      - type: word
        words:
          - "Custom Admin Panel"
          - "MyApp Administration"
        part: body
      
      - type: status
        status:
          - 200
```

### Example: Custom API Key Exposure

Create `custom/info-disclosure/api-key-leak.yaml`:

```yaml
id: custom-api-key-exposure

info:
  name: Custom API Key Exposure
  author: Security Team
  severity: critical
  description: Detects exposed API keys in your application
  tags: custom,api-key,exposure

requests:
  - method: GET
    path:
      - "{{BaseURL}}/config.js"
      - "{{BaseURL}}/app-config.json"
      - "{{BaseURL}}/.env"
    
    matchers:
      - type: regex
        regex:
          - 'api[_-]?key["\s:=]+[a-zA-Z0-9]{32,}'
          - 'secret[_-]?key["\s:=]+[a-zA-Z0-9]{32,}'
        part: body
```

## 🔧 Template Best Practices

### 1. Use Descriptive IDs
```yaml
# Good
id: myorg-custom-xxe-check

# Bad
id: test1
```

### 2. Add Proper Metadata
```yaml
info:
  name: Clear, descriptive name
  author: Your Team Name
  severity: critical|high|medium|low|info
  description: Detailed description
  reference:
    - https://link-to-documentation
  tags: custom,category,specific-tech
```

### 3. Use Multiple Matchers
```yaml
matchers-condition: and  # Both must match
matchers:
  - type: status
    status:
      - 200
  
  - type: word
    words:
      - "vulnerable"
```

### 4. Extract Useful Data
```yaml
extractors:
  - type: regex
    name: api_key
    regex:
      - 'api_key=([a-zA-Z0-9]+)'
    group: 1
```

## 📚 Template Categories

### 1. Information Disclosure
Templates that detect sensitive information exposure:
- Configuration files
- API keys
- Database credentials
- Internal paths

### 2. Vulnerabilities
Custom vulnerability checks specific to your tech stack:
- Custom CVEs
- Framework-specific issues
- Application logic flaws

### 3. Exposed Panels
Detection of administrative interfaces:
- Custom admin panels
- Internal tools
- Debug interfaces

### 4. Misconfigurations
Configuration issues:
- Security headers
- CORS misconfig
- Authentication bypass

## 🧪 Testing Templates Locally

```bash
# Test single template
nuclei -t nuclei-templates/custom/your-template.yaml -u https://example.com

# Test all custom templates
nuclei -t nuclei-templates/custom/ -l subdomains.txt

# Validate template syntax
nuclei -t nuclei-templates/custom/your-template.yaml -validate

# Debug mode
nuclei -t nuclei-templates/custom/your-template.yaml -u https://example.com -debug
```

## 📖 Official Documentation

- [Nuclei Template Guide](https://docs.projectdiscovery.io/templates/introduction)
- [Template Examples](https://github.com/projectdiscovery/nuclei-templates)
- [Matcher Types](https://docs.projectdiscovery.io/templates/reference/matchers)
- [Extractor Types](https://docs.projectdiscovery.io/templates/reference/extractors)

## ⚠️ Important Notes

1. **Test Before Production**: Always test templates on safe targets first
2. **Avoid False Positives**: Use specific matchers to reduce noise
3. **Performance**: Keep rate limits reasonable to avoid overwhelming targets
4. **Versioning**: Commit templates to git for version control
5. **Documentation**: Document each template's purpose and expected findings

## 🚀 Quick Start

### 1. Create Your First Template

```bash
# Create folder structure
mkdir -p nuclei-templates/custom/vulnerabilities

# Create template file
cat > nuclei-templates/custom/vulnerabilities/my-first-check.yaml << 'EOF'
id: my-first-custom-check

info:
  name: My First Custom Check
  author: Security Team
  severity: medium
  description: Example custom vulnerability check

requests:
  - method: GET
    path:
      - "{{BaseURL}}/test-endpoint"
    
    matchers:
      - type: word
        words:
          - "test-response"
EOF
```

### 2. Test Locally

```bash
nuclei -t nuclei-templates/custom/vulnerabilities/my-first-check.yaml -u https://testphp.vulnweb.com
```

### 3. Run in Workflow

```bash
# Commit templates
git add nuclei-templates/
git commit -m "Add custom templates"
git push

# Run workflow with custom profile
gh workflow run nuclei-mass-scan.yml \
  -f scan_profile=custom \
  -f batch_size=10
```

## 📧 Support

For help with template creation or issues:
1. Check [Nuclei Documentation](https://docs.projectdiscovery.io)
2. Review [Template Examples](https://github.com/projectdiscovery/nuclei-templates)
3. Test with `-debug` flag for troubleshooting

## 🔄 Template Updates

```bash
# Pull latest changes
git pull

# Templates are automatically used when profile=custom
# No need to manually update in workflows
```
