# Asterisk WebRTC Server with Coturn

Production-ready Asterisk 22.5.2 PBX with WebRTC support, Coturn TURN/STUN server, and H.264 video optimization for low-latency intercom applications.

## Features

- ✅ **Asterisk 22.5.2** - Latest stable release with full PJSIP support
- ✅ **WebRTC Ready** - WSS transport with DTLS/SRTP encryption
- ✅ **Coturn TURN/STUN** - Reliable NAT traversal for WebRTC clients
- ✅ **H.264 Video** - Optimized for intercom devices (no transcoding)
- ✅ **Multi-codec Audio** - Opus, ulaw, alaw, G.722, GSM
- ✅ **TLS/DTLS** - Secure signaling and media encryption
- ✅ **Docker Compose** - Easy deployment and management
- ✅ **Health Checks** - Automatic container monitoring
- ✅ **Production Ready** - Optimized multi-stage builds

## Architecture

```
┌─────────────────┐         WSS/HTTPS          ┌──────────────────┐
│  WebRTC Client  │◄─────────────────────────►│  Asterisk 22.5.2 │
│   (Browser)     │                            │    (172.20.0.10) │
└─────────────────┘                            └──────────────────┘
        │                                               │
        │ STUN/TURN                                     │ RTP/SRTP
        ▼                                               ▼
┌─────────────────┐                            ┌──────────────────┐
│ Coturn 4.7      │                            │   SIP Devices    │
│ (172.20.0.20)   │                            │   (Hardware)     │
└─────────────────┘                            └──────────────────┘
```

## Quick Start

### Prerequisites

- Docker Engine 20.10+
- Docker Compose 2.0+
- 4GB RAM minimum
- Ports available: 3478, 5060, 5061, 5349, 8088, 8089, 10000-10200

### 1. Clone Repository

```
git clone https://github.com/YOUR_USERNAME/asterisk-webrtc-server.git
cd asterisk-webrtc-server
```

### 2. Generate TLS Certificates

```
mkdir -p certs
openssl req -x509 -newkey rsa:4096 \
  -keyout certs/asterisk-key.pem \
  -out certs/asterisk-cert.pem \
  -days 365 -nodes \
  -subj "/C=US/ST=State/L=City/O=Organization/CN=asterisk.local"

chmod 644 certs/*.pem
```

### 3. Configure Environment

```
# Copy example environment file
cp .env.example .env

# Edit with your details
nano .env
```

**Update these values in `.env`:**
```
# Your public IP address
PUBLIC_IP=YOUR_PUBLIC_IP_HERE

# Change default passwords!
SIP_PASSWORD=YourStrongPassword123
TURN_PASSWORD=YourTurnPassword456
```

### 4. Start Services

```
# Build and start
docker compose up -d

# Check status
docker compose ps

# View logs
docker compose logs -f
```

### 5. Verify Installation

```
# Check Asterisk is ready
docker compose exec asterisk asterisk -rx "core show version"

# Check PJSIP endpoints
docker compose exec asterisk asterisk -rx "pjsip show endpoints"

# Check Coturn
docker compose logs coturn | grep "listener opened"
```

**Expected:** Asterisk shows version 22.5.2, endpoints 6001-6003 visible, Coturn has 4 listeners active.

## Configuration

### WebRTC Endpoints

Three pre-configured WebRTC endpoints for testing:

| Endpoint | Username | Password | Protocol |
|----------|----------|----------|----------|
| 6001 | 6001 | SecurePass123 | WSS |
| 6002 | 6002 | SecurePass123 | WSS |
| 6003 | 6003 | SecurePass123 | WSS |

**To add more endpoints:** Edit `configs/pjsip.conf`

### TURN Credentials

| Username | Password | Usage |
|----------|----------|-------|
| turnuser | TurnPassword123 | WebRTC clients |
| webrtc | WebRtcTurn456 | Alternative |
| intercom | IntercomTurn789 | Hardware devices |

**Update in:** `coturn/turnserver.conf`

### Test Extensions

| Extension | Purpose |
|-----------|---------|
| 100 | Echo test (hear yourself) |
| 101 | Hello World playback |
| 102 | Music on hold |
| 200 | Conference room |
| 6001-6003 | Call other extensions |

## WebRTC Client Configuration

### JavaScript Example (SIP.js)

```
const config = {
  uri: 'sip:6001@YOUR_PUBLIC_IP',
  transportOptions: {
    server: 'wss://YOUR_PUBLIC_IP:8089/ws'
  },
  authorizationUsername: '6001',
  authorizationPassword: 'SecurePass123',
  sessionDescriptionHandlerFactoryOptions: {
    peerConnectionOptions: {
      rtcConfiguration: {
        iceServers: [
          { urls: 'stun:YOUR_PUBLIC_IP:3478' },
          { 
            urls: 'turn:YOUR_PUBLIC_IP:3478?transport=udp',
            username: 'turnuser',
            credential: 'TurnPassword123'
          }
        ]
      }
    }
  }
};
```

