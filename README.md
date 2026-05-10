# JunoPay OpenCart Demo

Deployable OpenCart demo store for the JunoPay payment extension.

The image installs OpenCart 3.0.5.0, MariaDB, and the bundled `junopay` payment extension. On startup it bootstraps a demo store, enables JunoPay, and creates a `1 gallon of air` product priced at `1 JUNO`.

## Runtime configuration

- `OPENCART_HTTP_SERVER`: public base URL.
- `JUNOPAY_BASE_URL`: Juno Pay Server base URL.
- `JUNOPAY_MERCHANT_API_KEY`: merchant API key used to create invoices.
- `JUNOPAY_WEBHOOK_SECRET`: reserved for webhook verification.

## Local run

```bash
docker build -t junopay-opencart-demo:local .
docker run --rm -p 18084:8080 \
  -e OPENCART_HTTP_SERVER=http://localhost:18084/ \
  -e JUNOPAY_BASE_URL=https://staging.junopayserver.com \
  -e JUNOPAY_MERCHANT_API_KEY=replace-me \
  junopay-opencart-demo:local
```

Open `http://localhost:18084/index.php?route=product/product&product_id=1`.
