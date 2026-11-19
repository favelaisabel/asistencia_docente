import { defineConfig } from 'vitest/config';

// La primera conexión al emulador puede tardar varios segundos.
export default defineConfig({
  test: {
    testTimeout: 30000,
    hookTimeout: 30000,
    fileParallelism: false,
  },
});
