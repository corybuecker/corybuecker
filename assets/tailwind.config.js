/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ["../templates/**/*.tera"],
  theme: {
    extend: {},
  },
  plugins: [require("@tailwindcss/typography"), require("@tailwindcss/forms")],
};
