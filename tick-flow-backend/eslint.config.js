import eslint from '@eslint/js';
import tseslint from 'typescript-eslint';

export default tseslint.config(
  { ignores: ['dist/', 'node_modules/', 'eslint.config.js'] },
  eslint.configs.recommended,
  ...tseslint.configs.recommendedTypeChecked,
  {
    languageOptions: {
      parserOptions: {
        projectService: true,
        tsconfigRootDir: import.meta.dirname,
      },
    },
    rules: {
      // CLAUDE.md: no `any` in services/repositories — error everywhere except tests
      '@typescript-eslint/no-explicit-any': 'error',
      // fire-and-forget must be explicit (`void promise`), never accidental
      '@typescript-eslint/no-floating-promises': ['error', { ignoreVoid: true }],
      // implementing an async port without awaiting is idiomatic here
      '@typescript-eslint/require-await': 'off',
      '@typescript-eslint/no-unused-vars': ['error', { argsIgnorePattern: '^_', varsIgnorePattern: '^_' }],
    },
  },
  {
    // tests stub deps with `{} as X` and read untyped res.json() — relax the unsafe-* family
    files: ['**/*.test.ts'],
    rules: {
      '@typescript-eslint/no-unsafe-assignment': 'off',
      '@typescript-eslint/no-unsafe-member-access': 'off',
      '@typescript-eslint/no-unsafe-argument': 'off',
      '@typescript-eslint/no-unsafe-call': 'off',
      '@typescript-eslint/no-unsafe-return': 'off',
      // expect(mock.fn).toHaveBeenCalled trips this on vitest mocks
      '@typescript-eslint/unbound-method': 'off',
    },
  },
);
