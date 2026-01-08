import { defineWorkersConfig } from '@cloudflare/vitest-pool-workers/config'

export default defineWorkersConfig({
  test: {
    poolOptions: {
      workers: {
        wrangler: {
          configPath: './wrangler.toml',
        },
        miniflare: {
          // Add bindings for testing
          bindings: {
            UPLOAD_SECRET: 'test-secret-key',
            PRESIGN_TOKEN: 'test-presign-token',
          },
        },
      },
    },
  },
})
