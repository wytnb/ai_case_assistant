import { defineWorkersConfig } from '@cloudflare/vitest-pool-workers/config';

export default defineWorkersConfig({
	test: {
		include: ['test/**/*.spec.ts'],
		exclude: ['test/**/*.live.spec.ts'],
		poolOptions: {
			workers: {
				wrangler: { configPath: './wrangler.jsonc' },
			},
		},
	},
});
