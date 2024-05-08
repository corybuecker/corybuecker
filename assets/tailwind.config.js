/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ["../templates/**/*.hbs"],
  theme: {
    extend: {},
  },
  plugins: [require("@tailwindcss/typography"), require("@tailwindcss/forms")],
};
