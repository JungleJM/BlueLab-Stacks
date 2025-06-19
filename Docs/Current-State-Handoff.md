# BlueLab Stacks - Current State Handoff Document

## Project Status Overview

**Current State**: Planning and Architecture Phase Complete  
**Next Step**: Begin Phase 1A Implementation  
**Repository**: BlueLab-Stacks (separate from main BlueLab ISO project)  
**Target**: Standalone system that works on any Linux distribution

## What Exists Currently

### Documentation
- ✅ **Initial Task.md** - Project requirements and goals
- ✅ **BlueLab-Stacks-Phase2-Plan.md** - Detailed technical planning
- ✅ **Architecture-Plan.md** - Complete system architecture
- ✅ **Project-Phases.md** - Development phases and timeline
- ✅ **Current-State-Handoff.md** - This document

### Repository Structure
```
BlueLab-Stacks/
├── Docs/
│   ├── Initial Task.md
│   ├── BlueLab-Stacks-Phase2-Plan.md
│   ├── Architecture-Plan.md
│   ├── Project-Phases.md
│   └── Current-State-Handoff.md
└── [Implementation directories to be created]
```

## What Needs to be Created

### Phase 1A Implementation (Immediate Next Steps) - trying to do with a VM at the moment

#### 1. Directory Structure Creation
```bash
mkdir -p {scripts,stacks,config,templates}
mkdir -p stacks/{core-networking,core-download,core-database,monitoring}
mkdir -p config/{homepage,docker,global}
mkdir -p templates/{docker-compose,service-configs}
```

#### 2. Core Scripts to Implement
- [ ] `scripts/install.sh` - Main installation script
- [ ] `scripts/detect-system.sh` - Distribution detection
- [ ] `scripts/setup-distrobox.sh` - Distrobox container management
- [ ] `scripts/deploy-stack.sh` - Stack deployment manager
- [ ] `scripts/configure-networking.sh` - Tailscale and DNS setup

#### 3. Configuration Templates
- [ ] `config/global/global.env.template` - Global environment variables
- [ ] `config/docker/docker.env.template` - Docker-specific settings
- [ ] `config/distrobox/bluelab-container.conf` - Container definition
- [ ] `templates/docker-compose/base.yml` - Base compose template

#### 4. Core Stack Implementations
- [ ] `stacks/core-networking/docker-compose.yml` - Tailscale + AdGuard Home (smart domain routing)
- [ ] `stacks/core-download/docker-compose.yml` - Deluge (primary) + qBittorrent + utilities
- [ ] `stacks/core-database/docker-compose.yml` - PostgreSQL + Redis
- [ ] `stacks/smb-share/docker-compose.yml` - Samba with Tailscale integration
- [ ] `stacks/monitoring/docker-compose.yml` - Homepage + Dockge

## Technical Decisions Made

### Architecture Decisions
1. **Distrobox Strategy**: Ubuntu 22.04 LTS container for maximum compatibility
2. **Smart DNS Solution**: AdGuard Home with BlueLab user detection
   - BlueLab users: `bluelab.movies`, `bluelab.tv`, etc.
   - Non-BlueLab users: `homelab.movies`, `homelab.tv`, etc.
3. **Download Client Priority**: Deluge (primary) with Labels plugin, qBittorrent (secondary)
4. **SMB Integration**: Core stack for Phase 1 (not optional)
5. **Shared Services**: Core stacks handle shared dependencies (databases, download clients)
6. **Service Discovery**: Docker labels for automatic Homepage configuration
7. **Storage**: `/var/lib/bluelab/` for all persistent data

### Network Architecture
- **Primary Access**: Tailscale for secure remote access
- **Local Access**: Standard IP addresses with port forwarding
- **Smart DNS Routing**: Domain prefix based on user type
  - BlueLab users: `bluelab.movies` → radarr, `bluelab.tv` → sonarr
  - Non-BlueLab users: `homelab.movies` → radarr, `homelab.tv` → sonarr
- **Port Management**: Automatic conflict detection and resolution

### Security Model
- **Isolation**: Distrobox provides additional security layer
- **Secrets**: Centralized API key generation and management
- **Access Control**: Tailscale device-based authentication
- **User Permissions**: Non-root containers with PUID/PGID

## Key Questions Answered

### Q: Should we use Distrobox or native installation?
**A**: Distrobox prioritized for compatibility and easy removal, with native fallback.

### Q: Electron installer or bash installer first?
**A**: Bash installer for Phase 1, Electron interface in Phase 3A (moved up for UX priority).

### Q: How to handle shared dependencies between stacks?
**A**: Core stacks (core-download, core-database, smb-share) handle shared services automatically.

### Q: How deep should Tailscale integration be?
**A**: Primarily for access, with smart DNS routing based on user type (bluelab.* vs homelab.*).

### Q: Should Gaming stack follow standard pattern?
**A**: No, it's a special case - installs Steam natively if available, containerized if not (Phase 4C).

### Q: What about SMB sharing?
**A**: Moved to Phase 1 as core infrastructure - essential for file access across devices.

## Implementation Priorities

### Phase 1 (Weeks 1-3) - Foundation
**Critical Path**: Distrobox setup → Core stacks (including SMB) → Service discovery
**Priority**: Get basic system working with monitoring, networking, and file sharing

### Phase 2 (Weeks 4-6) - Media Stack  
**Critical Path**: Jellyfin → Sonarr/Radarr → ARR stack auto-configuration (CRITICAL)
**Priority**: Deliver primary user value (Netflix replacement) with zero manual configuration

