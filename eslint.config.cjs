const vue = require('eslint-plugin-vue');

module.exports = [
  {
    files: ['**/*.js'],
    languageOptions: {
      ecmaVersion: 2020,
      globals: {
        node: true,
      },
    },
  },
  {
    files: ['**/*.vue'],
    languageOptions: {
      ecmaVersion: 2020,
      globals: {
        node: true,
      },
      parser: require('vue-eslint-parser'),
      parserOptions: {
        ecmaVersion: 2020,
        sourceType: 'module',
      },
    },
    plugins: {
      vue,
    },
    rules: {
      'vue/multi-word-component-names': 0,
    },
  },
];
