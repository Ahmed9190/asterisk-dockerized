# Contributing to Asterisk WebRTC Server

Thank you for considering contributing to this project!

## How to Contribute

### Reporting Bugs

1. Check existing issues first
2. Create a new issue with:
   - Clear description
   - Steps to reproduce
   - Expected vs actual behavior
   - Environment details (OS, Docker version)
   - Relevant logs

### Suggesting Enhancements

1. Open an issue describing:
   - Use case
   - Proposed solution
   - Alternative approaches considered

### Pull Requests

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Make your changes
4. Test thoroughly
5. Commit with clear messages
6. Push and create PR

### Code Style

- Follow existing patterns
- Comment complex logic
- Keep configurations readable
- Test before committing

### Testing Checklist

- [ ] Services start successfully
- [ ] PJSIP endpoints register
- [ ] Calls work (audio/video)
- [ ] TURN/STUN functional
- [ ] No errors in logs
- [ ] Documentation updated

## Development Setup

```
# Clone your fork
git clone https://github.com/YOUR_USERNAME/asterisk-webrtc-server.git
cd asterisk-webrtc-server

# Create feature branch
git checkout -b feature/my-feature

# Make changes and test
docker compose up --build

# Commit
git add .
git commit -m "feat: add feature description"

# Push
git push origin feature/my-feature
```

## Questions?

Open an issue or start a discussion!