## Testing

### Test STUN/TURN

```
# Test STUN from host
stun YOUR_PUBLIC_IP -p 3478

# Test Coturn authentication
docker compose exec coturn turnutils_uclient \
  -u turnuser -w TurnPassword123 -y 127.0.0.1
```

### Test SIP Registration

Register a SIP client with:
- **Server:** YOUR_PUBLIC_IP
- **Port:** 5060 (UDP/TCP) or 8089 (WSS)
- **Username:** 6001
- **Password:** SecurePass123

### Test Call Flow

1. Register two WebRTC clients (6001 and 6002)
2. From 6001, dial **6002**
3. Answer on 6002
4. Verify two-way audio/video

## File Structure

```
asterisk-webrtc-server/
├── configs/                    # Asterisk configuration files
│   ├── pjsip.conf             # SIP endpoints and transports
│   ├── extensions.conf        # Dialplan
│   ├── rtp.conf               # RTP/media settings
│   └── http.conf              # WebRTC HTTP/WSS
├── coturn/                     # Coturn TURN server config
│   └── turnserver.conf
├── certs/                      # TLS certificates (generated)
│   ├── asterisk-cert.pem
│   └── asterisk-key.pem
├── Dockerfile                  # Asterisk build
├── docker-compose.yml          # Service orchestration
├── .env.example                # Environment template
├── .gitignore
└── README.md
```

## Production Deployment

### Security Hardening

1. **Change all default passwords** in configs
2. **Use Let's Encrypt certificates** for production
3. **Configure firewall rules**
4. **Enable fail2ban** for brute-force protection
5. **Use strong SIP passwords** (16+ characters)

### Resource Limits

Update `docker-compose.yml` with limits:

```
deploy:
  resources:
    limits:
      cpus: '2'
      memory: 2G
    reservations:
      cpus: '0.5'
      memory: 512M
```

### Monitoring

Add monitoring stack (optional):

```
# Prometheus metrics endpoint
curl http://localhost:8088/metrics

# Health checks
docker compose ps
```

## Troubleshooting

### No Audio in Calls

- Check RTP ports are open: `10000-10200/udp`
- Verify STUN/TURN is working
- Check firewall allows UDP traffic

### WebRTC Client Won't Register

- Verify WSS port 8089 is accessible
- Check TLS certificate is valid
- Ensure endpoint is configured in pjsip.conf

### TURN Not Working

- Check Coturn logs: `docker compose logs coturn`
- Verify credentials match in config and client
- Test port 3478 UDP is open

### Common Issues

| Issue | Solution |
|-------|----------|
| "Unable to find object 6001" | PJSIP config error, check syntax |
| "No SIP transport" | PJSIP transports not configured |
| TLS certificate errors | Regenerate certificates |
| Port already in use | Stop conflicting service |

## Performance Optimization

### For High Call Volume (100+ concurrent)

- Increase RTP port range to 10000-30000
- Add more Coturn relay ports
- Use dedicated Redis for TURN sessions
- Enable Asterisk database backend

### For Low Latency (Intercom)

- Use H.264 video codec only (no transcoding)
- Enable `direct_media=yes` for intercom endpoints
- Reduce jitter buffer: `jbenable=no`
- Use Opus for audio (lowest latency)

## Maintenance

### Backup

```
# Backup configurations
tar -czf asterisk-backup-$(date +%Y%m%d).tar.gz configs/ certs/

# Backup CDR data
docker compose exec asterisk tar -czf /tmp/cdr-backup.tar.gz /var/log/asterisk/cdr-csv/
docker compose cp asterisk:/tmp/cdr-backup.tar.gz ./
```

### Updates

```
# Pull latest Coturn image
docker compose pull coturn

# Rebuild Asterisk (if needed)
docker compose build asterisk

# Restart services
docker compose up -d
```

### Logs

```
# View all logs
docker compose logs

# Follow specific service
docker compose logs -f asterisk

# Last 100 lines
docker compose logs --tail=100 asterisk

# Save logs to file
docker compose logs > asterisk-logs-$(date +%Y%m%d).txt
```

## Contributing

Contributions welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

MIT License - See [LICENSE](LICENSE) file for details

## Support

- **Issues:** [GitHub Issues](https://github.com/YOUR_USERNAME/asterisk-webrtc-server/issues)
- **Documentation:** [Asterisk Wiki](https://wiki.asterisk.org/)
- **Community:** [Asterisk Forums](https://community.asterisk.org/)

## Acknowledgments

- [Asterisk](https://www.asterisk.org/) - Open source PBX
- [Coturn](https://github.com/coturn/coturn) - TURN/STUN server
- [Docker](https://www.docker.com/) - Containerization platform

---

**Built with ❤️ for WebRTC and VoIP applications**
