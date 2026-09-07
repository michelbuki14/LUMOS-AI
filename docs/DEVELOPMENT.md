# =============================================================================
# LUMOS AI — Developer Documentation
# =============================================================================

# Getting Started

## Prerequisites

Before you begin, ensure you have the following installed:

- **Docker** 24+ and **Docker Compose** v2
- **Flutter** 3.24+ (`flutter doctor` should pass)
- **Rust** 1.82+ (`rustc --version`)
- **Python** 3.12+ (`python3 --version`)
- **Node.js** 20+ and **pnpm** 9+

## Quick Start

### Option 1: Docker (Recommended)

```bash
# Clone the repository
git clone https://github.com/lumos-ai/lumos.git
cd lumos

# Start all services
docker compose up

# Or build and start
docker compose up --build
```

This starts:
- PostgreSQL on port 5432
- Redis on port 6379
- MinIO on port 9000/9001
- FastAPI backend on port 8000
- AI inference service on port 8001
- Rust rendering engine on port 8002

### Option 2: Native Development

```bash
# Install dependencies
pnpm install

# Start infrastructure (PostgreSQL, Redis, MinIO)
docker compose up postgres redis minio

# Start the API server
pnpm dev:api

# Start the AI service (in another terminal)
pnpm dev:ai

# Start the rendering engine (in another terminal)
pnpm dev:render

# Start the Flutter desktop app (in another terminal)
pnpm dev:desktop
```

## Project Structure

```
lumos/
├── apps/
│   └── desktop/          # Flutter desktop application
│       ├── lib/
│       │   ├── src/
│       │   │   ├── app.dart
│       │   │   ├── core/
│       │   │   │   ├── providers/
│       │   │   │   └── services/
│       │   │   └── features/
│       │   │       ├── dashboard/
│       │   │       ├── catalog/
│       │   │       ├── editor/
│       │   │       ├── culling/
│       │   │       ├── batch/
│       │   │       ├── galleries/
│       │   │       ├── settings/
│       │   │       └── widgets/
│       │   └── main.dart
│       └── pubspec.yaml
├── services/
│   ├── api/              # FastAPI backend
│   │   ├── lumos/
│   │   │   ├── app.py
│   │   │   ├── config.py
│   │   │   ├── database.py
│   │   │   ├── middleware.py
│   │   │   ├── routers/
│   │   │   └── models/
│   │   └── requirements.txt
│   ├── ai/               # AI inference service
│   │   ├── lumos/ai/
│   │   │   └── app.py
│   │   └── requirements.txt
│   └── render/           # Rust rendering engine
│       ├── src/
│       │   ├── lib.rs
│       │   ├── main.rs
│       │   ├── device.rs
│       │   ├── error.rs
│       │   ├── operations.rs
│       │   ├── pipeline.rs
│       │   └── processor.rs
│       └── Cargo.toml
├── infra/
│   ├── docker/
│   │   ├── Dockerfile.api
│   │   ├── Dockerfile.ai
│   │   ├── Dockerfile.render
│   │   └── postgres/
│   │       └── init.sql
│   └── k8s/              # Kubernetes manifests
├── docs/                 # Documentation
├── scripts/              # Build & dev scripts
└── tests/                # End-to-end tests
```

## API Documentation

Once the API server is running, visit:
- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc

### Authentication

All API endpoints require authentication via JWT tokens.

```bash
# Login
curl -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=demo@lumos.ai&password=demo123"

# Use the token in subsequent requests
curl http://localhost:8000/api/v1/assets \
  -H "Authorization: Bearer <your_token>"
```

### Key Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/auth/login` | Login and get JWT tokens |
| POST | `/api/v1/auth/register` | Register new account |
| GET | `/api/v1/assets` | List all assets |
| POST | `/api/v1/assets/upload` | Upload a new image |
| GET | `/api/v1/assets/{id}` | Get asset details |
| POST | `/api/v1/ai/cull` | Run AI culling |
| POST | `/api/v1/ai/mask` | Generate AI mask |
| POST | `/api/v1/ai/portrait` | AI portrait retouching |
| POST | `/api/v1/ai/background` | AI background processing |
| POST | `/api/v1/ai/remove` | AI object removal |
| GET | `/api/v1/projects` | List projects |
| POST | `/api/v1/projects` | Create project |
| GET | `/api/v1/galleries` | List galleries |
| POST | `/api/v1/galleries` | Create gallery |
| POST | `/api/v1/batch` | Create batch job |
| POST | `/api/v1/export` | Export images |

## Database Schema

The database schema is defined in `infra/docker/postgres/init.sql`. Key tables:

- **users** — User accounts
- **workspaces** — Top-level organization units
- **workspace_members** — User-workspace relationships with roles
- **assets** — Image files with metadata
- **projects** — Photography projects
- **albums** — Image collections
- **adjustment_graphs** — Non-destructive edit graphs
- **masks** — AI-generated and manual masks
- **galleries** — Client delivery galleries
- **ai_operations** — AI processing job tracking
- **export_presets** — Export configuration presets
- **batch_jobs** — Batch processing jobs
- **audit_logs** — Activity logging

## Development Workflow

### Running Tests

```bash
# Run all tests
pnpm test

# Run API tests
pnpm test:api

# Run AI service tests
pnpm test:ai

# Run Flutter tests
pnpm test:desktop
```

### Code Quality

```bash
# Lint all code
pnpm lint

# Format all code
pnpm format

# Type checking (Python)
cd services/api && pnpm typecheck
```

### Database Migrations

```bash
# Run migrations
pnpm db:migrate

# Seed demo data
pnpm db:seed
```

## Architecture Decisions

### Why Flutter for Desktop?

- Single codebase for Windows, macOS, and Linux
- Excellent performance with Skia rendering
- Rich ecosystem of packages
- Native desktop integration (window management, system tray, hotkeys)

### Why Rust for Rendering?

- Zero-cost abstractions for image processing
- Memory safety without garbage collection
- GPU acceleration via wgpu (Vulkan/Metal/DX12)
- Excellent performance for pixel-level operations

### Why FastAPI for Backend?

- Async-first design for high performance
- Automatic OpenAPI documentation
- Type hints with Pydantic
- Easy integration with ML/AI libraries

### Why PostgreSQL?

- Robust, production-ready relational database
- Excellent JSON support for flexible metadata
- Full-text search capabilities
- Proven at scale

## Performance Targets

| Metric | Target |
|--------|--------|
| Application startup | < 2 seconds |
| RAW file open | < 500ms |
| AI preview generation | < 1 second |
| Batch export (1,000 images) | Without crashing |
| GPU-accelerated rendering | Enabled by default |
| Memory efficiency | < 2GB for typical workflow |
| Offline capability | Full editing without internet |

## Security

- JWT-based authentication with refresh tokens
- Role-based access control (RBAC)
- Encrypted local database (Hive)
- Input validation on all endpoints
- Rate limiting on API endpoints
- Audit logging for all mutations
- CORS configuration for web origins

## Troubleshooting

### Docker Issues

```bash
# Reset everything
docker compose down -v
docker compose up --build

# View logs
docker compose logs -f api
docker compose logs -f ai
docker compose logs -f render
```

### Flutter Issues

```bash
# Clean and rebuild
cd apps/desktop
flutter clean
flutter pub get
flutter run -d windows  # or macos, linux
```

### Database Issues

```bash
# Reset database
docker compose down postgres
docker volume rm lumos-ai_postgres_data
docker compose up postgres
```

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

Proprietary — LUMOS AI, Inc. All rights reserved.
