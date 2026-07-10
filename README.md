# Custom Image Gateway - B2 / S3-Compatible

A fork of [haierkeys/custom-image-gateway](https://github.com/haierkeys/custom-image-gateway) that adds **custom S3 endpoint support**, making it work with **Backblaze B2** and other S3-compatible object storage services.

## Why this fork?

The upstream project supports AWS S3, but the S3 endpoint is hard-coded to AWS. Backblaze B2, Cloudflare R2, MinIO, and many other providers expose an S3-compatible API that requires a custom endpoint. This fork adds an `endpoint` field to the S3 storage configuration so you can use any of them.

## What changed

- `pkg/storage/aws_s3/s3.go`: Added `Endpoint` field and inject it into the AWS SDK via `BaseEndpoint`.
- `pkg/storage/aws_s3/operation.go`: Fixed the double-slash bug when `CustomPath` is empty.
- `frontend/assets/index-*.js`: Added an **Endpoint** input field to the S3 configuration form in the WebUI.
- `config/config.yaml`: Added an `endpoint` example for the `aws-s3` section.
- Docker Hub image published via GitHub Actions.

## Docker image

```
lascivea/custom-image-gateway-b2:latest
```

Built for `linux/amd64` and `linux/arm64`.

## Deploy with Docker Compose

1. Clone this repository:

```bash
git clone https://github.com/lascivea/custom-image-gateway-b2.git
cd custom-image-gateway-b2
```

2. Copy the compose template and config template:

```bash
cp docker-compose.example.yaml docker-compose.yaml
cp config/config.yaml config/config.yaml
```

3. Edit `config/config.yaml` and fill in your credentials and endpoint.

4. Start the service:

```bash
docker compose pull
docker compose up -d
```

5. Check logs:

```bash
docker logs -f image-api
```

### Compose template

`docker-compose.example.yaml`:

```yaml
services:
  image-api:
    image: lascivea/custom-image-gateway-b2:latest
    container_name: image-api
    ports:
      - "9000:9000"
      - "9001:9001"
    volumes:
      - ./config/:/api/config/
      - ./storage/:/api/storage/
    restart: always
    pull_policy: always
```

## Quick start

```bash
git clone https://github.com/lascivea/custom-image-gateway-b2.git
cd custom-image-gateway-b2

mkdir -p config
cp config/config.yaml config/config.yaml

# Edit config/config.yaml and fill in your credentials and endpoint
# docker compose pull && docker compose up -d
```

### Backblaze B2 example

```yaml
aws-s3:
  is-enable: true
  is-user-enable: true
  region: us-west-004
  endpoint: https://s3.us-west-004.backblazeb2.com
  bucket-name: your-bucket-name
  access-key-id: YOUR_B2_KEY_ID
  access-key-secret: YOUR_B2_KEY_SECRET
  custom-path: ""
```

### WebUI setup

1. Open `http://your-server-ip:9000`.
2. Register and log in.
3. Add an S3 storage configuration and enter your endpoint, region, bucket, and credentials.
4. Set the **访问地址前缀** (URL prefix) to your public CDN or proxy domain, e.g. `https://img.example.com`.

### Environment variables

The following environment variables override `config.yaml` values and are useful for quickly tuning upload behavior without editing the config file:

| Variable | Description | Default from `config.yaml` |
|----------|-------------|----------------------------|
| `UPLOAD_MAX_SIZE` | Maximum single file upload size in MB | `5` |
| `IMAGE_MAX_SIZE_WIDTH` | Server-side image resize width limit, `0` disables | `800` |
| `IMAGE_MAX_SIZE_HEIGHT` | Server-side image resize height limit, `0` disables | `800` |

Set them in `docker-compose.yaml` under `environment:`.

### Cloudflare CDN example

DNS:

| Type | Name | Target | Proxy |
|------|------|--------|-------|
| CNAME | `img` | `f000.backblazeb2.com` | On |

Transform Rule:

- Rule name: `B2 image bucket rewrite`
- Hostname equals: `img.example.com`
- Rewrite path: Dynamic
- Expression: `concat("/file/your-bucket-name", http.request.uri.path)`

## Companion Obsidian plugin

Use this server with the matching Obsidian plugin fork:

- [`lascivea/obsidian-pic-cloud`](https://github.com/lascivea/obsidian-pic-cloud)

It supports both `![[wikilink]]` and standard `![alt](path)` Markdown image links, drag-and-drop uploads, frontmatter per-file toggles, and more.

## License

Apache-2.0, same as the upstream project.
