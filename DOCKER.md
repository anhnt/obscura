# Running Obscura with Docker

This guide explains how to build and run Obscura inside a Docker container. Running Obscura via Docker is ideal for headless automation (Playwright/Puppeteer) as it allows isolated environments and scalable scrapers.

## Build the Docker Image

You can build the Docker image locally using the provided `Dockerfile`. The Dockerfile uses a multi-stage process to compile Obscura from source with stealth capabilities and then packages it into a minimal Debian runtime image.

```bash
docker build -t obscura:latest .
```
*(Note: Compiling Obscura from source builds the V8 engine and might take a few minutes on the first run.)*

## Run the Container using Docker Compose

The easiest way to start Obscura is using `docker-compose`.

```bash
docker-compose up -d
```

This will run the Obscura container in the background, listening on port `9222`. It mounts the port to your host machine.

### Configuration via Environment Variables

The container accepts the following environment variables to customize the runtime:

- `PORT` (default: `9222`): The port that Obscura will be exposed on.
- `WORKERS` (default: `1`): The number of worker processes to spawn. Increase this for higher concurrency.
- `STEALTH` (default: `true`): If set to `true` or `1`, enables stealth features (TLS fingerprint spoofing, anti-detection).

## Run the Container manually using Docker CLI

If you prefer not to use `docker-compose`, you can run the image directly:

```bash
docker run -d \
  --name obscura \
  -p 9222:9222 \
  -e WORKERS=2 \
  -e STEALTH=true \
  obscura:latest
```

## Connecting with Puppeteer & Playwright

Because Obscura's internal WebSocket server listens on `127.0.0.1` by default, the Docker setup automatically uses `socat` to proxy incoming traffic on `0.0.0.0:9222` to the internal server. This makes it instantly compatible with external tools connecting via the Docker network or from your host machine.

### Puppeteer Example

```javascript
import puppeteer from 'puppeteer-core';

(async () => {
  // Connect to the Obscura container
  const browser = await puppeteer.connect({
    // If running node on host, use localhost. If running node in another container, use 'ws://obscura:9222/devtools/browser'
    browserWSEndpoint: 'ws://127.0.0.1:9222/devtools/browser',
  });

  const page = await browser.newPage();
  await page.goto('https://news.ycombinator.com');
  console.log(await page.title());
  
  await browser.disconnect();
})();
```

### Playwright Example

```javascript
import { chromium } from 'playwright-core';

(async () => {
  // Connect to the Obscura container
  const browser = await chromium.connectOverCDP({
    // If running node on host, use localhost. If running node in another container, use 'ws://obscura:9222'
    endpointURL: 'ws://127.0.0.1:9222',
  });

  const page = await browser.newContext().then(ctx => ctx.newPage());
  await page.goto('https://en.wikipedia.org/wiki/Web_scraping');
  console.log(await page.title());

  await browser.close();
})();
```

## Running inside a Docker Network

If you are running your Node.js application (Puppeteer/Playwright scraper) in another Docker container within the same `docker-compose.yml`, you should connect to Obscura using the service name (`obscura`):

```javascript
// Puppeteer
browserWSEndpoint: 'ws://obscura:9222/devtools/browser'

// Playwright
endpointURL: 'ws://obscura:9222'
```