### Phase 3 (Weeks 7-8) - UX & Photos
**Critical Path**: Electron installer → Mobile optimization → Immich photos
**Priority**: Polish user experience and deliver Google Photos replacement

### Phase 4 (Weeks 9-13) - Extended Functionality
**Priority**: Audio, Books, Productivity, Gaming, Multi-user, Advanced monitoring

## Risk Mitigation Strategies

### Technical Risks
1. **Distrobox Compatibility**: Test on multiple distributions early
2. **Port Conflicts**: Implement robust port management system
3. **Service Dependencies**: Careful ordering of stack deployments
4. **Resource Usage**: Monitor memory and CPU usage throughout development

### User Experience Risks  
1. **Installation Complexity**: Extensive testing on clean systems
2. **Service Configuration**: Automated setup with minimal user input
3. **Documentation**: Clear, step-by-step instructions with screenshots
4. **Support**: Comprehensive troubleshooting guides

## Next Immediate Actions

### 1. Repository Setup (Day 1)
```bash
# Create basic repository structure
mkdir -p BlueLab-Stacks/{scripts,stacks,config,templates}
cd BlueLab-Stacks

# Initialize git repository
git init
git add .
git commit -m "Initial repository structure and documentation"
```

### 2. Development Environment (Day 1-2)
- Set up development VM with clean Ubuntu/Fedora
- Install Distrobox and Docker
- Create basic test scripts for system detection

### 3. Core Installation Script (Day 3-5)
- Implement `scripts/install.sh` with basic functionality
- Add system detection and prerequisite checking
- Create Distrobox container setup

### 4. First Stack Implementation (Day 6-10)
- Implement Core Networking stack (Tailscale + AdGuard Home)
- Add smart domain detection (bluelab.* vs homelab.*)
- Test DNS routing and subdomain access
- Verify Tailscale integration works correctly

### 5. Core Infrastructure (Day 11-15)
- Implement Core Download stack (Deluge primary with Labels plugin)
- Add SMB Share stack with Tailscale integration
- Implement basic Homepage dashboard
- Add Dockge for container management
- Test service discovery functionality

## Success Criteria for Phase 1

### Functional Requirements
- [ ] Installation script works on Ubuntu, Fedora, and Silverblue
- [ ] Distrobox container creates successfully with proper volume mounts
- [ ] Tailscale connects and provides smart domain routing (bluelab.* or homelab.*)
- [ ] SMB shares accessible from any device on network
- [ ] Deluge configured with Labels plugin auto-loaded
- [ ] Homepage displays running services automatically
- [ ] Dockge provides visual container management
- [ ] All core services start and remain healthy

### Performance Requirements
- [ ] Installation completes in under 30 minutes
- [ ] Core services (including SMB) use less than 2GB RAM
- [ ] Service startup time under 5 minutes
- [ ] Homepage loads in under 3 seconds
- [ ] SMB file transfers perform adequately over network

### User Experience Requirements
- [ ] Installation requires minimal user input
- [ ] All services accessible via smart domain URLs (bluelab.* or homelab.*)
- [ ] SMB shares easily accessible from any device
- [ ] Error messages are clear and actionable
- [ ] Uninstallation leaves system in original state

## Integration Points

### BlueLab ISO Integration (Future)
Once Phase 1-2 are complete, integration with main BlueLab ISO:
- Add BlueLab-Stacks as git submodule
- Modify first-boot script to call BlueLab-Stacks installer
- Ensure stack selection passes through from ISO web form
- Test complete end-to-end installation process

### External Service Integration
- **Mobile Apps**: Jellyfin, Immich, Nextcloud clients
- **Desktop Integration**: SMB mounts, calendar sync
- **Browser Integration**: Automatic bookmark generation
- **API Integration**: All services maintain API access

## Communication Plan

### Documentation Updates
- Update README.md with installation instructions
- Create INSTALLATION.md with step-by-step guide
- Document troubleshooting common issues
- Maintain changelog for each release

### Testing Strategy
- Test on multiple Linux distributions
- Validate with target audience (non-technical users)
- Performance testing on minimum hardware
- Security review of all configurations

## Handoff Notes

### Development Environment
- Recommend using VM for development to test clean installations
- Keep separate development and testing environments
- Use git branches for each phase implementation
- Regular commits with clear commit messages

### Code Standards
- Follow existing BlueLab coding conventions
- Comment all complex logic thoroughly
- Use consistent error handling patterns
- Include health checks for all services

### Testing Requirements
- Test installation on clean systems only
- Verify uninstallation removes all traces
- Test service recovery after failures
- Validate all documented features work

## Contact and Resources

### Key Resources
- **BlueLab Main Repo**: https://github.com/JungleJM/BlueLab
- **First-Boot Branch**: Contains current Phase 1 implementation
- **Documentation**: Comprehensive docs in main repo
- **Issue Tracking**: Use GitHub issues for bugs and features

### Development References
- **Distrobox Documentation**: https://distrobox.privatedns.org/
- **Docker Compose**: https://docs.docker.com/compose/
- **Tailscale**: https://tailscale.com/kb/
- **Homepage**: https://gethomepage.dev/

This handoff document provides a complete picture of the current project state and clear next steps for implementation. The architecture is solid, the phases are well-defined, and the technical approach has been thoroughly planned.