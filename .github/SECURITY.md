# Security Policy

## Supported Versions

| Version | Supported |
| ------- | --------- |
| 1.x.x   | Yes       |
| < 1.0   | No        |

## Reporting a Vulnerability

### Quick Steps

1. **DO NOT** create a public GitHub issue
2. Email: sergiy@noskov.org starting with \[SECURITY\] in the subject line
3. Include:
    - Detailed description
    - Steps to reproduce
    - Rootine version (`rootine --version`)
    - Ubuntu version
    - Error messages (if any)

### Response Timeline

| Priority | Initial Response | Fix Timeline  |
|----------|------------------|---------------|
| Critical | 1 day            | 1 week        |
| High     | 1 week           | 2 weeks       |
| Medium   | 2 weeks          | 1 month       |
| Low      | 1 month          | 3 months      |

## Security Best Practices

1. **Installation**
    - Review scripts before running as root
    - Keep backup files (`*.rootine.bak`)
    - Use official package sources

2. **Usage**
    - Run with appropriate permissions
    - Keep system and Rootine updated
    - Follow least privilege principle
    - Monitor security advisories

## Security Contacts

- Lead Maintainer: sergiy@noskov.org
- Organization: contact@ergiosko.com

## Scope

### Included
- Rootine shell scripts
- Configuration files
- Official releases
- Installation scripts

### Excluded
- Third-party packages
- User configuration errors
- Modified scripts
- External dependencies
