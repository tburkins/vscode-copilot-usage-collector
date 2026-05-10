docker run --rm -d `
  -p 4317:4317 `
  -p 4318:4318 `
  -v "${PWD}\otel-collector.yaml:/etc/otel-collector.yaml" `
  -v "${PWD}\data:/data" `
  --name otel-parquet `
  otel/opentelemetry-collector-contrib:0.102.0 `
  --config=/etc/otel-collector.yaml
