module.exports = {
  parser: "@typescript-eslint/parser", // Specifies the ESLint parser

  parserOptions: {
    ecmaVersion: 2020,
    sourceType: "module",
  },

  extends: [
    "plugin:@typescript-eslint/recommended",
  ],
};
